import 'dart:ui';
// Removed unused imports
import 'package:ecoins/ui/screens/brand/offer_management_screen.dart';
import 'package:ecoins/ui/screens/brand/brand_settings_screen.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class BrandDashboardScreen extends StatefulWidget {
  const BrandDashboardScreen({super.key});

  @override
  State<BrandDashboardScreen> createState() => _BrandDashboardScreenState();
}

class _BrandDashboardScreenState extends State<BrandDashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _brand;
  List<Map<String, dynamic>> _activeOffers = [];
  
  // Authentic Stats
  double _totalCo2 = 0;
  double _treesPlanted = 0;
  double _plasticRecycled = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      // 1. Fetch Brand Profile
      final brandData = await _supabase
          .from('brands')
          .select()
          .eq('owner_user_id', user.id)
          .maybeSingle();

      if (brandData == null) {
        if (mounted) {
          setState(() {
            _brand = null;
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Fetch Active Offers
      final offersResponse = await _supabase
          .from('offers')
          .select()
          .eq('brand_id', brandData['id'])
          .eq('is_active', true)
          .limit(5); // Top 5

      // 3. Calculate/Fetch Stats
      final dbCo2 = (brandData['total_carbon_saved'] ?? 0).toDouble();
      final trees = (dbCo2 / 20).floorToDouble(); 
      final plastic = (dbCo2 / 5).floorToDouble();

      if (mounted) {
        setState(() {
          _brand = brandData;
          _activeOffers = List<Map<String, dynamic>>.from(offersResponse);
          _totalCo2 = dbCo2;
          _treesPlanted = trees;
          _plasticRecycled = plastic;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0FDF4),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    if (_brand == null) {
      return _buildOnboardingState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Fallback
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0FDF4), // Mint 50
              Color(0xFFECFDF5), // Emerald 50
              Color(0xFFF8FAFC), // Slate 50
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Main Scrollable Content
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120), // Bottom padding for nav bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Stats Row (Horizontal Scroll)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          _buildGlassStatCard(
                            label: 'CO2 Saved',
                            value: _totalCo2.toStringAsFixed(0),
                            unit: 'kg',
                            icon: Icons.filter_drama, // closest to co2
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 16),
                          _buildGlassStatCard(
                            label: 'Planted',
                            value: _treesPlanted.toStringAsFixed(0),
                            unit: 'Trees',
                            icon: Icons.forest,
                            color: Colors.green[800]!,
                          ),
                          const SizedBox(width: 16),
                          _buildGlassStatCard(
                            label: 'Plastic',
                            value: _plasticRecycled.toStringAsFixed(0),
                            unit: 'kg',
                            icon: Icons.recycling,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Weekly Engagement Chart
                    _buildEngagementChart(),
                    const SizedBox(height: 32),

                    // Active Campaigns Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Campaigns',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[900],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const OfferManagementScreen()));
                          },
                          child: Text(
                            'See All',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Campaigns List
                    if (_activeOffers.isEmpty)
                      _buildEmptyState()
                    else
                      ..._activeOffers.map((offer) => _buildCampaignCard(offer)),
                      
                    const SizedBox(height: 32),
                    
                    // Grid Section (Eco Score & New Button)
                    Row(
                      children: [
                        Expanded(child: _buildEcoScoreCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildNewCampaignButton()),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Navigation
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  )
                ],
                image: DecorationImage(
                  image: _brand?['logo_url'] != null
                      ? NetworkImage(_brand!['logo_url'])
                      : const AssetImage('assets/images/logo.png') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _brand?['name'] ?? 'Partner',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueGrey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
              )
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, size: 22, color: Colors.blueGrey[600]),
            onPressed: () {
               // Handle notifications
            },
            padding: EdgeInsets.zero,
          ),
        )
      ],
    );
  }

  Widget _buildGlassStatCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      color: Colors.white.withOpacity(0.7),
      opacity: 0.4, // Glass effect
      blur: 10,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.5)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[500],
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                      letterSpacing: -0.5,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: unit,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart() {
    // Mock Data for the chart
    final List<FlSpot> spots = const [
      FlSpot(0, 3),
      FlSpot(1, 4),
      FlSpot(2, 3.5),
      FlSpot(3, 5),
      FlSpot(4, 4),
      FlSpot(5, 6),
      FlSpot(6, 5.5),
    ];

    return GlassContainer(
      color: Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.6)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Engagement',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'High Activity',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        '+12%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Chart
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 8,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.2),
                            const Color(0xFF10B981).withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // X-Axis Labels
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((day) => Text(
                        day,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey[400],
                        ),
                      )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> offer) {
    // Determine status color
    final isActive = offer['status'] == 'active' || offer['is_active'] == true;
    
    // Mock progress 
    final double progress = 0.75; 
    final int percentage = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: offer['image_url'] != null 
                        ? NetworkImage(offer['image_url']) 
                        : (_brand?['logo_url'] != null 
                            ? NetworkImage(_brand!['logo_url']) 
                            : const AssetImage('assets/images/logo.png') as ImageProvider),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer['title'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer['expires_at'] != null 
                          ? 'Ends ${timeago.format(DateTime.parse(offer['expires_at']), allowFromNow: true)}'
                          : 'Ongoing',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green[600] : Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.blueGrey[100],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
       child: Padding(
         padding: const EdgeInsets.all(24.0),
         child: Text(
           'No active campaigns yet. Start one today!',
           style: GoogleFonts.inter(color: Colors.grey[400]),
           textAlign: TextAlign.center,
         ),
       ),
     );
  }

  Widget _buildEcoScoreCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              children: [
                const Center(
                   child: SizedBox(
                     height: 80,
                     width: 80,
                     child: CircularProgressIndicator(
                       value: 0.92,
                       strokeWidth: 6,
                       color: Color(0xFF10B981),
                       backgroundColor: Color(0xFFF1F5F9),
                       strokeCap: StrokeCap.round,
                     ),
                   ),
                ),
                Center(
                  child: Text(
                    '92',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Community\nEco Score',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[500],
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewCampaignButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OfferManagementScreen()));
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blueGrey[200]!, width: 2, style: BorderStyle.solid), // Dashed border styling simplified to solid with color diff
          boxShadow: [
            BoxShadow(color: Colors.transparent, blurRadius: 0),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OfferManagementScreen()));
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.blueGrey, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  'New Campaign',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Custom Bottom Nav
  Widget _buildBottomNav() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: Border(top: BorderSide(color: Colors.blueGrey[100]!)),
          ),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               _buildNavItem(Icons.dashboard_rounded, 'Home', true),
               _buildNavItem(Icons.campaign_outlined, 'Campaigns', false, onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const OfferManagementScreen()));
               }),
               _buildNavItem(Icons.bar_chart_rounded, 'Stats', false),
               _buildNavItem(Icons.person_outline_rounded, 'Profile', false, onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandSettingsScreen()));
               }),
             ],
           ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: isActive ? const Color(0xFF10B981) : Colors.blueGrey[400],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF10B981) : Colors.blueGrey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingState() {
     // Reusing simplified onboarding logic if brand is null
     return Scaffold(
       backgroundColor: const Color(0xFFF0FDF4),
       body: Center(child: Text("Initializing Brand Portal...", style: GoogleFonts.inter())),
     );
  }
}
