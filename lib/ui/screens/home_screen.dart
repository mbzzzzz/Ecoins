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
import 'package:ecoins/ui/widgets/scale_button.dart';
import 'package:ecoins/ui/widgets/shimmer_loading.dart';
import 'package:ecoins/ui/widgets/walkthrough_overlay.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ecoins/ui/widgets/level_up_celebration.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Map<String, dynamic>? _userStats;
  bool _showWalkthrough = false;
  LevelData? _newLevelData;
  int _previousPoints = -1;
  RealtimeChannel? _profileChannel;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkWalkthrough();
    _subscribeToProfile();
  }

  Future<void> _checkWalkthrough() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_walkthrough') ?? false;
    if (mounted && !seen) {
      setState(() => _showWalkthrough = true);
    }
  }

  void _subscribeToProfile() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _profileChannel = _supabase
        .channel('profile:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final updated = payload.newRecord;
            final newPoints = updated['points_balance'] as int? ?? _points;
            final prevLevel = LevelSystem.getLevel(_points);
            final currentLevel = LevelSystem.getLevel(newPoints);
            setState(() {
              _points = newPoints;
              _carbonSaved = (updated['carbon_saved_kg'] ?? _carbonSaved).toDouble();
              _avatarUrl = updated['avatar_url'] ?? _avatarUrl;
              if (currentLevel.minPoints > prevLevel.minPoints) {
                _newLevelData = currentLevel;
                _notifyFriendsOfLevelUp(currentLevel);
              }
            });
          },
        )
        .subscribe();
  }

  Future<void> _notifyFriendsOfLevelUp(LevelData newLevel) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final friendships = await _supabase
          .from('friendships')
          .select('requester_id, addressee_id')
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .eq('status', 'accepted');

      final friendIds = (friendships as List<dynamic>).map((f) {
        return (f['requester_id'] == userId
            ? f['addressee_id']
            : f['requester_id']) as String;
      }).toList();

      if (friendIds.isEmpty) return;

      final profile = await _supabase
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();
      final name = profile?['display_name'] ?? 'Your friend';

      final notifications = friendIds
          .map((fid) => {
                'user_id': fid,
                'type': 'level_up',
                'title': '🌱 $name levelled up!',
                'body': '$name just reached ${newLevel.name} on Ecoins. Can you keep up?',
                'created_at': DateTime.now().toIso8601String(),
              })
          .toList();

      await _supabase.from('notifications').insert(notifications);

      // Send actual push notifications via FCM
      try {
        await _supabase.functions.invoke('send-push', body: {
          'user_ids': friendIds,
          'title': '🌱 $name levelled up!',
          'body': '$name just reached ${newLevel.name} on Ecoins. Can you keep up?',
        });
      } catch (e) {
        debugPrint('FCM push failed (non-fatal): $e');
      }
    } catch (e) {
      debugPrint('Failed to notify friends of level up: $e');
    }
  }

  @override
  void dispose() {
    if (_profileChannel != null) {
      _supabase.removeChannel(_profileChannel!);
    }
    super.dispose();
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

      // Fetch Profile (including avatar_url from profiles table)
      try {
        final profile = await _supabase
            .from('profiles')
            .select('points_balance, carbon_saved_kg, avatar_url')
            .eq('id', userId)
            .single();
        _points = profile['points_balance'] ?? 0;
        _carbonSaved = (profile['carbon_saved_kg'] ?? 0.0).toDouble();
        _avatarUrl = profile['avatar_url'];
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
        // Level Up Check
        if (_previousPoints != -1) {
           final prevLevel = LevelSystem.getLevel(_previousPoints);
           final currentLevel = LevelSystem.getLevel(_points);
           if (currentLevel.minPoints > prevLevel.minPoints) {
             // Level Up Event!
             setState(() {
               _newLevelData = currentLevel;
             });
           }
        }
        _previousPoints = _points;

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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  void _logQuickAction(String category) {
    HapticFeedback.lightImpact();
    // Instead of auto-logging, we now require verification for everything.
    // Quick actions just pre-select the category in the modal.
    _showLoggerModal(initialCategory: category);
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, String category, int points) {
    return ScaleButton(
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
                    fit: BoxFit.cover, color: Colors.black.withOpacity(0.3), colorBlendMode: BlendMode.darken)),
             SafeArea(
               child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Skeleton Header
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: const [
                             ShimmerLoading(width: 100, height: 16),
                             SizedBox(height: 8),
                             ShimmerLoading(width: 180, height: 28),
                           ],
                         ),
                         const ShimmerLoading(width: 50, height: 50, borderRadius: BorderRadius.all(Radius.circular(25))),
                       ],
                     ),
                     const Spacer(),
                     // Skeleton Tree
                     const Center(child: ShimmerLoading(width: 240, height: 240, borderRadius: BorderRadius.all(Radius.circular(120)))),
                     const SizedBox(height: 24),
                     // Skeleton Stats
                     const Center(child: ShimmerLoading(width: 200, height: 40, borderRadius: BorderRadius.all(Radius.circular(20)))),
                     const Spacer(),
                     // Skeleton Buttons
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: List.generate(4, (index) => const ShimmerLoading(width: 60, height: 80)),
                     ),
                     const SizedBox(height: 40),
                   ],
                 ),
               ),
             ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
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
                                _greeting,
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
                          ScaleButton(
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
                            child: _avatarUrl == null
                                ? Text(
                                    _supabase.auth.currentUser?.email?[0].toUpperCase() ?? 'U',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
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
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _showLoggerModal();
                            },
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
                               HapticFeedback.mediumImpact();
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

            ],
          ),
          // Removed Floating Action Button
        ),
        // Walkthrough overlay
        if (_showWalkthrough)
          WalkthroughOverlay(
            onFinish: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_seen_walkthrough', true);
              if (mounted) setState(() => _showWalkthrough = false);
            },
            onSkip: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_seen_walkthrough', true);
              if (mounted) setState(() => _showWalkthrough = false);
            },
          ),
        // Level-up celebration overlay
        if (_newLevelData != null)
          LevelUpCelebration(
            newLevel: _newLevelData!,
            onDismiss: () => setState(() => _newLevelData = null),
          ),
      ],
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
