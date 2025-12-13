import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/activity_logger_modal.dart';
import 'package:ecoins/ui/widgets/my_tree_widget.dart';
import 'package:ecoins/ui/screens/leaderboard_screen.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  int _points = 0;
  double _carbonSaved = 0.0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        // MOCK DATA (For UI Review during Outage)
        if (mounted) {
          setState(() {
            _points = 1250;
            _carbonSaved = 42.5;
            _recentActivities = [
              {
                'category': 'transport',
                'description': 'Bus Ride (Mock)',
                'points_earned': 50,
                'logged_at': DateTime.now().toIso8601String(),
              },
              {
                'category': 'food',
                'description': 'Vegan Lunch (Mock)',
                'points_earned': 30,
                'logged_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
              },
            ];
            _isLoading = false;
          });
        }
        return;
      }

      final userId = user.id;

      // Fetch Profile
      final profile = await _supabase
          .from('profiles')
          .select('points_balance, carbon_saved_kg')
          .eq('id', userId)
          .single();

      // Fetch Recent Activities
      final activities = await _supabase
          .from('activities')
          .select('*')
          .eq('user_id', userId)
          .order('logged_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _points = profile['points_balance'] ?? 0;
          _carbonSaved = (profile['carbon_saved_kg'] ?? 0.0).toDouble();
          _recentActivities = List<Map<String, dynamic>>.from(activities);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLoggerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityLoggerModal(onLogged: _fetchUserData),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/images/background.png', fit: BoxFit.cover)),
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          ],
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
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
                            'Good Morning,',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _supabase.auth.currentUser?.email?.split('@')[0] ?? 'Eco Warrior',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, // Ensure circular shape
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2), // Outer border
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.2), // Semi-transparent Glassy background
                          child: Text(
                            _supabase.auth.currentUser?.email?[0].toUpperCase() ?? 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

<<<<<<< HEAD
              // Hero Card (Impact)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'This Month\'s Impact',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const LeaderboardScreen())
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.leaderboard, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Leaders', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_carbonSaved.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_upward, color: Colors.white70, size: 20),
                      ],
                    ),
                    Text(
                      'CO₂ Saved',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Points Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.stars, color: Colors.amber, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Points', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          '$_points',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Daily Challenges Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Challenges',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to challenges list if we had one, or show info
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _supabase.from('daily_challenges').select().order('created_at').limit(3),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No active challenges today'));
                    }
                    final challenges = snapshot.data!;
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: challenges.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final challenge = challenges[index];
                        return Container(
                          width: 260,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
=======
                  // Hero Section (Tree)
                  Center(
                    child: GestureDetector(
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                        );
                      },
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
>>>>>>> 990c220 (feat: Gamified tree growth and AI verification improvements)
                            children: [
                              // Glow
                              Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              // Tree Widget
                              MyTreeWidget(points: _points, size: 220),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Stats
                          Column(
                            children: [
                              Text(
                                '${_carbonSaved.toStringAsFixed(1)} kg',
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'CO₂ Saved (Tree Growth: ${_points}pts)',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Daily Progress & Quick Action Grid
                  Row(
                    children: [
                      // Daily Challenge Card
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.directions_bike, color: Colors.white, size: 24),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Daily Challenge',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                'Bike to Work',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                               LinearProgressIndicator(
                                value: 0.8,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                color: AppTheme.accentYellow,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '80% • 4/5 km ridden',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Streak Card (Passive)
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 24),
                              ),
                              const SizedBox(height: 12),
                               Text(
                                'Current Streak',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                '5 Days',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Keep it up!',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
                              ),
                              const SizedBox(height: 4), 
                              // Visual spacer to match height of neighbor roughly if needed, or just let it adjust
                              const SizedBox(height: 18), 
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLoggerModal,
        backgroundColor: Colors.white.withOpacity(0.2), // Glass FAB
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), 
            side: BorderSide(color: Colors.white.withOpacity(0.5))
        ),
        icon: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryGreen),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
        label: Text('Log Activity', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category) {
      case 'transport': return Icons.directions_bus;
      case 'energy': return Icons.bolt;
      case 'food': return Icons.restaurant;
      case 'recycle': return Icons.recycling;
      case 'shopping': return Icons.shopping_bag;
      default: return Icons.eco;
    }
  }
}
