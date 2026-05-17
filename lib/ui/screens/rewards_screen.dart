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
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 1. Fetch User Points
      final profile = await _supabase
          .from('profiles')
          .select('points_balance')
          .eq('id', user.id)
          .single();

      // 2. Fetch Offers
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
                    'code_prefix': offer['code_prefix'],
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
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_marketOffers.isEmpty) {
      return Center(
          child: Text('No rewards available',
              style: GoogleFonts.inter(color: Colors.white70)));
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: DecorationImage(
                  image: imageUrl != null && imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : const AssetImage('assets/images/logo.png')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                    Positioned(
                        top: 8, right: 8,
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                            child: Text('$points pts', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                        )
                    )
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

  // Reuse logic from original file
  Future<void> _redeem(Map<String, dynamic> reward) async {
      // ... same logic as before, abbreviated here for saving chars ...
      // In a real refactor, I'd extract this to a service or mixin
      final cost = reward['cost_points'] as int;
      if (_userPoints < cost) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough points!'), backgroundColor: Colors.red));
         return;
      }
      
      HapticFeedback.lightImpact();
      // CONFIRM DIALOG - Premium Design
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937), // Dark Gray
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 5)
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: AppTheme.accentYellow, size: 48),
                const SizedBox(height: 16),
                Text('Redeem Reward?', 
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Redeem "${reward['title']}" for $cost points?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white70)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: ()=>Navigator.pop(context, false), 
                        child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white60))
                      )
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12)
                        ),
                        onPressed: ()=>Navigator.pop(context, true), 
                        child: const Text('Confirm')
                      )
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );

      if (confirm != true) return;

      try {
          final user = _supabase.auth.currentUser;
          if (user == null) return;
          
          final codePrefix = reward['code_prefix'] ?? 'ECO';
          final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
          final uniquePromoCode = '$codePrefix-$uniqueSuffix';
          final brandDisplayCode = reward['discount_code'] ?? uniquePromoCode;

          await _supabase.from('redemptions').insert({
              'user_id': user.id,
              'offer_id': reward['id'],
              'promo_code': uniquePromoCode,
              'status': 'active'
          });

          final newBalance = _userPoints - cost;
          await _supabase.from('profiles').update({'points_balance': newBalance}).eq('id', user.id);

          if (mounted) {
              setState(() => _userPoints = newBalance);
              HapticFeedback.heavyImpact();
              CustomToast.show(context, 'Redeemed: $uniquePromoCode');
          }
          _fetchData();
      } catch(e) {
          debugPrint(e.toString());
      }
  }
}
