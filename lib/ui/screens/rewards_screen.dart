
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _rewards = [];
  bool _isLoading = true;
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Fetch User Points
      final profile = await _supabase.from('profiles').select('points_balance').eq('id', userId).single();
      
      // Fetch Rewards with Brands
      final rewards = await _supabase
          .from('rewards')
          .select('*, brands(name, logo_url)')
          .eq('is_active', true)
          .order('cost_points', ascending: true);

      if (mounted) {
        setState(() {
          _userPoints = profile['points_balance'] ?? 0;
          _rewards = List<Map<String, dynamic>>.from(rewards);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching rewards: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _redeem(Map<String, dynamic> reward) async {
    final cost = reward['cost_points'] as int;
    
    if (_userPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough points!'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Text('Redeem "${reward['title']}" for $cost points?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userId = _supabase.auth.currentUser!.id;
      final code = '${reward['code_prefix'] ?? 'ECO'}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      // 1. Create Redemption
      await _supabase.from('redemptions').insert({
        'user_id': userId,
        'reward_id': reward['id'],
        'promo_code': code,
        'status': 'active'
      });

      // 2. Deduct Points (Client side update, assume secure RPC/trigger in real prod)
      // Note: Ideally use RPC or transaction. 
      await _supabase.from('profiles').update({
        'points_balance': _userPoints - cost
      }).eq('id', userId);

      await _fetchData(); // Refresh

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Reward Redeemed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 64),
                const SizedBox(height: 16),
                Text('Your code: $code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Show this code at checkout.'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Marketplace'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_userPoints',
                      style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _rewards.isEmpty 
              ? const Center(child: Text('No active rewards available.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _rewards.length,
                  itemBuilder: (context, index) {
                    final reward = _rewards[index];
                    final brand = reward['brands'] as Map<String, dynamic>?;
                    
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: brand?['logo_url'] != null
                                  ? Image.network(brand!['logo_url'])
                                  : Center(child: Text(brand?['name']?[0] ?? 'B')),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              brand?['name'] ?? 'Partner Brand',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reward['title'] ?? 'Reward',
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              '${reward['cost_points']} pts',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _redeem(reward),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Redeem'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
