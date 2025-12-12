import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ActivityFeedTab(),
          FriendsTab(),
        ],
      ),
    );
  }
}

class ActivityFeedTab extends StatelessWidget {
  const ActivityFeedTab({super.key});

  Future<List<Map<String, dynamic>>> _fetchFeed() async {
    final supabase = Supabase.instance.client;
    // Assuming 'activity_feed' view exists
    return await supabase
        .from('activity_feed')
        .select()
        .order('logged_at', ascending: false)
        .limit(20);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchFeed(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feed_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No recent activity from friends.'),
              ],
            ),
          );
        }

        final activities = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = activities[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: item['avatar_url'] != null ? NetworkImage(item['avatar_url']) : null,
                  child: item['avatar_url'] == null ? Text(item['user_name']?[0] ?? '?') : null,
                ),
                title: Text(item['user_name'] ?? 'Unknown User'),
                subtitle: Text('Saved ${item['carbon_saved']}kg CO₂ via ${item['category']}'),
                trailing: Text(
                  '+${item['points_earned']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ),
            );
          },
        );
      },
    );
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
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      // Fetch accepted friendships. 
      // Note: In real app, we need to join with profiles to get details.
      // This is a simplified fetch assuming we can get profile details directly or via join.
      final response = await _supabase.from('friendships')
          .select('*, requester:requester_id(display_name, email), addressee:addressee_id(display_name, email)')
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .eq('status', 'accepted');

      if (mounted) {
        setState(() {
          _friends = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching friends: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest() async {
    final email = _searchController.text.trim();
    if (email.isEmpty) return;

    try {
      // 1. Find user by email (This requires a secure function or RLS allowing public profile lookup)
      // For MVP Demo: active users lookup
      final user = await _supabase
          .from('profiles')
          .select('id')
          .ilike('email', email) // Assuming email is stored/searchable in profiles.details for this MVP
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

      // 2. Insert Friendship
      await _supabase.from('friendships').insert({
        'requester_id': _supabase.auth.currentUser!.id,
        'addressee_id': addresseeId,
        'status': 'pending'
      });

      if (mounted) {
        _searchController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!')));
        // Refresh not strictly needed if we switch tabs or have a "Pending" section, but good practice
      }

    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Add friend by email...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendRequest,
                icon: const Icon(Icons.person_add),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _friends.isEmpty
                  ? const Center(child: Text('No friends yet. Add someone!'))
                  : ListView.builder(
                      itemCount: _friends.length,
                      itemBuilder: (context, index) {
                         final friendship = _friends[index];
                         final myId = _supabase.auth.currentUser!.id;
                         // Determine which profile is the "friend"
                         final isRequester = friendship['requester_id'] == myId;
                         final friendData = isRequester ? friendship['addressee'] : friendship['requester'];
                         
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(friendData?['display_name'] ?? 'Friend'),
                          subtitle: Text(friendData?['email'] ?? ''),
                          trailing: const Icon(Icons.check_circle, color: Colors.green),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
