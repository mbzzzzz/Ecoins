import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/screens/edit_profile_screen.dart';
import 'package:ecoins/ui/screens/notification_screen.dart';
import 'package:ecoins/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui'; // For ImageFilter

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

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
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      if (mounted) {
        setState(() {
          _profile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If table doesn't exist or error, fall back to basic info
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      context.go('/role-select'); // Go back to role select instead of login to allow role re-choice
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
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.textMain),
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
            ? Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 20, bottom: 40, left: 20, right: 20),
                child: Column(
                  children: [
                    // Profile Header Card
                    _buildProfileHeader(isDark),
                    
                    const SizedBox(height: 24),

                    // Stats Grid
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Carbon Saved', '${_profile?['carbon_saved_kg']?.toStringAsFixed(1) ?? '0'} kg', Icons.cloud_outlined, const Color(0xFF10B981), isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Eco Points', '${_profile?['points_balance'] ?? '0'}', Icons.stars_rounded, const Color(0xFFF59E0B), isDark)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Achievements Section
                    _buildAchievementsSection(isDark),

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
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: CircleAvatar(
                radius: 52,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                backgroundImage: _profile?['avatar_url'] != null 
                    ? NetworkImage(_profile!['avatar_url']) 
                    : null,
                child: _profile?['avatar_url'] == null 
                    ? Icon(Icons.person, size: 55, color: isDark ? Colors.grey[500] : Colors.grey[600]) 
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          _profile?['display_name'] ?? _supabase.auth.currentUser?.email?.split('@')[0] ?? 'Eco Warrior',
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
            'Member since Dec 2025',
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
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

  Widget _buildAchievementsSection(bool isDark) {
    return Container(
      width: double.infinity,
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
              _buildAchievementChip('First Ride', Icons.directions_bike, Colors.blue, isDark),
              _buildAchievementChip('Carbon Free', Icons.grass, Colors.green, isDark),
              _buildAchievementChip('Early Adopter', Icons.verified, Colors.purple, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementChip(String label, IconData icon, Color color, bool isDark) {
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
          title: 'Edit Profile',
          icon: Icons.edit_outlined,
          color: Colors.blue,
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ).then((_) => _fetchProfile()),
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
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(color: isDark ? Colors.grey[300] : AppTheme.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
