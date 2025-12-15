import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      final user = _supabase.auth.currentUser;
      
      if (user == null) {
        // MOCK DATA
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() {
            _userPoints = 1250;
            _rewards = [
              {
                'id': 'mock1',
                'title': '10% Off EcoStore',
                'cost_points': 500,
                'code_prefix': 'ECO10',
                'description': 'Get 10% off your next purchase at EcoStore.',
                'brands': {'name': 'EcoStore', 'logo_url': null}
              },
              {
                'id': 'mock2',
                'title': 'Free Coffee',
                'cost_points': 300,
                'code_prefix': 'COFFEE',
                'description': 'One free organic coffee.',
                'brands': {'name': 'GreenCafe', 'logo_url': null}
              },
              {
                'id': 'mock3',
                'title': 'Bus Pass (1 Day)',
                'cost_points': 800,
                'code_prefix': 'BUS',
                'description': 'Unlimited travel for one day.',
                'brands': {'name': 'CityTransit', 'logo_url': null}
              },
            ];
            _isLoading = false;
          });
        }
        return;
      }

      final userId = user.id;
      
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
        backgroundColor: Colors.white.withOpacity(0.9),
        title: const Text('Confirm Redemption'),
        content: Text('Redeem "${reward['title']}" for $cost points?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (_supabase.auth.currentUser == null) {
        // MOCK REDEMPTION
         if (mounted) {
            final mockCode = '${reward['code_prefix'] ?? 'ECO'}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
            setState(() {
              _userPoints -= cost;
            });
            _showSuccessDialog(mockCode);
         }
         return;
      }
      
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
      await _supabase.from('profiles').update({
        'points_balance': _userPoints - cost
      }).eq('id', userId);

      await _fetchData(); // Refresh

      if (mounted) {
        _showSuccessDialog(code);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        title: const Text('🎉 Reward Redeemed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 64),
            const SizedBox(height: 16),
            Text('Your code: $code', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Redeem Rewards', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Or handling back button if needed
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              opacity: 0.2,
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppTheme.accentYellow, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$_userPoints',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
           // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(16),
                    opacity: 0.15,
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search rewards...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        icon: const Icon(Icons.search, color: Colors.white70),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filters
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip('All', true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Food', false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Retail', false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Transport', false),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // Grid
                Expanded(
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Colors.white)) 
                      : _rewards.isEmpty 
                          ? Center(child: Text('No rewards found', style: GoogleFonts.inter(color: Colors.white)))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.70, // Taller cards
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _rewards.length,
                              itemBuilder: (context, index) {
                                final reward = _rewards[index];
                                final brand = reward['brands'] as Map<String, dynamic>?;
                                
                                return GlassContainer(
                                  padding: const EdgeInsets.all(0),
                                  opacity: 0.2, // Slightly more opaque
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image Section
                                      Expanded(
                                        flex: 4,
                                        child: Container(
                                          margin: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            image: DecorationImage(
                                              image: brand?['logo_url'] != null 
                                                  ? NetworkImage(brand!['logo_url']) 
                                                  : const AssetImage('assets/images/logo.png') as ImageProvider, // Placeholder
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.9),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    '${reward['cost_points']} pts',
                                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      // Info Section
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                brand?['name'] ?? 'Partner',
                                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                reward['title'] ?? 'Reward',
                                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const Spacer(),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 32,
                                                child: ElevatedButton(
                                                  onPressed: () => _redeem(reward),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF10B981).withOpacity(0.9),
                                                    foregroundColor: Colors.white,
                                                    padding: EdgeInsets.zero,
                                                    elevation: 0,
                                                  ),
                                                  child: const Text('Redeem 🌿', style: TextStyle(fontSize: 12)),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(20),
      color: isSelected ? Colors.white : Colors.black,
      opacity: isSelected ? 0.3 : 0.1,
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
