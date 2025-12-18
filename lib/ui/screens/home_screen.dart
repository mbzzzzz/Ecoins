import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/activity_logger_modal.dart';
import 'package:ecoins/ui/widgets/my_tree_widget.dart';
import 'package:ecoins/ui/screens/leaderboard_screen.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:ecoins/ui/widgets/steps_tracker_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecoins/ui/screens/edit_profile_screen.dart';

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
                'logged_at': DateTime.now()
                    .subtract(const Duration(hours: 2))
                    .toIso8601String(),
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
            Positioned.fill(
                child: Image.asset('assets/images/background.png',
                    fit: BoxFit.cover)),
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
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0),
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
                            _supabase.auth.currentUser?.email?.split('@')[0] ??
                                'Eco Warrior',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const EditProfileScreen()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, // Ensure circular shape
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2), // Outer border
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withOpacity(
                                0.2), // Semi-transparent Glassy background
                            child: Text(
                              _supabase.auth.currentUser?.email?[0]
                                      .toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Hero Section (Tree)
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LeaderboardScreen()),
                        );
                      },
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow
                              Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.3),
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

                  // Steps Tracker Widget
                  const StepsTrackerWidget(),

                  const SizedBox(height: 16),

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
                                child: const Icon(Icons.directions_bike,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Daily Challenge',
                                style: GoogleFonts.inter(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                'Bike to Work',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
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
                                style: GoogleFonts.inter(
                                    color: Colors.white70, fontSize: 10),
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
                                child: const Icon(Icons.local_fire_department,
                                    color: Colors.orangeAccent, size: 24),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Current Streak',
                                style: GoogleFonts.inter(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                '5 Days',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Keep it up!',
                                style: GoogleFonts.inter(
                                    color: Colors.white70, fontSize: 10),
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

                  const SizedBox(height: 12),

                  // Log Activity Button (Inline)
                  Center(
                    child: GestureDetector(
                      onTap: _showLoggerModal,
                      child: GlassContainer(
                        borderRadius: BorderRadius.circular(30),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryGreen),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text('Log Activity',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category) {
      case 'transport':
        return Icons.directions_bus;
      case 'energy':
        return Icons.bolt;
      case 'food':
        return Icons.restaurant;
      case 'recycle':
        return Icons.recycling;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.eco;
    }
  }
}
