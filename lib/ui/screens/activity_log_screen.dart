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
        // Mock data for preview if no user
        if (mounted) {
           await Future.delayed(const Duration(milliseconds: 500));
           setState(() {
            _profile = {'points': 1250, 'carbon_saved': 42.5};
            _activities = [
              {'description': 'Cycle', 'points_earned': 20, 'carbon_saved': 4.2, 'logged_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String()},
              {'description': 'Veg Meal', 'points_earned': 30, 'carbon_saved': 2.5, 'logged_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
              {'description': 'Recycle', 'points_earned': 15, 'carbon_saved': 1.0, 'logged_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
            ];
            _isLoading = false;
           });
        }
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
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log New Activity', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildActivityOption(Icons.directions_bike, 'Cycle', 20, 4.2, const Color(0xFF3B82F6), isDark),
                _buildActivityOption(Icons.restaurant, 'Veg Meal', 30, 2.5, const Color(0xFFF59E0B), isDark),
                _buildActivityOption(Icons.recycling, 'Recycle', 15, 1.0, const Color(0xFF10B981), isDark),
                _buildActivityOption(Icons.bolt, 'Energy', 45, 5.0, const Color(0xFFEAB308), isDark),
                _buildActivityOption(Icons.shopping_bag, 'Reusable', 10, 0.5, const Color(0xFF8B5CF6), isDark),
                _buildActivityOption(Icons.water_drop, 'Save Water', 25, 3.0, const Color(0xFF06B6D4), isDark),
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
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textMain)),
          Text('+$points pts', style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Gradient Background
    final bgColors = isDark 
        ? [AppTheme.backgroundDark, const Color(0xFF1A1A2E)] 
        : [AppTheme.backgroundLight, const Color(0xFFE6F0F5)];

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppTheme.textMain),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text('Activity Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
        centerTitle: true,
        systemOverlayStyle: isDark ? null : null, // Uses system default or theme
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        // Total Ecoins Card
                        Expanded(child: _buildSummaryCard('Total Ecoins', '${_profile?['points'] ?? 0}', Icons.savings, const Color(0xFF10B981), isDark)),
                        const SizedBox(width: 16),
                        // CO2 Saved Card
                        Expanded(child: _buildSummaryCard('CO₂ Saved', '${_profile?['carbon_saved']?.toStringAsFixed(1) ?? 0} kg', Icons.cloud_outlined, const Color(0xFF3B82F6), isDark)),
                      ],
                    ),
                  ),
                ),
                
                SliverPadding(
                   padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                   sliver: SliverToBoxAdapter(
                     child: Text(
                       'Recent Activity',
                       style: GoogleFonts.outfit(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: isDark ? Colors.white : AppTheme.textMain,
                       ),
                     ),
                   ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final activity = _activities[index];
                        return _buildActivityItem(
                          icon: _getIconForType(activity['description']),
                          iconColor: _getColorForType(activity['description']),
                          title: activity['description'] ?? 'Activity',
                          subtitle: timeago.format(DateTime.parse(activity['logged_at'])),
                          score: '+${activity['points_earned']}',
                          isDark: isDark,
                        );
                      },
                      childCount: _activities.length,
                    ),
                  ),
                ),
                
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
            
            // FAB
            Positioned(
              bottom: 30,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: _showAddActivitySheet,
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.add),
                label: Text('Log Activity', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark.withOpacity(0.8) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textMain,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : AppTheme.textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textMain,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : AppTheme.textSub,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                  ),
                ),
              ],
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
      case 'cycle': return const Color(0xFF3B82F6);
      case 'veg meal': return const Color(0xFFF59E0B);
      case 'recycle': return const Color(0xFF10B981);
      case 'energy': return const Color(0xFFEAB308);
      case 'reusable': return const Color(0xFF8B5CF6);
      case 'save water': return const Color(0xFF06B6D4);
      default: return const Color(0xFF10B981);
    }
  }
}
