import 'package:ecoins/core/theme.dart';
import 'package:ecoins/core/game_points.dart';
import 'package:ecoins/ui/widgets/activity_logger_modal.dart';
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

      final results = await Future.wait([
        _supabase.from('profiles').select().eq('id', user.id).maybeSingle(),
        _supabase
            .from('activities')
            .select()
            .eq('user_id', user.id)
            .order('logged_at', ascending: false)
            .limit(50),
      ]);

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

  Future<void> _addQuickActivity(
      String label, String category, int points, double carbon) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final newActivity = {
        'user_id': user.id,
        'category': category,
        'description': label,
        'points_earned': points,
        'carbon_saved': carbon,
        'is_verified': false,
        'logged_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('activities').insert(newActivity);

      final currentPoints =
          (_profile?['points_balance'] as num? ?? 0).toInt();
      final currentCarbon =
          (_profile?['carbon_saved_kg'] as num? ?? 0.0).toDouble();

      await _supabase.from('profiles').update({
        'points_balance': currentPoints + points,
        'carbon_saved_kg': currentCarbon + carbon,
      }).eq('id', user.id);

      if (mounted) {
        setState(() {
          _profile = {
            ...?_profile,
            'points_balance': currentPoints + points,
            'carbon_saved_kg': currentCarbon + carbon,
          };
          _activities.insert(0, newActivity);
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+$points pts logged!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showQuickLogSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Log',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.textMain),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAiVerifyModal();
                  },
                  icon: const Icon(Icons.verified,
                      size: 16, color: AppTheme.primaryGreen),
                  label: Text('AI Verify',
                      style: GoogleFonts.inter(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ],
            ),
            Text(
              'No photo required — just tap and go.',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : AppTheme.textSub),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
              children: [
                _buildQuickOption(
                    Icons.directions_bike,
                    'Cycle',
                    'transport',
                    5 * GamePoints.transportPointsPerUnit,
                    5 * GamePoints.transportCo2PerUnit,
                    const Color(0xFF3B82F6),
                    isDark),
                _buildQuickOption(
                    Icons.restaurant,
                    'Veg Meal',
                    'food',
                    GamePoints.foodPointsPerUnit * 2,
                    GamePoints.foodCo2PerUnit * 2,
                    const Color(0xFFF59E0B),
                    isDark),
                _buildQuickOption(
                    Icons.recycling,
                    'Recycle',
                    'recycle',
                    GamePoints.recyclePointsPerUnit * 5,
                    GamePoints.recycleCo2PerUnit * 5,
                    const Color(0xFF10B981),
                    isDark),
                _buildQuickOption(
                    Icons.bolt,
                    'Energy',
                    'energy',
                    GamePoints.energyPointsPerUnit,
                    GamePoints.energyCo2PerUnit,
                    const Color(0xFFEAB308),
                    isDark),
                _buildQuickOption(
                    Icons.shopping_bag,
                    'Reusable',
                    'shopping',
                    GamePoints.shoppingPointsPerUnit,
                    GamePoints.shoppingCo2PerUnit,
                    const Color(0xFF8B5CF6),
                    isDark),
                _buildQuickOption(Icons.water_drop, 'Save Water', 'energy',
                    20, 0.5, const Color(0xFF06B6D4), isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAiVerifyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, __) => ActivityLoggerModal(
          onLogged: _fetchData,
        ),
      ),
    );
  }

  Widget _buildQuickOption(IconData icon, String label, String category,
      int points, double carbon, Color color, bool isDark) {
    return InkWell(
      onTap: () => _addQuickActivity(label, category, points, carbon),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration:
                BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textMain)),
          Text('+$points pts',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }

  int get _thisWeekCount {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _activities.where((a) {
      final logged = DateTime.tryParse(a['logged_at'] ?? '') ?? DateTime(2000);
      return logged.isAfter(weekAgo);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
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
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: isDark ? Colors.white : AppTheme.textMain),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text('Activity Log',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textMain)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              child: IconButton(
                icon: Icon(Icons.camera_alt_outlined,
                    color: isDark ? Colors.white : AppTheme.textMain),
                tooltip: 'AI Verify Activity',
                onPressed: _showAiVerifyModal,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.backgroundDark, const Color(0xFF1A1A2E)]
                : [AppTheme.backgroundLight, const Color(0xFFE6F0F5)],
          ),
        ),
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _fetchData,
              color: AppTheme.primaryGreen,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),

                  // Stats row
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                                  'Ecoins',
                                  '${_profile?['points_balance'] ?? 0}',
                                  Icons.savings,
                                  const Color(0xFF10B981),
                                  isDark)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildStatCard(
                                  'CO₂ Saved',
                                  '${(_profile?['carbon_saved_kg'] as num?)?.toStringAsFixed(1) ?? '0'} kg',
                                  Icons.cloud_outlined,
                                  const Color(0xFF3B82F6),
                                  isDark)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildStatCard(
                                  'This Week',
                                  '$_thisWeekCount',
                                  Icons.calendar_today_outlined,
                                  const Color(0xFF8B5CF6),
                                  isDark)),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
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

                  if (_activities.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.eco,
                                  size: 48, color: AppTheme.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            Text('No activities yet',
                                style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : AppTheme.textMain)),
                            const SizedBox(height: 8),
                            Text('Tap Log Activity to get started!',
                                style: GoogleFonts.inter(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : AppTheme.textSub)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildActivityItem(_activities[index], isDark),
                          childCount: _activities.length,
                        ),
                      ),
                    ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            ),

            Positioned(
              bottom: 30,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: _showQuickLogSheet,
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.add),
                label: Text('Log Activity',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surfaceDark.withOpacity(0.8)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textMain)),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDark ? Colors.grey[400] : AppTheme.textSub,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, bool isDark) {
    final typeKey = activity['description'] ?? activity['category'] ?? '';
    final icon = _iconFor(typeKey);
    final color = _colorFor(typeKey);
    final isVerified = activity['is_verified'] == true;
    final co2 =
        (activity['carbon_saved'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final pts = activity['points_earned'] ?? 0;

    String displayName = activity['description'] ?? 'Activity';
    // Trim appended AI metadata that older entries may have stored in description
    final metaIdx = displayName.indexOf('\n\n[Verified by AI');
    if (metaIdx != -1) displayName = displayName.substring(0, metaIdx);

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
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textMain),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified,
                                size: 10, color: AppTheme.primaryGreen),
                            const SizedBox(width: 3),
                            Text('AI',
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      timeago.format(DateTime.parse(activity['logged_at'])),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color:
                              isDark ? Colors.grey[400] : AppTheme.textSub),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('·',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[400])),
                    ),
                    Text('$co2 kg CO₂',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF3B82F6))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+$pts',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('cycle') || t.contains('bike') || t.contains('transport') || t.contains('walk')) {
      return Icons.directions_bike;
    }
    if (t.contains('veg') || t.contains('food') || t.contains('meal')) return Icons.restaurant;
    if (t.contains('recycle')) return Icons.recycling;
    if (t.contains('energy') || t.contains('bolt')) return Icons.bolt;
    if (t.contains('reusable') || t.contains('shopping') || t.contains('bag')) return Icons.shopping_bag;
    if (t.contains('water')) return Icons.water_drop;
    return Icons.eco;
  }

  Color _colorFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('cycle') || t.contains('bike') || t.contains('transport') || t.contains('walk')) {
      return const Color(0xFF3B82F6);
    }
    if (t.contains('veg') || t.contains('food') || t.contains('meal')) return const Color(0xFFF59E0B);
    if (t.contains('recycle')) return const Color(0xFF10B981);
    if (t.contains('energy') || t.contains('bolt')) return const Color(0xFFEAB308);
    if (t.contains('reusable') || t.contains('shopping') || t.contains('bag')) return const Color(0xFF8B5CF6);
    if (t.contains('water')) return const Color(0xFF06B6D4);
    return const Color(0xFF10B981);
  }
}
