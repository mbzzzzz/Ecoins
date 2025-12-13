import 'package:ecoins/ui/screens/edit_profile_screen.dart';
import 'package:ecoins/ui/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

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
        // MOCK DATA
         await Future.delayed(const Duration(milliseconds: 500));
         if (mounted) {
           setState(() {
             _profile = {
               'display_name': 'Eco Warrior', 
               'avatar_url': null,
               'points_balance': 1250,
               'carbon_saved_kg': 42.5
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar Section
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profile?['avatar_url'] != null 
                              ? NetworkImage(_profile!['avatar_url']) 
                              : null,
                          child: _profile?['avatar_url'] == null 
                              ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _profile?['display_name'] ?? _supabase.auth.currentUser?.email ?? 'User',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Joined Dec 2025',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stats Grid
                  Row(
                    children: [
                      _buildStatCard('Points', '${_profile?['points_balance'] ?? 0}', Icons.stars, Colors.amber),
                      const SizedBox(width: 16),
                      _buildStatCard('CO₂ Saved', '${_profile?['carbon_saved_kg']?.toStringAsFixed(1) ?? 0} kg', Icons.cloud, Colors.green),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Achievements (Mock for now or can fetch from table if created)
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Achievements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              children: const [
                                Chip(avatar: Icon(Icons.directions_bike), label: Text('First Ride')),
                                Chip(avatar: Icon(Icons.grass), label: Text('Carbon Free')),
                                Chip(avatar: Icon(Icons.verified), label: Text('Verified')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Settings Options
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ).then((_) => _fetchProfile()), // Refresh after return
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
