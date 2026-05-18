import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/screens/challenges_tab.dart';
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
  int _activeCount = 0;
  List<String?> _recentAvatars = [null, null, null];

  @override
  void initState() {
    super.initState();
    _fetchHeaderData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchHeaderData() async {
    try {
      final supabase = Supabase.instance.client;
      final since = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();

      final activityRes = await supabase
          .from('activity_feed')
          .select('user_id')
          .gte('logged_at', since);

      final uniqueUsers = (activityRes as List)
          .map((r) => r['user_id'])
          .toSet();

      final profileRes = await supabase
          .from('profiles')
          .select('avatar_url')
          .not('avatar_url', 'is', null)
          .order('updated_at', ascending: false)
          .limit(3);

      final avatars = (profileRes as List)
          .map<String?>((p) => p['avatar_url'] as String?)
          .toList();
      while (avatars.length < 3) { avatars.add(null); }

      if (mounted) {
        setState(() {
          _activeCount = uniqueUsers.length;
          _recentAvatars = avatars;
        });
      }
    } catch (_) {}
  }

  void _onTabSelected(int index) {
    if (_selectedIndex != index) HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
          padding: EdgeInsets.zero,
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
                            fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: Supabase.instance.client
                      .from('notifications')
                      .select()
                      .eq('user_id',
                          Supabase.instance.client.auth.currentUser?.id ?? '')
                      .order('created_at', ascending: false)
                      .limit(20),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                          child: Text('No notifications yet',
                              style: GoogleFonts.inter(color: Colors.white60)));
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white24),
                      itemBuilder: (context, index) {
                        final n = snapshot.data![index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              n['type'] == 'message'
                                  ? Icons.chat
                                  : Icons.notifications,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          title: Text(n['title'] ?? '',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['body'] ?? '',
                                  style:
                                      GoogleFonts.inter(color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text(
                                timeago.format(
                                    DateTime.parse(n['created_at'])),
                                style: GoogleFonts.inter(
                                    color: Colors.white38, fontSize: 10),
                              ),
                            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Community',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              StackedAvatars(
                                  imageUrls: _recentAvatars,
                                  size: 24,
                                  overlap: 10),
                              const SizedBox(width: 8),
                              Text(
                                _activeCount > 0
                                    ? '$_activeCount active today'
                                    : 'Join the community',
                                style: GoogleFonts.inter(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
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
                      ),
                    ],
                  ),
                ),

                // 3-tab switcher
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        alignment: Alignment(
                          -1.0 + (_selectedIndex * 1.0),
                          0,
                        ),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: FractionallySizedBox(
                          widthFactor: 1 / 3,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(21),
                              boxShadow: [
                                BoxShadow(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _tab('Feed', 0),
                          _tab('Challenges', 1),
                          _tab('Friends', 2),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _selectedIndex = i),
                    children: const [
                      ActivityFeedTab(),
                      ChallengesTab(),
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

  Widget _tab(String label, int index) => Expanded(
        child: GestureDetector(
          onTap: () => _onTabSelected(index),
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: _selectedIndex == index
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
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
  String? _selectedCategory;
  List<String> _categories = [];

  // activity_id -> {emoji -> count}
  final Map<String, Map<String, int>> _reactions = {};
  // activity_id -> user's emoji
  final Map<String, String> _userReactions = {};

  late final RealtimeChannel _feedChannel;

  static const _emojis = ['👏', '🌿', '⚡', '💚'];

  static const _categoryLabels = {
    'recycle': '♻️ Recycling',
    'cycling': '🚲 Cycling',
    'walking': '🚶 Walking',
    'transport': '🚌 Transport',
    'energy': '⚡ Energy',
    'shopping': '🛍️ Shopping',
    'food': '🥗 Food',
    'water': '💧 Water',
  };

  @override
  void initState() {
    super.initState();
    _fetchFeed();
    _feedChannel = _supabase
        .channel('activity_feed_rt')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'activities',
          callback: (payload) async {
            // Fetch the enriched row from the view
            final row = payload.newRecord;
            final id = row['id'] as String?;
            if (id == null || !mounted) return;
            try {
              final enriched = await _supabase
                  .from('activity_feed')
                  .select()
                  .eq('id', id)
                  .maybeSingle();
              if (enriched != null && mounted) {
                setState(() => _activities.insert(0, Map<String, dynamic>.from(enriched)));
              }
            } catch (_) {}
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_feedChannel);
    super.dispose();
  }

  Future<void> _fetchFeed() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) { setState(() => _isLoading = false); return; }

      if (_friendsOnly && _friendIds.isEmpty) {
        final fs = await _supabase
            .from('friendships')
            .select('requester_id, addressee_id')
            .or('requester_id.eq.${user.id},addressee_id.eq.${user.id}')
            .eq('status', 'accepted');
        _friendIds = (fs as List<dynamic>).map<String>((f) =>
            (f['requester_id'] == user.id
                ? f['addressee_id']
                : f['requester_id']) as String).toList();
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

      // Extract categories
      final cats = <String>{};
      for (final a in data) {
        if (a['category'] != null) cats.add(a['category'] as String);
      }

      // Fetch reactions
      final ids = data
          .where((a) => a['id'] != null)
          .map((a) => a['id'] as String)
          .toList();
      if (ids.isNotEmpty) await _fetchReactions(ids, user.id);

      if (mounted) {
        setState(() {
          _activities = data;
          _categories = cats.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Feed error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReactions(List<String> ids, String uid) async {
    try {
      final res = await _supabase
          .from('activity_feed_reactions')
          .select('activity_id, emoji, user_id')
          .inFilter('activity_id', ids);

      _reactions.clear();
      _userReactions.clear();

      for (final r in res as List) {
        final aid = r['activity_id'] as String;
        final emoji = r['emoji'] as String;
        _reactions[aid] ??= {};
        _reactions[aid]![emoji] = (_reactions[aid]![emoji] ?? 0) + 1;
        if (r['user_id'] == uid) _userReactions[aid] = emoji;
      }
    } catch (_) {}
  }

  Future<void> _toggleReaction(String activityId, String emoji) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    final current = _userReactions[activityId];

    setState(() {
      _reactions[activityId] ??= {};
      if (current != null) {
        _reactions[activityId]![current] =
            ((_reactions[activityId]![current] ?? 1) - 1).clamp(0, 999);
        if (_reactions[activityId]![current] == 0) {
          _reactions[activityId]!.remove(current);
        }
        _userReactions.remove(activityId);
      }
      if (current != emoji) {
        _reactions[activityId]![emoji] =
            (_reactions[activityId]![emoji] ?? 0) + 1;
        _userReactions[activityId] = emoji;
      }
    });

    try {
      if (current != null) {
        await _supabase
            .from('activity_feed_reactions')
            .delete()
            .eq('activity_id', activityId)
            .eq('user_id', uid);
      }
      if (current != emoji) {
        await _supabase.from('activity_feed_reactions').upsert({
          'activity_id': activityId,
          'user_id': uid,
          'emoji': emoji,
        });
      }
    } catch (_) {}
  }

  void _toggleFriendsOnly() {
    setState(() {
      _friendsOnly = !_friendsOnly;
      _friendIds = [];
    });
    _fetchFeed();
  }

  String _categoryLabel(String cat) =>
      _categoryLabels[cat.toLowerCase()] ?? cat;

  @override
  Widget build(BuildContext context) {
    final displayActivities = _selectedCategory == null
        ? _activities
        : _activities
            .where((a) => a['category'] == _selectedCategory)
            .toList();

    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                _friendsOnly ? 'Friends\' Activity' : 'Global Feed',
                style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleFriendsOnly,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _friendsOnly
                        ? AppTheme.primaryGreen
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _friendsOnly
                          ? AppTheme.primaryGreen
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          _friendsOnly
                              ? Icons.people_rounded
                              : Icons.public_rounded,
                          size: 14,
                          color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _friendsOnly ? 'Friends Only' : 'Everyone',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Category chips
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _catChip('All', null),
                ..._categories.map((c) => _catChip(_categoryLabel(c), c)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),
        Expanded(child: _buildFeedContent(displayActivities)),
      ],
    );
  }

  Widget _catChip(String label, String? value) {
    final selected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected
                ? AppTheme.primaryGreen
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildFeedContent(List<Map<String, dynamic>> activities) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _friendsOnly ? Icons.people_outline : Icons.feed_outlined,
                size: 48,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _friendsOnly ? 'No friend activity yet.' : 'No activity yet.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
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
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = activities[index];
          final activityId = item['id'] as String?;
          return FadeInUp(
            delay: Duration(milliseconds: index * 60),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: item['avatar_url'] != null
                            ? NetworkImage(item['avatar_url'])
                            : null,
                        child: item['avatar_url'] == null
                            ? Text(
                                (item['user_name'] ?? '?')[0],
                                style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['user_name'] ?? 'Unknown',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text(
                              item['logged_at'] != null
                                  ? timeago.format(
                                      DateTime.parse(item['logged_at']))
                                  : '',
                              style: GoogleFonts.inter(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.accentYellow.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '+${item['points_earned']} XP',
                          style: GoogleFonts.outfit(
                              color: AppTheme.accentYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(item['description'] ?? '',
                      style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (item['is_verified'] == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('AI Verified',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_outlined,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text('${item['carbon_saved']} kg CO₂',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Reactions
                  if (activityId != null) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 10),
                    _buildReactionRow(activityId),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReactionRow(String activityId) {
    final counts = _reactions[activityId] ?? {};
    final myReaction = _userReactions[activityId];

    return Row(
      children: _emojis.map((emoji) {
        final count = counts[emoji] ?? 0;
        final isSelected = myReaction == emoji;
        return GestureDetector(
          onTap: () => _toggleReaction(activityId, emoji),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Text('$count',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
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
  List<Map<String, dynamic>> _globalLeaderboard = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _showGlobalLeaderboard = false;
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

  void _onSearchChanged() => _searchUsers(_searchController.text);

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) setState(() { _searchResults = []; _isSearching = false; });
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

      if (mounted) setState(() { _searchResults = filtered; _isSearching = false; });
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchFriendsAndRequests() async {
    if (!mounted) return;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) { setState(() => _isLoading = false); return; }
      final uid = user.id;

      final friendsData = await _supabase
          .from('friendships')
          .select('*, requester:requester_id(id, display_name, email, avatar_url, points_balance), addressee:addressee_id(id, display_name, email, avatar_url, points_balance)')
          .or('requester_id.eq.$uid,addressee_id.eq.$uid')
          .eq('status', 'accepted');

      final requestsData = await _supabase
          .from('friendships')
          .select('*, requester:requester_id(id, display_name, email, avatar_url)')
          .eq('addressee_id', uid)
          .eq('status', 'pending');

      if (mounted) {
        final normalizedFriends =
            List<Map<String, dynamic>>.from(friendsData).map((f) {
          final isRequester = f['requester_id'] == uid;
          return {...f, 'friend': isRequester ? f['addressee'] : f['requester']};
        }).toList();

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

        try {
          final selfData = await _supabase
              .from('profiles')
              .select('id, display_name, avatar_url, points_balance')
              .eq('id', uid)
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
      debugPrint('Friends fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGlobalLeaderboard() async {
    if (_globalLeaderboard.isNotEmpty) return;
    try {
      final uid = _supabase.auth.currentUser?.id;
      final res = await _supabase
          .from('profiles')
          .select('id, display_name, avatar_url, points_balance')
          .order('points_balance', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _globalLeaderboard = List<Map<String, dynamic>>.from(res).map((p) => {
            ...p,
            'is_self': p['id'] == uid,
            'display_name': p['id'] == uid
                ? '${p['display_name'] ?? 'You'} (You)'
                : p['display_name'],
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Global leaderboard error: $e');
    }
  }

  Future<void> _handleRequest(String friendshipId, bool accept) async {
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        setState(() { _searchResults = []; _isSearching = false; });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Friend request sent!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  child: Text('Share with ${friend['display_name']}',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 24),
            _shareOption(
              icon: Icons.chat_bubble_outline,
              label: 'Send Message',
              description: 'Start a conversation',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ChatScreen(friend: friend)));
              },
            ),
            const SizedBox(height: 16),
            _shareOption(
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
            _shareOption(
              icon: Icons.local_offer_outlined,
              label: 'Gift a Coupon',
              description: 'Transfer a discount code to them',
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
      context: this.context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Achievement',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                  await _supabase.from('messages').insert({
                    'sender_id': user.id,
                    'receiver_id': friend['id'],
                    'content': '🏆 Shared an achievement: ${level.name}',
                    'message_type': 'achievement',
                    'metadata': {
                      'level_name': level.name,
                      'level_asset': level.assetPath,
                      'points': points,
                    },
                  });
                } catch (_) {}
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!ctx.mounted) return;
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(friend: friend),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Image.asset(level.assetPath, width: 50, height: 50),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(level.name,
                            style: GoogleFonts.outfit(
                                color: AppTheme.accentYellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        Text('Current Level · $points XP',
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
              Text('Gift a Coupon',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('This transfers the code to ${friend['display_name']}',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
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
                          child: Text('No active coupons to gift.',
                              style: GoogleFonts.inter(color: Colors.white70)));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final coupon = snapshot.data![index];
                        final offer = coupon['offers'] as Map?;
                        final brand = offer?['brands'] as Map?;
                        final code = coupon['promo_code'] ?? offer?['discount_code'] ?? '—';

                        return InkWell(
                          onTap: () async {
                            try {
                              // Mark original as gifted
                              await _supabase
                                  .from('redemptions')
                                  .update({'status': 'gifted'})
                                  .eq('id', coupon['id']);

                              // Create new redemption for friend
                              await _supabase.from('redemptions').insert({
                                'offer_id': coupon['offer_id'],
                                'user_id': friend['id'],
                                'promo_code': code,
                                'status': 'active',
                                'redeemed_at': DateTime.now().toIso8601String(),
                              });

                              // Notify friend
                              await _supabase.from('notifications').insert({
                                'user_id': friend['id'],
                                'title': 'You received a Gift! 🎁',
                                'body':
                                    '${user.userMetadata?['display_name'] ?? 'A friend'} gifted you a ${offer?['title'] ?? 'coupon'}. Code: $code',
                                'type': 'coupon',
                                'created_at': DateTime.now().toIso8601String(),
                              });

                              // Send rich coupon message
                              await _supabase.from('messages').insert({
                                'sender_id': user.id,
                                'receiver_id': friend['id'],
                                'content': '🎁 Gifted a coupon: ${offer?['title'] ?? 'coupon'}',
                                'message_type': 'coupon',
                                'metadata': {
                                  'offer_title': offer?['title'],
                                  'brand_name': brand?['name'] ?? 'Partner',
                                  'brand_logo': brand?['logo_url'],
                                  'promo_code': code,
                                },
                              });

                              if (!context.mounted) return;
                              Navigator.pop(ctx);
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ChatScreen(friend: friend)),
                              );
                            } catch (e) {
                              debugPrint('Gift error: $e');
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: brand?['logo_url'] != null
                                          ? NetworkImage(brand!['logo_url']) as ImageProvider
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
                                      Text(offer?['title'] ?? '—',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      Text(brand?['name'] ?? 'Partner',
                                          style: GoogleFonts.inter(
                                              color: Colors.white60, fontSize: 12)),
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

  Widget _shareOption({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(description,
                        style: GoogleFonts.inter(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white38, size: 16),
            ],
          ),
        ),
      );

  Widget _buildLeaderboard() {
    final list = _showGlobalLeaderboard ? _globalLeaderboard : _leaderboard;
    if (list.isEmpty && !_showGlobalLeaderboard) return const SizedBox.shrink();

    const medals = ['🥇', '🥈', '🥉'];
    final uid = _supabase.auth.currentUser?.id;

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
                _showGlobalLeaderboard ? 'Global Top 50' : 'Friend Leaderboard',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() =>
                      _showGlobalLeaderboard = !_showGlobalLeaderboard);
                  if (_showGlobalLeaderboard) _fetchGlobalLeaderboard();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _showGlobalLeaderboard ? 'Friends' : 'Global',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('Loading...',
                style: GoogleFonts.inter(color: Colors.white38)),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final entry = list[index];
                final isSelf =
                    entry['id'] == uid || entry['is_self'] == true;
                final points = (entry['points_balance'] as num?)?.toInt() ?? 0;
                final level = LevelSystem.getLevel(points);
                final medal = index < 3 ? medals[index] : '${index + 1}';

                return Container(
                  width: 90,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelf
                        ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelf
                          ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(medal, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                        (entry['display_name'] as String? ?? '?')
                            .split(' ')
                            .first,
                        style: GoogleFonts.outfit(
                          color: isSelf
                              ? AppTheme.primaryGreen
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        level.name,
                        style:
                            GoogleFonts.inter(color: Colors.white54, fontSize: 9),
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
          // Search bar
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
                          hintText: 'Search by name or email...',
                          hintStyle: GoogleFonts.inter(color: Colors.white60),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white60),
                          onPressed: () => _searchController.clear()),
                  ],
                ),
              ),
            ),
          ),

          // Search results
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Search Results',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  if (_searchResults.isEmpty && !_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No users found',
                          style: TextStyle(color: Colors.white60)),
                    )
                  else
                    ..._searchResults.asMap().entries.map((entry) {
                      final u = entry.value;
                      return FadeInUp(
                        delay: Duration(milliseconds: entry.key * 50),
                        child: GlassContainer(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                backgroundImage: u['avatar_url'] != null
                                    ? NetworkImage(u['avatar_url'])
                                    : null,
                                child: u['avatar_url'] == null
                                    ? Text((u['display_name'] ?? '?')[0])
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u['display_name'] ?? 'Unknown',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    Text(u['email'] ?? '',
                                        style: GoogleFonts.inter(
                                            color: Colors.white60,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_add,
                                    color: AppTheme.primaryGreen),
                                onPressed: () => _sendFriendRequest(u['id']),
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

          // Pending requests
          if (_requests.isNotEmpty && _searchController.text.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Friend Requests',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
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
                          backgroundColor:
                              Colors.orange.withValues(alpha: 0.2),
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
                              Text(requester['display_name'] ?? 'Unknown',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('Wants to be friends',
                                  style: GoogleFonts.inter(
                                      color: Colors.white70, fontSize: 13)),
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

          // Leaderboard
          if (_searchController.text.isEmpty) _buildLeaderboard(),

          // My Squad
          if (_searchController.text.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('My Squad (${_friends.length})',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            if (_friends.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3)),
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
                  final profile =
                      fri['friend'] as Map<String, dynamic>? ?? {};
                  final points =
                      (profile['points_balance'] as num?)?.toInt() ?? 0;
                  final level = LevelSystem.getLevel(points);

                  return FadeInUp(
                    delay: Duration(milliseconds: index * 50),
                    child: GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () =>
                            _showShareOptions(context, profile),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              backgroundImage:
                                  profile['avatar_url'] != null
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
                                      Text(level.name,
                                          style: GoogleFonts.inter(
                                              color: AppTheme.primaryGreen,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                      Text(' · $points XP',
                                          style: GoogleFonts.inter(
                                              color: Colors.white54,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ChatScreen(friend: profile)),
                              ),
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
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }
}
