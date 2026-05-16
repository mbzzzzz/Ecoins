import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ecoins/ui/screens/chat_screen.dart';
import 'package:ecoins/core/level_system.dart';
import 'package:ecoins/ui/widgets/stacked_avatars.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';


class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedIndex != index) HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notifications',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: Supabase.instance.client
                      .from('notifications')
                      .select()
                      .eq('user_id', Supabase.instance.client.auth.currentUser?.id ?? '')
                      .order('created_at', ascending: false)
                      .limit(20),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("No notifications yet", style: GoogleFonts.inter(color: Colors.white60)));
                    }
                    final notifs = snapshot.data!;
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: notifs.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white24),
                      itemBuilder: (context, index) {
                        final n = notifs[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              n['type'] == 'message' ? Icons.chat : Icons.notifications,
                              color: AppTheme.primaryGreen
                            ),
                          ),
                          title: Text(n['title'], style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['body'], style: GoogleFonts.inter(color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text(
                                timeago.format(DateTime.parse(n['created_at'])),
                                style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)
                              ),
                            ],
                          ),
                        );
                      }
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const StackedAvatars(
                                imageUrls: [null, null, null],
                                size: 24,
                                overlap: 10,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '128 Online',
                                style: GoogleFonts.inter(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showNotifications(context),
                        child: GlassContainer(
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.notifications_none_rounded,
                              color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),

                // Modern Custom Tab Switcher
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        alignment: _selectedIndex == 0
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.5 - 20,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(21),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _onTabSelected(0),
                              behavior: HitTestBehavior.translucent,
                              child: Center(
                                child: Text(
                                  'Activity Feed',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: _selectedIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _onTabSelected(1),
                              behavior: HitTestBehavior.translucent,
                              child: Center(
                                child: Text(
                                  'Friends',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: _selectedIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _selectedIndex = index),
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

// ─── Activity Feed ────────────────────────────────────────────────────────────

class ActivityFeedTab extends StatefulWidget {
  const ActivityFeedTab({super.key});

  @override
  State<ActivityFeedTab> createState() => _ActivityFeedTabState();
}

class _ActivityFeedTabState extends State<ActivityFeedTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  bool _friendsOnly = false;
  List<String> _friendIds = [];

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (_friendsOnly && _friendIds.isEmpty) {
        final fs = await _supabase
            .from('friendships')
            .select('requester_id, addressee_id')
            .or('requester_id.eq.${user.id},addressee_id.eq.${user.id}')
            .eq('status', 'accepted');
        _friendIds = (fs as List<dynamic>).map<String>((f) {
          return (f['requester_id'] == user.id
              ? f['addressee_id']
              : f['requester_id']) as String;
        }).toList();
      }

      List<Map<String, dynamic>> data;

      if (_friendsOnly) {
        if (_friendIds.isEmpty) {
          data = [];
        } else {
          data = List<Map<String, dynamic>>.from(
            await _supabase
                .from('activity_feed')
                .select()
                .inFilter('user_id', _friendIds)
                .order('logged_at', ascending: false)
                .limit(50),
          );
        }
      } else {
        data = List<Map<String, dynamic>>.from(
          await _supabase
              .from('activity_feed')
              .select()
              .order('logged_at', ascending: false)
              .limit(50),
        );
      }

      if (mounted) {
        setState(() {
          _activities = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching feed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleFriendsOnly() {
    setState(() {
      _friendsOnly = !_friendsOnly;
      _friendIds = [];
    });
    _fetchFeed();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter toggle row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                _friendsOnly ? 'Friends\' Activity' : 'Global Feed',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleFriendsOnly,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _friendsOnly
                        ? AppTheme.primaryGreen
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _friendsOnly
                          ? AppTheme.primaryGreen
                          : Colors.white.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _friendsOnly ? Icons.people_rounded : Icons.public_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _friendsOnly ? 'Friends Only' : 'Everyone',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildFeedContent()),
      ],
    );
  }

  Widget _buildFeedContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _friendsOnly ? Icons.people_outline : Icons.feed_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _friendsOnly ? 'No friend activity yet.' : 'No recent activity.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _friendsOnly
                  ? 'Your friends haven\'t logged any activities yet.'
                  : 'Connect with friends to see their progress!',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFeed,
      color: AppTheme.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = _activities[index];
          return FadeInUp(
            delay: Duration(milliseconds: index * 80),
            duration: const Duration(milliseconds: 400),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: item['avatar_url'] != null
                            ? NetworkImage(item['avatar_url'])
                            : null,
                        child: item['avatar_url'] == null
                            ? Text(
                                (item['user_name'] ?? '?')[0],
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['user_name'] ?? 'Unknown',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatTime(item['logged_at']),
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentYellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accentYellow.withOpacity(0.5)),
                        ),
                        child: Text(
                          '+${item['points_earned']} XP',
                          style: GoogleFonts.outfit(
                            color: AppTheme.accentYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['description'] ?? '',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (item['is_verified'] == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'AI Verified',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_outlined, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${item['carbon_saved']} kg CO₂',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    return timeago.format(DateTime.parse(timestamp));
  }
}

// ─── Friends Tab ─────────────────────────────────────────────────────────────

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFriendsAndRequests();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchUsers(_searchController.text);
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('profiles')
          .select('id, display_name, email, avatar_url')
          .or('email.ilike.%$query%,display_name.ilike.%$query%')
          .neq('id', user.id)
          .limit(20);

      final friendIds = <String>{};
      for (var f in _friends) {
        friendIds.add(f['requester_id'] as String);
        friendIds.add(f['addressee_id'] as String);
      }

      final filtered = List<Map<String, dynamic>>.from(response)
          .where((u) => !friendIds.contains(u['id']))
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = filtered;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchFriendsAndRequests() async {
    if (!mounted) return;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userId = user.id;

      final friendsData = await _supabase
          .from('friendships')
          .select(
              '*, requester:requester_id(id, display_name, email, avatar_url, points_balance), addressee:addressee_id(id, display_name, email, avatar_url, points_balance)')
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .eq('status', 'accepted');

      final requestsData = await _supabase
          .from('friendships')
          .select('*, requester:requester_id(id, display_name, email, avatar_url)')
          .eq('addressee_id', userId)
          .eq('status', 'pending');

      if (mounted) {
        final normalizedFriends = List<Map<String, dynamic>>.from(friendsData).map((f) {
          final isRequester = f['requester_id'] == userId;
          return {
            ...f,
            'friend': isRequester ? f['addressee'] : f['requester'],
          };
        }).toList();

        // Build leaderboard: sort friends + self by points
        final leaderboardEntries = <Map<String, dynamic>>[];
        for (final f in normalizedFriends) {
          final profile = f['friend'] as Map<String, dynamic>? ?? {};
          leaderboardEntries.add({
            'id': profile['id'],
            'display_name': profile['display_name'] ?? 'Friend',
            'avatar_url': profile['avatar_url'],
            'points_balance': profile['points_balance'] ?? 0,
          });
        }

        // Fetch current user's own profile for self entry
        try {
          final selfData = await _supabase
              .from('profiles')
              .select('id, display_name, avatar_url, points_balance')
              .eq('id', userId)
              .maybeSingle();
          if (selfData != null) {
            leaderboardEntries.add({
              'id': selfData['id'],
              'display_name': '${selfData['display_name'] ?? 'You'} (You)',
              'avatar_url': selfData['avatar_url'],
              'points_balance': selfData['points_balance'] ?? 0,
              'is_self': true,
            });
          }
        } catch (_) {}

        leaderboardEntries.sort((a, b) =>
            (b['points_balance'] as int).compareTo(a['points_balance'] as int));

        setState(() {
          _friends = normalizedFriends;
          _requests = List<Map<String, dynamic>>.from(requestsData);
          _leaderboard = leaderboardEntries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching friends: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRequest(String friendshipId, bool accept) async {
    if (_supabase.auth.currentUser == null) return;

    try {
      if (accept) {
        await _supabase
            .from('friendships')
            .update({'status': 'accepted'}).eq('id', friendshipId);
      } else {
        await _supabase.from('friendships').delete().eq('id', friendshipId);
      }
      _fetchFriendsAndRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _sendFriendRequest(String targetUserId) async {
    if (_supabase.auth.currentUser == null) return;

    try {
      await _supabase.from('friendships').insert({
        'requester_id': _supabase.auth.currentUser!.id,
        'addressee_id': targetUserId,
        'status': 'pending',
      });

      if (mounted) {
        _searchController.clear();
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showShareOptions(BuildContext context, Map<String, dynamic> friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: friend['avatar_url'] != null
                      ? NetworkImage(friend['avatar_url'])
                      : null,
                  radius: 20,
                  child: friend['avatar_url'] == null
                      ? Text((friend['display_name'] ?? '?')[0])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Share with ${friend['display_name']}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildShareOption(
              icon: Icons.chat_bubble_outline,
              label: 'Send Message',
              description: 'Start a conversation',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(friend: friend)),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildShareOption(
              icon: Icons.emoji_events_outlined,
              label: 'Share Achievement',
              description: 'Show off your progress',
              color: Colors.amber,
              onTap: () {
                Navigator.pop(ctx);
                _showAchievementSelector(context, friend);
              },
            ),
            const SizedBox(height: 16),
            _buildShareOption(
              icon: Icons.local_offer_outlined,
              label: 'Gift Coupon',
              description: 'Send a discount code',
              color: AppTheme.primaryGreen,
              onTap: () {
                Navigator.pop(ctx);
                _showCouponSelector(context, friend);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showAchievementSelector(
      BuildContext context, Map<String, dynamic> friend) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    int points = 0;
    try {
      final data = await _supabase
          .from('profiles')
          .select('points_balance')
          .eq('id', user.id)
          .single();
      points = data['points_balance'] ?? 0;
    } catch (_) {}

    final level = LevelSystem.getLevel(points);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Achievement',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () async {
                try {
                  await _supabase.from('notifications').insert({
                    'user_id': friend['id'],
                    'title': 'Achievement Unlocked! 🏆',
                    'body':
                        '${user.userMetadata?['display_name'] ?? 'A friend'} shared an achievement: ${level.name}',
                    'type': 'achievement',
                    'created_at': DateTime.now().toIso8601String(),
                  });
                } catch (e) {
                  debugPrint('Failed to send notification: $e');
                }

                if (!mounted) return;
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      friend: friend,
                      initialMessage:
                          '🏆 I just reached the ${level.name} level! #EcoWarrior',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Image.asset(level.assetPath, width: 50, height: 50),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.name,
                          style: GoogleFonts.outfit(
                              color: AppTheme.accentYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        Text('Current Level • $points XP',
                            style: GoogleFonts.inter(color: Colors.white70)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.send, color: AppTheme.primaryGreen),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showCouponSelector(
      BuildContext context, Map<String, dynamic> friend) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (_, scrollController) => GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Select Coupon to Gift',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _supabase
                      .from('redemptions')
                      .select('*, offers(*, brands(*))')
                      .eq('user_id', user.id)
                      .eq('status', 'active')
                      .order('redeemed_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text('No active coupons found.',
                            style: GoogleFonts.inter(color: Colors.white70)),
                      );
                    }

                    final coupons = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: coupons.length,
                      itemBuilder: (context, index) {
                        final coupon = coupons[index];
                        final offer = coupon['offers'];
                        final brand = offer['brands'];
                        final code = offer['discount_code'] ?? coupon['promo_code'];

                        return InkWell(
                          onTap: () async {
                            try {
                              await _supabase.from('notifications').insert({
                                'user_id': friend['id'],
                                'title': 'You received a Gift! 🎁',
                                'body':
                                    '${user.userMetadata?['display_name'] ?? 'A friend'} sent you a ${offer['title']} coupon.',
                                'type': 'coupon',
                                'created_at': DateTime.now().toIso8601String(),
                              });
                            } catch (e) {
                              debugPrint('Failed to send notification: $e');
                            }

                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  friend: friend,
                                  initialMessage:
                                      '🎁 I\'m gifting you my ${offer['title']} coupon! Code: $code',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: brand?['logo_url'] != null
                                          ? NetworkImage(brand['logo_url'])
                                              as ImageProvider
                                          : const AssetImage('assets/images/logo.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        offer['title'],
                                        style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        brand?['name'] ?? 'Partner',
                                        style: GoogleFonts.inter(
                                            color: Colors.white60, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.card_giftcard,
                                    color: AppTheme.accentYellow),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (_leaderboard.isEmpty) return const SizedBox.shrink();

    const medals = ['🥇', '🥈', '🥉'];
    final userId = _supabase.auth.currentUser?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Friend Leaderboard',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _leaderboard.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = _leaderboard[index];
              final isSelf = entry['id'] == userId || entry['is_self'] == true;
              final points = entry['points_balance'] as int;
              final level = LevelSystem.getLevel(points);
              final medal = index < 3 ? medals[index] : '${index + 1}';

              return Container(
                width: 90,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelf
                      ? AppTheme.primaryGreen.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelf
                        ? AppTheme.primaryGreen.withOpacity(0.5)
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(medal, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: entry['avatar_url'] != null
                          ? NetworkImage(entry['avatar_url'])
                          : null,
                      child: entry['avatar_url'] == null
                          ? Text(
                              (entry['display_name'] ?? '?')[0],
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (entry['display_name'] as String).split(' ').first,
                      style: GoogleFonts.outfit(
                        color: isSelf ? AppTheme.primaryGreen : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      level.name,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return RefreshIndicator(
      onRefresh: _fetchFriendsAndRequests,
      color: AppTheme.primaryGreen,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Add Friend Search Bar
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white60),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search friends by name or email...',
                          hintStyle: GoogleFonts.inter(color: Colors.white60),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white60),
                        onPressed: () => _searchController.clear(),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Search Results
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Search Results',
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_searchResults.isEmpty && !_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No users found',
                          style: TextStyle(color: Colors.white60)),
                    )
                  else
                    ..._searchResults.asMap().entries.map((entry) {
                      final index = entry.key;
                      final user = entry.value;
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 50),
                        child: GlassContainer(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: user['avatar_url'] != null
                                    ? NetworkImage(user['avatar_url'])
                                    : null,
                                child: user['avatar_url'] == null
                                    ? Text((user['display_name'] ?? '?')[0])
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['display_name'] ?? 'Unknown',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      user['email'] ?? '',
                                      style: GoogleFonts.inter(
                                          color: Colors.white60, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_add,
                                    color: AppTheme.primaryGreen),
                                onPressed: () => _sendFriendRequest(user['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const Divider(color: Colors.white24, height: 32),
                ],
              ),
            ),

          // Pending Requests
          if (_requests.isNotEmpty && _searchController.text.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Friend Requests',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                final requester = req['requester'] ?? {};
                return FadeInLeft(
                  delay: Duration(milliseconds: index * 100),
                  child: GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          child: Text(
                            (requester['display_name'] ?? '?')[0],
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                requester['display_name'] ?? 'Unknown',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              Text(
                                'Wants to be friends',
                                style: GoogleFonts.inter(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: AppTheme.primaryGreen, size: 28),
                          onPressed: () => _handleRequest(req['id'], true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.redAccent, size: 28),
                          onPressed: () => _handleRequest(req['id'], false),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          // Leaderboard (shown when not searching and has friends)
          if (_searchController.text.isEmpty && _leaderboard.isNotEmpty)
            _buildLeaderboard(),

          // My Squad
          if (_searchController.text.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'My Squad (${_friends.length})',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),

            if (_friends.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 48, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('Build your eco squad!',
                          style: GoogleFonts.inter(color: Colors.white60)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final fri = _friends[index];
                  final profile = fri['friend'] as Map<String, dynamic>? ?? {};
                  final points = profile['points_balance'] as int? ?? 0;
                  final level = LevelSystem.getLevel(points);

                  return FadeInUp(
                    delay: Duration(milliseconds: index * 50),
                    child: GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _showShareOptions(context, profile),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              backgroundImage: profile['avatar_url'] != null
                                  ? NetworkImage(profile['avatar_url'])
                                  : null,
                              child: profile['avatar_url'] == null
                                  ? Text(
                                      (profile['display_name'] ?? 'F')[0],
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile['display_name'] ?? 'Friend',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        level.name,
                                        style: GoogleFonts.inter(
                                            color: AppTheme.primaryGreen,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        ' · $points XP',
                                        style: GoogleFonts.inter(
                                            color: Colors.white54,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ChatScreen(friend: profile)),
                                );
                              },
                              icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
