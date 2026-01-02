import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ecoins/ui/screens/chat_screen.dart';
import 'package:ecoins/core/level_system.dart';


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
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Community',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GlassContainer(
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.notifications_none_rounded,
                            color: Colors.white),
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
                      // Animated Background
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
                      // Tab Labels
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
                'is_verified': true,
                'logged_at': DateTime.now()
                    .subtract(const Duration(minutes: 45))
                    .toIso8601String(),
              },
              {
                'user_name': 'Mike Chen',
                'avatar_url': null,
                'category': 'food',
                'description': 'Cooked a plant-based dinner',
                'points_earned': 50,
                'carbon_saved': 1.1,
                'is_verified': false,
                'logged_at': DateTime.now()
                    .subtract(const Duration(hours: 3))
                    .toIso8601String(),
              },
              {
                'user_name': 'Emma Wilson',
                'avatar_url': null,
                'category': 'energy',
                'description': 'Installed LED bulbs',
                'points_earned': 200,
                'carbon_saved': 5.0,
                'is_verified': true,
                'logged_at': DateTime.now()
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
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
    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));

    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed_outlined,
                size: 64, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No recent activity.',
                style: GoogleFonts.inter(color: Colors.white70)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      itemCount: _activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _activities[index];
        return GlassContainer(
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
                        ? Text((item['user_name'] ?? '?')[0],
                            style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))
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
                              fontSize: 16),
                        ),
                        Text(
                          _formatTime(item['logged_at']),
                          style: GoogleFonts.inter(
                              color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.accentYellow.withOpacity(0.5)),
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
              Text(
                item['description'] ?? '',
                style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    height: 1.4),
              ),
              const SizedBox(height: 12),
              // Tags Row
              Row(
                children: [
                  if (item['is_verified'] == true) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6), // Increased vertical padding
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.8), // Solid background for visibility
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified,
                              size: 14, color: Colors.white), // White icon
                          const SizedBox(width: 4),
                          Text(
                            'AI Verified',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white), // White text
                          ),
                        ],
                      ),
                    ),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Increased vertical padding
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen, // Solid background for visibility
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_outlined,
                            color: Colors.white, size: 14), // White icon
                        const SizedBox(width: 4),
                        Text(
                          '${item['carbon_saved']} kg CO2',
                          style: GoogleFonts.inter(
                              color: Colors.white, // White text
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              )
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
  List<Map<String, dynamic>> _searchResults = [];
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
    // Basic debounce implementation
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
      if (user == null) {
        // Mock search for guest/demo
         await Future.delayed(const Duration(milliseconds: 300));
         if(mounted) {
           setState(() {
              _searchResults = [
                {
                  'id': 'mock1',
                  'display_name': 'John Doe',
                  'email': 'john@example.com',
                  'avatar_url': null,
                },
                 {
                  'id': 'mock2',
                  'display_name': 'Jane Nature',
                  'email': 'jane@nature.com',
                  'avatar_url': 'https://i.pravatar.cc/150?u=jane',
                }
              ].where((u) => 
                (u['display_name'] as String).toLowerCase().contains(query.toLowerCase()) || 
                (u['email'] as String).toLowerCase().contains(query.toLowerCase())
              ).toList();
           });
         }
         return;
      }

      // Real Real-time search
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, email, avatar_url')
          .or('email.ilike.%$query%,display_name.ilike.%$query%')
          .neq('id', user.id) // Don't show self
          .limit(10);

      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }
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
              {
                'id': 'req1',
                'requester': {
                  'display_name': 'New Joiner',
                  'email': 'new@eco.com'
                },
                'status': 'pending'
              }
            ];
            _friends = [
              {
                'id': 'f1',
                'friend': {
                  'display_name': 'Sarah Jenkins',
                  'email': 'sarah@eco.com',
                  'avatar_url': null
                }
              },
              {
                'id': 'f2',
                'friend': {
                  'display_name': 'Mike Chen',
                  'email': 'mike@eco.com',
                  'avatar_url': null
                }
              },
            ];
            _isLoading = false;
          });
        }
        return;
      }

      final userId = user.id;

      // 1. Fetch Friends (Accepted)
      final friendsData = await _supabase
          .from('friendships')
          .select(
              '*, requester:requester_id(display_name, email, avatar_url), addressee:addressee_id(display_name, email, avatar_url)')
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .eq('status', 'accepted');

      // 2. Fetch Requests (Pending where I am the addressee)
      final requestsData = await _supabase
          .from('friendships')
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
          _friends.add({'friend': req['requester']});
        }
      });
      return;
    }

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _sendFriendRequest(String targetUserId) async {
    if (_supabase.auth.currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request sent (Mock)!')));
      _searchController.clear();
      setState(() {
         _searchResults = [];
         _isSearching = false;
      });
      return;
    }

    try {
      // Check existing
      // (simplified)

      await _supabase.from('friendships').insert({
        'requester_id': _supabase.auth.currentUser!.id,
        'addressee_id': targetUserId,
        'status': 'pending'
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
       if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  backgroundImage: friend['avatar_url'] != null ? NetworkImage(friend['avatar_url']) : null,
                   radius: 20,
                   child: friend['avatar_url'] == null ? Text((friend['display_name'] ?? '?')[0]) : null,
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
                )
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
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatScreen(friend: friend),
                ));
              }
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
              }
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
              }
            ),
             const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showAchievementSelector(BuildContext context, Map<String, dynamic> friend) async {
    // Fetch user stats
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Default mock stats if fetch fails or just basic
    int points = 0;
    try {
      final data = await _supabase.from('profiles').select('total_points').eq('id', user.id).single();
      points = data['total_points'] ?? 0;
    } catch (e) {
      // Mock if fails
      points = 1250; 
    }

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
             Text('Select Achievement', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 20),
             InkWell(
               onTap: () {
                 Navigator.pop(ctx);
                 Navigator.push(context, MaterialPageRoute(
                   builder: (_) => ChatScreen(
                     friend: friend,
                     initialMessage: "🏆 I just reached the ${level.name} level! #EcoWarrior",
                   )
                 ));
               },
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(16)
                 ),
                 child: Row(
                   children: [
                     Image.asset(level.assetPath, width: 50, height: 50),
                     const SizedBox(width: 16),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(level.name, style: GoogleFonts.outfit(color: AppTheme.accentYellow, fontWeight: FontWeight.bold, fontSize: 18)),
                         Text('Current Level • $points XP', style: GoogleFonts.inter(color: Colors.white70)),
                       ],
                     ),
                     const Spacer(),
                     const Icon(Icons.send, color: AppTheme.primaryGreen)
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 20),
           ],
         ),
      )
    );
  }

  Future<void> _showCouponSelector(BuildContext context, Map<String, dynamic> friend) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height if needed
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
               Text('Select Coupon check to Gift', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
               const SizedBox(height: 20),
               Expanded(
                 child: FutureBuilder<List<Map<String, dynamic>>>(
                   future: _supabase.from('redemptions')
                       .select('*, offers(*, brands(*))')
                       .eq('user_id', user.id)
                       .eq('status', 'active')
                       .order('redeemed_at', ascending: false),
                   builder: (context, snapshot) {
                     if (snapshot.connectionState == ConnectionState.waiting) {
                       return const Center(child: CircularProgressIndicator());
                     }
                     if (!snapshot.hasData || snapshot.data!.isEmpty) {
                       return Center(child: Text('No active coupons found.', style: GoogleFonts.inter(color: Colors.white70)));
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
                           onTap: () {
                             Navigator.pop(ctx);
                             Navigator.push(context, MaterialPageRoute(
                               builder: (_) => ChatScreen(
                                 friend: friend,
                                 initialMessage: "🎁 I'm gifting you my ${offer['title']} coupon! Code: $code",
                               )
                             ));
                           },
                           child: Container(
                             margin: const EdgeInsets.only(bottom: 12),
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.08),
                               borderRadius: BorderRadius.circular(12)
                             ),
                             child: Row(
                               children: [
                                  Container(
                                     width: 40, height: 40,
                                     decoration: BoxDecoration(
                                       borderRadius: BorderRadius.circular(8),
                                       image: DecorationImage(
                                         image: brand?['logo_url'] != null ? NetworkImage(brand['logo_url']) : const AssetImage('assets/images/logo.png') as ImageProvider,
                                         fit: BoxFit.cover
                                       )
                                     ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(offer['title'], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                        Text(brand?['name'] ?? 'Partner', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.card_giftcard, color: AppTheme.accentYellow)
                               ],
                             ),
                           ),
                         );
                       },
                     );
                   },
                 ),
               )
             ],
           ),
        ),
      )
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
                  Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(description, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Add Friend Bar
        Padding(
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
                    onPressed: () {
                      _searchController.clear();
                       // The listener will handle the update
                    },
                  ),
              ],
            ),
          ),
        ),

        // Search Results Layer
        if (_searchController.text.isNotEmpty)
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                   padding: const EdgeInsets.only(bottom: 8),
                   child: Text('Search Results', 
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))
                ),
                if (_searchResults.isEmpty && !_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No users found', style: TextStyle(color: Colors.white60)),
                  )
                else
                  ..._searchResults.map((user) => GlassContainer(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                         CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                            child: user['avatar_url'] == null ? Text( (user['display_name'] ?? '?')[0] ) : null,
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(user['display_name'] ?? 'Unknown', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                               Text(user['email'] ?? '', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                             ],
                           ),
                         ),
                         IconButton(
                           icon: const Icon(Icons.person_add, color: AppTheme.primaryGreen),
                           onPressed: () => _sendFriendRequest(user['id']),
                         )
                      ],
                    ),
                  )),
                  const Divider(color: Colors.white24, height: 32),
              ],
            ),
           ),


        // Requests Section
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
              return GlassContainer(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      child: Text((requester['display_name'] ?? '?')[0],
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold)),
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
              );
            },
          ),
        ],

        // Friends List
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
              padding: const EdgeInsets.only(top: 40),
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
                final profile = fri['friend'] ?? {};

                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        backgroundImage: profile['avatar_url'] != null
                            ? NetworkImage(profile['avatar_url'])
                            : null,
                        child: profile['avatar_url'] == null
                            ? Text((profile['display_name'] ?? 'F')[0],
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile['display_name'] ?? 'Friend',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text(profile['email'] ?? '',
                                style: GoogleFonts.inter(
                                    color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () => _showShareOptions(context, profile),
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              color: Colors.white70))
                    ],
                  ),
                );
              },
            ),
        ]
      ],
    );
  }
}
