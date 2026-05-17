import 'dart:math';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:ecoins/ui/screens/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecoins/ui/widgets/scale_button.dart';
import 'package:ecoins/ui/widgets/custom_toast.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  
  // Data
  List<Map<String, dynamic>> _marketOffers = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _userPoints = 0;

  // Mock Raffles
  final List<Map<String, dynamic>> _raffles = [
    {
      'title': 'Electric Scooter',
      'image': 'assets/images/scooter_raffle.png',
      'entries_cost': 50,
      'ends_in': '2 days',
      'total_entries': 1240
    },
    {
      'title': '\$500 Grocery Gift Card',
      'image': 'assets/images/giftcard_raffle.png',
      'entries_cost': 20,
      'ends_in': '5 days',
      'total_entries': 850
    },
  ];

  // Mock Donations
  final List<Map<String, dynamic>> _donations = [
    {
      'title': 'Plant 1 Tree',
      'org': 'OneTreePlanted',
      'cost': 500,
      'image': 'assets/images/tree_donate.png',
    },
    {
      'title': 'Clean Ocean (1kg)',
      'org': '4Ocean',
      'cost': 1200,
      'image': 'assets/images/ocean_donate.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final profile = await _supabase
          .from('profiles')
          .select('points_balance')
          .eq('id', user.id)
          .single();

      final List<dynamic> offersData = await _supabase
          .from('offers')
          .select('*, brands(name, logo_url)')
          .eq('is_active', true)
          .order('points_cost', ascending: true);

      if (mounted) {
        setState(() {
          _userPoints = profile['points_balance'] ?? 0;
          _marketOffers = offersData
              .map((offer) => {
                    'id': offer['id'],
                    'title': offer['title'],
                    'description': offer['description'],
                    'cost_points': offer['points_cost'],
                    'discount_code': offer['discount_code'],
                    'brands': offer['brands'],
                  })
              .toList()
              .cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching rewards: $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  String _generatePromoCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return 'ECO-${List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Marketplace',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentYellow,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Rewards'),
            Tab(text: 'Raffles 🎟️'),
            Tab(text: 'Donate ❤️'),
          ],
        ),
        actions: [
            Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ScaleButton(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                opacity: 0.2,
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: AppTheme.accentYellow, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_userPoints',
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: Image.asset('assets/images/background.png',
                  fit: BoxFit.cover)),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRewardsGrid(),
                _buildRafflesList(),
                _buildDonationsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text('Could not load rewards', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Check your connection and try again.', style: GoogleFonts.inter(color: Colors.white60)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      );
    }
    if (_marketOffers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard_outlined, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text('No rewards yet', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Brands are adding eco offers soon.\nLog activities to build up your points!', style: GoogleFonts.inter(color: Colors.white60), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _marketOffers.length,
      itemBuilder: (context, index) {
        final reward = _marketOffers[index];
        final brand = reward['brands'];
        return _buildCard(
          title: reward['title'],
          subtitle: brand?['name'] ?? 'Partner',
          imageUrl: brand?['logo_url'],
          points: reward['cost_points'],
          buttonText: 'Redeem',
          onTap: () => _redeem(reward),
        );
      },
    );
  }

  Widget _buildRafflesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _raffles.length,
      itemBuilder: (context, index) {
        final item = _raffles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_activity, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'],
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text('Ends in ${item['ends_in']}',
                             style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${item['entries_cost']} pts / ticket',
                          style: GoogleFonts.outfit(
                              color: AppTheme.accentYellow, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {}, // TODO: Implement Raffle Entry
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryDark,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.add),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDonationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _donations.length,
      itemBuilder: (context, index) {
        final item = _donations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
             padding: const EdgeInsets.all(0),
             child: Column(
               children: [
                 Container(
                   height: 120,
                   decoration: BoxDecoration(
                     color: Colors.green.shade900.withOpacity(0.5),
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                   ),
                   child: Center(
                     child: Icon(Icons.volunteer_activism, size: 64, color: Colors.white.withOpacity(0.5))
                   ),
                 ),
                 Padding(
                   padding: const EdgeInsets.all(16),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text(item['title'],
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('via ${item['org']}',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                         ],
                       ),
                       ElevatedButton(
                         onPressed: () {},
                         style: ElevatedButton.styleFrom(
                           backgroundColor: AppTheme.primaryGreen,
                           foregroundColor: Colors.white,
                         ),
                         child: Text('${item['cost']} pts'),
                       )
                     ],
                   ),
                 )
               ],
             ),
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    String? imageUrl,
    required int points,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      : _imageFallback(),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Text('$points pts', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryDark),
                      child: Text(buttonText, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _imageFallback() => Container(
    color: Colors.white12,
    child: const Center(child: Icon(Icons.store_outlined, color: Colors.white38, size: 40)),
  );

  Future<void> _redeem(Map<String, dynamic> reward) async {
    final cost = reward['cost_points'] as int;
    if (_userPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough points!'), backgroundColor: Colors.red));
      return;
    }

    HapticFeedback.lightImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: AppTheme.accentYellow, size: 48),
              const SizedBox(height: 16),
              Text('Redeem Reward?', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Redeem "${reward['title']}" for $cost points?', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white60)))),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Confirm'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final promoCode = _generatePromoCode();

      final result = await _supabase.rpc('redeem_offer', params: {
        'p_user_id': user.id,
        'p_offer_id': reward['id'],
        'p_points_cost': cost,
        'p_promo_code': promoCode,
      });

      final newBalance = result['new_balance'] as int;

      if (mounted) {
        setState(() => _userPoints = newBalance);
        HapticFeedback.heavyImpact();
        CustomToast.show(context, 'Your code: $promoCode');
      }
      _fetchData();
    } catch (e) {
      debugPrint('Redemption error: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Redemption failed'),
            content: Text(e.toString().contains('Insufficient')
                ? 'You don\'t have enough points for this reward.'
                : 'Something went wrong. Please try again.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    }
  }
}
