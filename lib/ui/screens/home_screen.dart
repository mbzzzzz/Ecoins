import 'package:ecoins/core/level_system.dart';
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
import 'package:ecoins/ui/screens/scan/qr_scan_screen.dart';
import 'package:ecoins/ui/screens/impact_dashboard_screen.dart';
import 'package:flutter/services.dart';

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

  int _streak = 0;
  bool _dailyGoalCompleted = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
           setState(() {
             _points = 0;
             _carbonSaved = 0.0;
             _isLoading = false;
           });
        }
        return;
      }

      final userId = user.id;
      _avatarUrl = user.userMetadata?['avatar_url'];

      // Fetch Profile
      try {
        final profile = await _supabase
            .from('profiles')
            .select('points_balance, carbon_saved_kg')
            .eq('id', userId)
            .single();
        _points = profile['points_balance'] ?? 0;
        _carbonSaved = (profile['carbon_saved_kg'] ?? 0.0).toDouble();
      } catch (e) {
        debugPrint('Profile fetch error: $e');
      }

      // Fetch Recent Activities (Last 5 for display)
      final activities = await _supabase
          .from('activities')
          .select('*')
          .eq('user_id', userId)
          .order('logged_at', ascending: false)
          .limit(5);

      // Fetch Activity History for Streak & Daily Goal (Last 30 records is enough for standard streak check)
      final history = await _supabase
          .from('activities')
          .select('logged_at')
          .eq('user_id', userId)
          .order('logged_at', ascending: false)
          .limit(30);

      if (mounted) {
        setState(() {
          _recentActivities = List<Map<String, dynamic>>.from(activities);
          _streak = _calculateRealStreak(history);
          _dailyGoalCompleted = _checkDailyGoal(history);
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

  // Real Streak Calculation
  int _calculateRealStreak(List<dynamic> activities) {
    if (activities.isEmpty) return 0;
    
    // Parse dates and normalize to midnight (local time)
    final uniqueDates = activities.map((a) {
      final dt = DateTime.parse(a['logged_at']).toLocal();
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet().toList();

    uniqueDates.sort((a, b) => b.compareTo(a)); // Descending

    if (uniqueDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final yesterdayMidnight = todayMidnight.subtract(const Duration(days: 1));

    int streak = 0;
    DateTime currentCheck;

    // Determine start of streak (Today or Yesterday)
    if (uniqueDates.contains(todayMidnight)) {
      currentCheck = todayMidnight;
    } else if (uniqueDates.contains(yesterdayMidnight)) {
      currentCheck = yesterdayMidnight;
    } else {
      return 0; // Streak broken if neither today nor yesterday has activity
    }

    // Count backwards
    while (uniqueDates.contains(currentCheck)) {
      streak++;
      currentCheck = currentCheck.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  bool _checkDailyGoal(List<dynamic> activities) {
    if (activities.isEmpty) return false;
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    
    return activities.any((a) {
      final dt = DateTime.parse(a['logged_at']).toLocal();
      return DateTime(dt.year, dt.month, dt.day) == todayMidnight;
    });
  }

  void _logQuickAction(String category) {
    // Instead of auto-logging, we now require verification for everything.
    // Quick actions just pre-select the category in the modal.
    _showLoggerModal(initialCategory: category);
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, String category, int points) {
    return GestureDetector(
      onTap: () => _logQuickAction(category),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2), // Glassy tint
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4)
                )
              ]
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Verify & Earn',
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: 10,
            ),
          )
        ],
      ),
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
    
    // final streak = _calculateStreak(); // Removed in favor of _streak class variable

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background - Premium Dark Nature
          Positioned.fill(
            child: Container(
              color: const Color(0xFF111827), // Fallback
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3), // Darken for text visibility
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
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
                              color: Colors.white70,
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
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black.withOpacity(0.5))
                              ]
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
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.primaryGreen.withOpacity(0.5),
                                width: 2),
                            boxShadow: [
                               BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.2), blurRadius: 10)
                            ]
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withOpacity(0.1),
    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
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

                  // Hero Section (Tree) with "Living" Glow
                  Center(
                    child: GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ambient Glow
                          Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.primaryGreen.withOpacity(0.2),
                                  Colors.transparent
                                ],
                                stops: const [0.5, 1.0]
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              MyTreeWidget(points: _points, size: 240),
                              const SizedBox(height: 10),
                              Column(
                                children: [
                                  Text(
                                    LevelSystem.getLevel(_points).name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentYellow,
                                      shadows: [
                                        Shadow(blurRadius: 8, color: Colors.black.withOpacity(0.5))
                                      ]
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // XP Bar
                                  Container(
                                    width: 180,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: LevelSystem.getProgress(_points),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen,
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [BoxShadow(color: AppTheme.primaryGreen, blurRadius: 6)]
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_points} / ${LevelSystem.getNextLevel(_points).minPoints} XP',
                                    style: GoogleFonts.inter(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Impact Stats Row
                  // Removed slight overlap to add space as requested
                  Center(
                    child: GlassContainer(
                      borderRadius: BorderRadius.circular(30),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      color: Colors.black, // Darker glass
                      opacity: 0.4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.eco, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            '${_carbonSaved.toStringAsFixed(1)} kg CO₂ Saved',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Streak & Daily Challenge Row
                  Row(
                    children: [
                       Expanded(
                         child: GlassContainer(
                           padding: const EdgeInsets.all(16),
                           borderRadius: BorderRadius.circular(20),
                           child: Row(
                             children: [
                               Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text('Streak', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                                     Text('$_streak Days', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                                   ],
                                 ),
                               )
                             ],
                           ),
                         )
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: GlassContainer(
                           padding: const EdgeInsets.all(16),
                           borderRadius: BorderRadius.circular(20),
                           child: Row(
                             children: [
                               Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _dailyGoalCompleted ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _dailyGoalCompleted ? Icons.check : Icons.track_changes,
                                    color: _dailyGoalCompleted ? Colors.green : Colors.blue,
                                    size: 24
                                  ),
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text('Daily Goal', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                                     Text(
                                       _dailyGoalCompleted ? 'Completed!' : 'Log Activity',
                                       style: GoogleFonts.outfit(
                                         color: Colors.white,
                                         fontWeight: FontWeight.bold,
                                         fontSize: 16 // Slightly smaller for fit
                                       )
                                     )
                                   ],
                                 ),
                               )
                             ],
                           ),
                         )
                       ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Actions (Frictionless)
                  Text(
                    'Quick Log',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       _buildQuickAction('Reuse Bottle', Icons.water, Colors.cyan, 'recycle', 10),
                       _buildQuickAction('Bus Ride', Icons.directions_bus, Colors.purple, 'transport', 20),
                       _buildQuickAction('Vegan Meal', Icons.restaurant_menu, Colors.green, 'food', 15),
                       _buildQuickAction('Recycle', Icons.recycling, Colors.teal, 'recycle', 15),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // Steps Tracker Section
                  const StepsTrackerWidget(),

                  // Manual Log / Scan (Secondary)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showLoggerModal(),
                            child: GlassContainer(
                              borderRadius: BorderRadius.circular(20),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: AppTheme.primaryGreen,
                              opacity: 0.8,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_a_photo, color: Colors.white, size: 24),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Log Activity',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScanScreen()));
                            },
                            child: GlassContainer(
                              borderRadius: BorderRadius.circular(20),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: Colors.white,
                              opacity: 0.1,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Scan Code',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10), // Minimal padding
                ],
              ),
            ),
          ),
          
          // Removed Floating Action Button
        ],
      ),
    );
  }

  void _showLoggerModal({String? initialCategory}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityLoggerModal(
        onLogged: () => _fetchUserData(), 
        initialCategory: initialCategory
      ),
    ).then((_) => _fetchUserData());
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
