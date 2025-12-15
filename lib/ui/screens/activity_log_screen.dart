import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  Map<String, dynamic>? _profile;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final profileFuture = _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      final activitiesFuture = _supabase.from('activities').select().eq('user_id', user.id).order('logged_at', ascending: false);

      final results = await Future.wait([profileFuture, activitiesFuture]);
      
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _activities = List<Map<String, dynamic>>.from(results[1] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching activity data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addActivity(String type, int points, double carbon, IconData icon) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Insert Activity
      await _supabase.from('activities').insert({
        'user_id': user.id,
        'description': type,
        'points_earned': points,
        'carbon_saved': carbon,
        'logged_at': DateTime.now().toIso8601String(),
      });

      // 2. Update Profile Stats
      if (_profile != null) {
        final newPoints = (_profile!['points'] ?? 0) + points;
        final newCarbon = (_profile!['carbon_saved'] ?? 0) + carbon;
        
        await _supabase.from('profiles').update({
          'points': newPoints,
          'carbon_saved': newCarbon,
        }).eq('id', user.id);
        
        // Optimistic Update
        setState(() {
          _profile!['points'] = newPoints;
          _profile!['carbon_saved'] = newCarbon;
          _activities.insert(0, {
            'user_id': user.id,
            'description': type,
            'points_earned': points,
            'carbon_saved': carbon,
            'logged_at': DateTime.now().toIso8601String(),
          });
        });
      } else {
        // Fallback refresh
        _fetchData();
      }
      
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddActivitySheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log New Activity', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildActivityOption(Icons.directions_bike, 'Cycle', 20, 4.2, Colors.blue, isDark),
                _buildActivityOption(Icons.restaurant, 'Veg Meal', 30, 2.5, Colors.orange, isDark),
                _buildActivityOption(Icons.recycling, 'Recycle', 15, 1.0, Colors.green, isDark),
                _buildActivityOption(Icons.bolt, 'Energy', 45, 5.0, Colors.yellow[700]!, isDark),
                _buildActivityOption(Icons.shopping_bag, 'Reusable', 10, 0.5, Colors.purple, isDark),
                _buildActivityOption(Icons.water_drop, 'Save Water', 25, 3.0, Colors.cyan, isDark),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActivityOption(IconData icon, String label, int points, double carbon, Color color, bool isDark) {
    return InkWell(
      onTap: () => _addActivity(label, points, carbon, icon),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.grey[300] : Colors.grey[800])),
          Text('+$points pts', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    // Group activities by date
    // Simple grouping logic: Today, Yesterday, Older
    // For now, I'll just list them all under "Recent Activity" to simplify, or maybe implement basic grouping.
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.backgroundDark.withOpacity(0.95) : AppTheme.backgroundLight.withOpacity(0.95),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Activity Log', style: GoogleFonts.splineSans(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // Total Ecoins Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(isDark ? 0.1 : 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.savings, color: isDark ? AppTheme.primaryGreen : Colors.green[700]), 
                                  const SizedBox(width: 8),
                                  Text('Total Ecoins', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.grey[300] : Colors.grey[600])),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('${_profile?['points'] ?? 0}', style: GoogleFonts.splineSans(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey[900], height: 1.0)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // CO2 Saved Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[100]!),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.eco, color: isDark ? Colors.green[400] : Colors.green[600]), 
                                  const SizedBox(width: 8),
                                  Text('CO2 Saved', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.grey[300] : Colors.grey[600])),
                                ],
                              ),
                              const SizedBox(height: 12),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(text: '${_profile?['carbon_saved'] ?? 0}', style: GoogleFonts.splineSans(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey[900])),
                                    TextSpan(text: 'kg', style: GoogleFonts.splineSans(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Recent Activity Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'RECENT ACTIVITY',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final activity = _activities[index];
                    return _buildActivityItem(
                      icon: _getIconForType(activity['description']),
                      iconColor: _getColorForType(activity['description']),
                      title: activity['description'] ?? 'Unknown Activity',
                      subtitle: timeago.format(DateTime.parse(activity['logged_at'])),
                      score: '+${activity['points_earned']}',
                      isDark: isDark,
                    );
                  },
                  childCount: _activities.length,
                ),
              ),
              
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          
          // FAB
          Positioned(
            bottom: 24,
            right: 20,
            child: FloatingActionButton.large(
              onPressed: _showAddActivitySheet,
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white, // Dark mode fix
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 36),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'cycle': return Icons.directions_bike;
      case 'veg meal': return Icons.restaurant;
      case 'recycle': return Icons.recycling;
      case 'energy': return Icons.bolt;
      case 'reusable': return Icons.shopping_bag;
      case 'save water': return Icons.water_drop;
      default: return Icons.eco;
    }
  }

  Color _getColorForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'cycle': return Colors.blue;
      case 'veg meal': return Colors.orange;
      case 'recycle': return Colors.green;
      case 'energy': return Colors.yellow[700]!;
      case 'reusable': return Colors.purple;
      case 'save water': return Colors.cyan;
      default: return Colors.teal;
    }
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String score,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withOpacity(0.2) : iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: isDark ? iconColor.withOpacity(0.8) : iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey[900])),
                Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(score, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.primaryGreen : Colors.green[800])),
                const SizedBox(width: 2),
                Icon(Icons.bolt, size: 16, color: isDark ? AppTheme.primaryGreen : Colors.green[800]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
