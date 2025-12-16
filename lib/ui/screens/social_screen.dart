import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Community',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {}, 
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white)
                      )
                    ],
                  ),
                ),

                // Custom Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: AppTheme.primaryGreen.withOpacity(0.8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    dividerColor: Colors.transparent,
                    tabs: const [
                       Tab(text: 'Activity Feed'),
                       Tab(text: 'Friends'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      ActivityFeedTab(),
                      FriendsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityFeedTab extends StatefulWidget {
  const ActivityFeedTab({super.key});

  @override
  State<ActivityFeedTab> createState() => _ActivityFeedTabState();
}

class _ActivityFeedTabState extends State<ActivityFeedTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    if (!mounted) return;
    try {
      final user = _supabase.auth.currentUser;
      
      if (user == null) {
        // MOCK DATA
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            _activities = [
              {
                'user_name': 'Sarah Jenkins',
                'avatar_url': null,
                'category': 'transport',
                'description': 'Cycled to work (15km)',
                'points_earned': 150,
                'carbon_saved': 2.4,
                'logged_at': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
              },
              {
                'user_name': 'Mike Chen',
                'avatar_url': null,
                'category': 'food',
                'description': 'Cooked a plant-based dinner',
                'points_earned': 50,
                'carbon_saved': 1.1,
                'logged_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
              },
              {
                'user_name': 'Emma Wilson',
                'avatar_url': null,
                'category': 'energy',
                'description': 'Installed LED bulbs',
                'points_earned': 200,
                'carbon_saved': 5.0,
                'logged_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
              },
            ];
            _isLoading = false;
          });
        }
        return;
      }

      final data = await _supabase
        .from('activity_feed')
        .select()
        .order('logged_at', ascending: false)
        .limit(20);

      if (mounted) {
        setState(() {
          _activities = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching feed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white));
    
    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed_outlined, size: 64, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No recent activity.', style: GoogleFonts.inter(color: Colors.white70)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _activities[index];
        return GlassContainer(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: item['avatar_url'] != null ? NetworkImage(item['avatar_url']) : null,
                child: item['avatar_url'] == null 
                  ? Text((item['user_name'] ?? '?')[0], style: const TextStyle(color: Colors.white)) 
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['user_name'] ?? 'Unknown',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _formatTime(item['logged_at']),
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['description'] ?? '',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_outlined, color: Color(0xFF10B981), size: 12),
                              const SizedBox(width: 4),
                              Text('${item['carbon_saved']} kg', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                         ),
                         const Spacer(),
                         Text(
                           '+${item['points_earned']} pts',
                           style: GoogleFonts.outfit(color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
                         ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    return timeago.format(DateTime.parse(timestamp));
  }
}

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFriendsAndRequests();
  }

  Future<void> _fetchFriendsAndRequests() async {
    if (!mounted) return;
    try {
      final user = _supabase.auth.currentUser;
      
      if (user == null) {
        // MOCK DATA for requests and friends
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() {
            _requests = [
              {'id': 'req1', 'requester': {'display_name': 'New Joiner', 'email': 'new@eco.com'}, 'status': 'pending'}
            ];
            _friends = [
              {'id': 'f1', 'friend': {'display_name': 'Sarah Jenkins', 'email': 'sarah@eco.com', 'avatar_url': null}},
              {'id': 'f2', 'friend': {'display_name': 'Mike Chen', 'email': 'mike@eco.com', 'avatar_url': null}},
            ];
            _isLoading = false;
          });
        }
        return;
      }
      
      final userId = user.id;

      // 1. Fetch Friends (Accepted)
      final friendsData = await _supabase.from('friendships')
          .select('*, requester:requester_id(display_name, email, avatar_url), addressee:addressee_id(display_name, email, avatar_url)')
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .eq('status', 'accepted');

      // 2. Fetch Requests (Pending where I am the addressee)
      final requestsData = await _supabase.from('friendships')
          .select('*, requester:requester_id(display_name, email, avatar_url)')
          .eq('addressee_id', userId)
          .eq('status', 'pending');

      if (mounted) {
        setState(() {
          _friends = List<Map<String, dynamic>>.from(friendsData).map((f) {
             // Normalize friend object
             final isRequester = f['requester_id'] == userId;
             return {
               ...f,
               'friend': isRequester ? f['addressee'] : f['requester']
             };
          }).toList();
          
          _requests = List<Map<String, dynamic>>.from(requestsData);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching friends: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRequest(String friendshipId, bool accept) async {
    // Mock handling
    if (_supabase.auth.currentUser == null) {
      setState(() {
        final req = _requests.firstWhere((r) => r['id'] == friendshipId);
        _requests.removeWhere((r) => r['id'] == friendshipId);
        if (accept) {
          _friends.add({
             'friend': req['requester']
          });
        }
      });
      return;
    }

    try {
      if (accept) {
        await _supabase.from('friendships').update({'status': 'accepted'}).eq('id', friendshipId);
      } else {
        await _supabase.from('friendships').delete().eq('id', friendshipId);
      }
      _fetchFriendsAndRequests();
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _sendRequest() async {
    final email = _searchController.text.trim();
    if (email.isEmpty) return;
    
    if (_supabase.auth.currentUser == null) {
      _searchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent (Mock)!')));
      return;
    }

    try {
      // 1. Find user by email (This requires a secure function or RLS allowing public profile lookup)
      // For MVP Demo: active users lookup
      final user = await _supabase
          .from('profiles')
          .select('id')
          .ilike('email', email)
          .maybeSingle();

      if (user == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
        return;
      }

      final addresseeId = user['id'];
      if (addresseeId == _supabase.auth.currentUser!.id) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot add yourself')));
         return;
      }

      // Check for existing friendship
      // ... (simplified for brevity)

      // 2. Insert Friendship
      await _supabase.from('friendships').insert({
        'requester_id': _supabase.auth.currentUser!.id,
        'addressee_id': addresseeId,
        'status': 'pending'
      });

      if (mounted) {
        _searchController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!')));
      }

    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white));

    return Column(
      children: [
        // Add Friend Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Add friend by email...',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      icon: Icon(Icons.person_add, color: Colors.white60),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _sendRequest,
                  child: Text('Add', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.accentYellow)),
                ),
              ],
            ),
          ),
        ),

        // Requests Section
        if (_requests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Requests', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _requests.length,
            itemBuilder: (context, index) {
              final req = _requests[index];
              final requester = req['requester'] ?? {};
              return GlassContainer(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      child: Text((requester['display_name'] ?? '?')[0], style: const TextStyle(color: Colors.orange)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(requester['display_name'] ?? 'Unknown', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Wants to be friends', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppTheme.primaryGreen),
                      onPressed: () => _handleRequest(req['id'], true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () => _handleRequest(req['id'], false),
                    ),
                  ],
                ),
              );
            },
          ),
        ],

        // Friends List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('My Friends (${_friends.length})', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        
        Expanded(
          child: _friends.isEmpty
            ? const Center(child: Text('No friends yet.', style: TextStyle(color: Colors.white70)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                   final fri = _friends[index];
                   final profile = fri['friend'] ?? {};
                   
                   return GlassContainer(
                     margin: const EdgeInsets.only(bottom: 12),
                     padding: const EdgeInsets.all(12),
                     child: Row(
                       children: [
                         CircleAvatar(
                           backgroundColor: Colors.white.withOpacity(0.2),
                           backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null,
                           child: profile['avatar_url'] == null 
                             ? Text((profile['display_name'] ?? 'F')[0], style: const TextStyle(color: Colors.white))
                             : null,
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(profile['display_name'] ?? 'Friend', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                               Text(profile['email'] ?? '', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                             ],
                           ),
                         ),
                         Container(
                           padding: const EdgeInsets.all(4),
                           decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryGreen.withOpacity(0.2)),
                           child: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryGreen, size: 16),
                         )
                       ],
                     ),
                   );
                },
              ),
        ),
      ],
    );
  }
}
