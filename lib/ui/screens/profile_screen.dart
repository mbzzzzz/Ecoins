import 'package:ecoins/core/analytics_service.dart';
import 'package:ecoins/core/level_system.dart';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/screens/carbon_methodology_screen.dart';
import 'package:ecoins/ui/screens/my_codes_screen.dart';
import 'package:ecoins/ui/widgets/referral_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ecoins/ui/screens/edit_profile_screen.dart';
import 'package:ecoins/ui/screens/notification_screen.dart';
import 'package:ecoins/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<double> _weeklyCarbon = List.filled(8, 0.0);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        // MOCK DATA for development/preview
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _profile = {
              'display_name': 'Eco Warrior',
              'avatar_url': null,
              'points_balance': 1250,
              'carbon_saved_kg': 42.5,
              'bio': 'Saving the planet, one step at a time.'
            };
            _isLoading = false;
          });
        }
        return;
      }

      final userId = user.id;
      final data =
          await _supabase.from('profiles').select().eq('id', userId).single();
      if (mounted) {
        setState(() {
          _profile = data;
          _isLoading = false;
        });
      }
      _fetchWeeklyCarbon();
    } catch (e) {
      // If table doesn't exist or error, fall back to basic info
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchWeeklyCarbon() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 56));
      final rows = await _supabase
          .from('activities')
          .select('carbon_saved, logged_at')
          .eq('user_id', user.id)
          .gte('logged_at', cutoff.toIso8601String())
          .order('logged_at', ascending: true);

      final buckets = List.filled(8, 0.0);
      final now = DateTime.now();
      for (final row in rows) {
        final dt = DateTime.parse(row['logged_at']).toLocal();
        final weeksAgo = now.difference(dt).inDays ~/ 7;
        if (weeksAgo < 8) {
          buckets[7 - weeksAgo] += (row['carbon_saved'] as num? ?? 0).toDouble();
        }
      }
      if (mounted) setState(() => _weeklyCarbon = buckets);
    } catch (e) {
      debugPrint('Weekly carbon fetch error: $e');
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      context.go(
          '/role-select'); // Go back to role select instead of login to allow role re-choice
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColors = isDark
        ? [AppTheme.backgroundDark, const Color(0xFF1A1A2E)]
        : [AppTheme.backgroundLight, const Color(0xFFF0F9FF)];

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : AppTheme.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColors[0].withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        iconTheme:
            IconThemeData(color: isDark ? Colors.white : AppTheme.textMain),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showLogoutDialog(context, isDark),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                    top: 20, bottom: 40, left: 20, right: 20),
                child: Column(
                  children: [
                    // Profile Header Card
                    _buildProfileHeader(isDark),

                    const SizedBox(height: 24),

                    // Level Progress Card
                    _buildLevelCard(isDark),

                    const SizedBox(height: 24),

                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                'Carbon Saved',
                                '${_profile?['carbon_saved_kg']?.toStringAsFixed(1) ?? '0'} kg',
                                Icons.cloud_outlined,
                                const Color(0xFF10B981),
                                isDark)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildStatCard(
                                'Eco Points',
                                '${_profile?['points_balance'] ?? '0'}',
                                Icons.stars_rounded,
                                const Color(0xFFF59E0B),
                                isDark)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Carbon Impact Chart
                    _buildCarbonChart(isDark),

                    const SizedBox(height: 24),

                    // Achievements Section
                    _buildAchievementsSection(isDark),

                    const SizedBox(height: 24),

                    // Referral Card
                    if (_profile?['referral_code'] != null)
                      ReferralCard(
                        referralCode: 'ECO-${_profile!['referral_code']}',
                      ),

                    if (_profile?['referral_code'] != null)
                      const SizedBox(height: 24),

                    // Menu Options
                    _buildMenuSection(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Column(
      children: [
        // Avatar with Green Circle Border
        Stack(
          alignment: Alignment.center,
          children: [
            // Green Circle Border (outer ring)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGreen, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Avatar with White Border
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: CircleAvatar(
                radius: 52,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                backgroundImage: _profile?['avatar_url'] != null
                    ? NetworkImage(_profile!['avatar_url'])
                    : null,
                child: _profile?['avatar_url'] == null
                    ? Icon(Icons.person,
                        size: 55,
                        color: isDark ? Colors.grey[500] : Colors.grey[600])
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          _profile?['display_name'] ??
              _supabase.auth.currentUser?.email?.split('@')[0] ??
              'Eco Warrior',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textMain,
          ),
        ),
        if (_profile?['bio'] != null) ...[
          const SizedBox(height: 4),
          Text(
            _profile!['bio'],
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : AppTheme.textSub,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
          ),
          child: Text(
            'Member since ${_formatMemberSince()}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  String _formatMemberSince() {
    final raw = _profile?['created_at'] ?? _profile?['member_since'];
    if (raw == null) return 'Recently';
    try {
      return DateFormat('MMM yyyy').format(DateTime.parse(raw.toString()).toLocal());
    } catch (_) {
      return 'Recently';
    }
  }

  String get _inviteCode {
    final uid = _supabase.auth.currentUser?.id ?? '';
    if (uid.isEmpty) return 'ECO-XXXXXX';
    return 'ECO-${uid.replaceAll('-', '').substring(0, 6).toUpperCase()}';
  }

  Widget _buildLevelCard(bool isDark) {
    final points = (_profile?['points_balance'] as num?)?.toInt() ?? 0;
    final level = LevelSystem.getLevel(points);
    final nextLevel = LevelSystem.getNextLevel(points);
    final progress = LevelSystem.getProgress(points);
    final isMaxLevel = level.name == nextLevel.name;
    final ptsToNext = nextLevel.minPoints - points;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Level',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(level.name,
                      style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
              Image.asset(level.assetPath, width: 48, height: 48,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.forest, color: Colors.white, size: 40)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMaxLevel
                ? 'Maximum level reached!'
                : '$ptsToNext pts to ${nextLevel.name}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textMain,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : AppTheme.textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarbonChart(bool isDark) {
    final maxY = _weeklyCarbon.reduce((a, b) => a > b ? a : b);
    final displayMax = maxY < 1 ? 5.0 : (maxY * 1.3).ceilToDouble();
    final weekLabels = ['7w', '6w', '5w', '4w', '3w', '2w', 'W', 'Now'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark.withOpacity(0.8) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Carbon Impact', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
                  Text('Last 8 weeks (kg CO₂)', style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.grey[400] : AppTheme.textSub)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: displayMax,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: displayMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        if (val == 0 || val == meta.max) return const SizedBox.shrink();
                        return Text(val.toInt().toString(), style: GoogleFonts.inter(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i < 0 || i >= weekLabels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(weekLabels[i], style: GoogleFonts.inter(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(8, (i) {
                  final isCurrentWeek = i == 7;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _weeklyCarbon[i] == 0 ? 0.1 : _weeklyCarbon[i],
                        color: isCurrentWeek ? AppTheme.primaryGreen : AppTheme.primaryGreen.withOpacity(0.4),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF1E2925) : Colors.white,
                    getTooltipItem: (group, _, rod, __) {
                      final kg = _weeklyCarbon[group.x];
                      return BarTooltipItem(
                        '${kg.toStringAsFixed(2)} kg',
                        GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surfaceDark.withOpacity(0.8)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                'Recent Achievements',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textMain,
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAchievementChip(
                  'First Ride', Icons.directions_bike, Colors.blue, isDark),
              _buildAchievementChip(
                  'Carbon Free', Icons.grass, Colors.green, isDark),
              _buildAchievementChip(
                  'Early Adopter', Icons.verified, Colors.purple, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementChip(
      String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(bool isDark) {
    return Column(
      children: [
        _buildMenuTile(
          title: 'My Redeemed Codes',
          icon: Icons.confirmation_number_outlined,
          color: AppTheme.primaryGreen,
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyCodesScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          title: 'Invite Friends',
          icon: Icons.person_add_alt_1_outlined,
          color: Colors.greenAccent,
          isDark: isDark,
          onTap: () => _showInviteDialog(context, isDark),
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          title: 'Edit Profile',
          icon: Icons.edit_outlined,
          color: Colors.blue,
          isDark: isDark,
          onTap: () {
            AnalyticsService.instance.track(AnalyticsService.profileEdited);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ).then((_) => _fetchProfile());
          },
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          title: 'Carbon Methodology',
          icon: Icons.science_outlined,
          color: Colors.teal,
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CarbonMethodologyScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          title: 'Notifications',
          icon: Icons.notifications_outlined,
          color: Colors.orange,
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          title: 'App Settings',
          icon: Icons.settings_outlined,
          color: Colors.grey,
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  void _showInviteDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism,
                    color: Colors.greenAccent, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Invite Your Squad',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your code and earn 500 XP when friends join!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _inviteCode,
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _inviteCode));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Code copied to clipboard!'),
                            backgroundColor: AppTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy_rounded,
                          size: 20, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
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
        child: ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textMain,
              fontSize: 16,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 5)
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 40),
               const SizedBox(height: 16),
               Text('Sign Out',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
               const SizedBox(height: 8),
               Text('Are you sure you want to sign out?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white70)),
               const SizedBox(height: 24),
               Row(
                 children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.white60)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _signOut();
                        },
                        child: const Text('Sign Out'),
                      ),
                    ),
                 ],
               )
            ],
          ),
        ),
      ),
    );
  }
}
