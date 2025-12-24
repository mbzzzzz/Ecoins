import 'dart:ui';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class OfferManagementScreen extends StatefulWidget {
  const OfferManagementScreen({super.key});

  @override
  State<OfferManagementScreen> createState() => _OfferManagementScreenState();
}

class _OfferManagementScreenState extends State<OfferManagementScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String? _brandId;

  // Stats
  int _activeCount = 0;
  int _redeemedCount = 0;

  // Animation controller for entry animations
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchOffers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchOffers() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _loadMockData();
        return;
      }

      // Get Brand ID
      final brand = await _supabase
          .from('brands')
          .select('id')
          .eq('owner_user_id', user.id)
          .maybeSingle();

      if (brand == null) {
        _loadMockData();
        return;
      }

      _brandId = brand['id'];

      // Fetch Offers
      final offersResponse = await _supabase
          .from('offers')
          .select()
          .eq('brand_id', _brandId!)
          .order('created_at', ascending: false);

      // Fetch Stats (Active Count)
      final activeCount = await _supabase
          .from('offers')
          .count(CountOption.exact)
          .eq('brand_id', _brandId!)
          .eq('is_active', true);

      // Calculate Total Redemptions
      int totalRedeemed = 0;
      final offerIds = offersResponse.map((e) => e['id']).toList();

      if (offerIds.isNotEmpty) {
        try {
          final redemptionCount = await _supabase
              .from('redemptions')
              .count(CountOption.exact)
              .filter('reward_id', 'in', offerIds);
          totalRedeemed = redemptionCount;
        } catch (e) {
          debugPrint('Error fetching redemption stats: $e');
        }
      }

      // Map DB data to UI Model
      final mappedOffers =
          List<Map<String, dynamic>>.from(offersResponse.map((row) {
        final bool isActive = row['is_active'] ?? false;
        final String? expiration = row['expires_at'];

        // Format expiry
        String? formattedExpiry;
        if (expiration != null) {
          try {
            // Check if it's a date string
            formattedExpiry = timeago.format(DateTime.parse(expiration),
                allowFromNow: true);
          } catch (_) {
            formattedExpiry = expiration;
          }
        }

        return {
          'id': row['id'],
          'title': row['title'] ?? 'Untitled Offer',
          'status': isActive ? 'active' : 'paused', // Map boolean to string status
          'type': row['type'] ?? 'Discount',
          'code': row['code_prefix'] ?? 'ECO-DEAL', // Placeholder or column
          'expiry': formattedExpiry,
          'image': row['image_url'],
          'stats': {
            'redeemed': 0,
            'views': 0
          } // Placeholder for per-offer stats
        };
      }));

      if (mounted) {
        setState(() {
          if (mappedOffers.isEmpty) {
            _offers = [];
          } else {
            _offers = mappedOffers;
          }
          _activeCount = activeCount;
          _redeemedCount = totalRedeemed;
          _isLoading = false;
          _controller.forward();
        });
      }
    } catch (e) {
      debugPrint('Error fetching offers: $e');
      if (mounted) _loadMockData();
    }
  }

  void _loadMockData() {
    setState(() {
      _activeCount = 3;
      _offers = [
        {
          'id': '1',
          'title': '20% Off Reusable Cups',
          'status': 'active', // active, paused, draft
          'type': 'Reusable Code',
          'code': 'ECO20',
          'expiry': 'Dec 31, 2024',
          'image':
              'https://plus.unsplash.com/premium_photo-1681488262364-8aeb1b6aac56?q=80&w=2070&auto=format&fit=crop',
          'stats': {'redeemed': 120, 'views': 450}
        },
        {
          'id': '2',
          'title': 'Free Bamboo Straw',
          'status': 'paused',
          'type': 'Unique Code',
          'code': 'BAMBOO',
          'expiry': 'Jan 15, 2025',
          'image':
              'https://images.unsplash.com/photo-1589365278144-c9e705f843ba?q=80&w=1974&auto=format&fit=crop',
          'stats': {'redeemed': 850, 'views': 1200}
        },
      ];
      _isLoading = false;
      _controller.forward();
    });
  }

  // Filter logic
  List<Map<String, dynamic>> get _filteredOffers {
    if (_selectedFilter == 'All') return _offers;
    return _offers
        .where((offer) =>
            (offer['status'] as String).toLowerCase() ==
            _selectedFilter.toLowerCase())
        .toList();
  }

  Color get _primaryColor => const Color(0xFF10B981);
  Color get _bgLight => const Color(0xFFF9FAFB);
  Color get _bgDark => const Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _bgDark : _bgLight;
    // Removed unused textColor

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Decor (Gradients)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  title: Text(
                    'Offer Management',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.blueGrey[900],
                    ),
                  ),
                  centerTitle: true,
                  backgroundColor: isDark
                      ? _bgDark.withOpacity(0.8)
                      : Colors.white.withOpacity(0.8),
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: isDark ? Colors.white : Colors.blueGrey[800]),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.add_circle_outline,
                          color: _primaryColor),
                      onPressed: () => _showOfferDialog(),
                    ),
                  ],
                ),
              ],
              body: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _primaryColor))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Scroll
                          SizedBox(
                            height: 140,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildStatCard(
                                  icon: Icons.local_offer,
                                  label: 'Active Offers',
                                  value: _activeCount.toString(),
                                  color: _primaryColor,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  icon: Icons.qr_code_2,
                                  label: 'Redeemed',
                                  value: _redeemedCount.toString(),
                                  color: Colors.blue,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  icon: Icons.eco,
                                  label: 'Impact Score',
                                  value: '98',
                                  suffix: '/100',
                                  color: Colors.amber,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                _buildFilterChip('All', isDark),
                                const SizedBox(width: 8),
                                _buildFilterChip('Live', isDark),
                                const SizedBox(width: 8),
                                _buildFilterChip('Paused', isDark),
                                const SizedBox(width: 8),
                                _buildFilterChip('Drafts', isDark),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Offer List
                          ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredOffers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final offer = _filteredOffers[index];
                              return _buildOfferCard(offer, isDark);
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOfferDialog(),
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? suffix,
    required Color color,
    required bool isDark,
  }) {
    return GlassContainer(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      opacity: isDark ? 0.4 : 0.6,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      child: Container(
        width: 130, // Min width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.blueGrey[900],
                    ),
                  ),
                  if (suffix != null)
                    TextSpan(
                      text: suffix,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor
              : (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.blueGrey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer, bool isDark) {
    final status = (offer['status'] as String).toLowerCase();
    final isActive = status == 'active';
    final isPaused = status == 'paused';
    final isDraft = status == 'draft';

    Color statusColor;
    Color statusBg;
    if (isActive) {
      statusColor = Colors.green[700]!;
      statusBg = Colors.green[50]!;
    } else if (isPaused) {
      statusColor = Colors.amber[700]!;
      statusBg = Colors.amber[50]!;
    } else {
      statusColor = Colors.blueGrey[600]!;
      statusBg = Colors.blueGrey[100]!;
    }

    if (isDark) {
      if (isActive) {
        statusColor = Colors.green[300]!;
        statusBg = Colors.green[900]!.withOpacity(0.3);
      } else if (isPaused) {
        statusColor = Colors.amber[300]!;
        statusBg = Colors.amber[900]!.withOpacity(0.3);
      } else {
        statusColor = Colors.blueGrey[400]!;
        statusBg = Colors.blueGrey[700]!;
      }
    }

    // Border color based on status for left strip
    final stripColor = isActive
        ? _primaryColor
        : (isPaused ? Colors.amber : Colors.transparent);

    return GlassContainer(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      opacity: isDark ? 0.5 : 0.7,
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Status Strip
            if (!isDraft)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: stripColor),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Stack(
                        children: [
                          Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(offer['image'] ??
                                    'https://via.placeholder.com/150'),
                                fit: BoxFit.cover,
                                colorFilter: isPaused || isDraft
                                    ? const ColorFilter.mode(
                                        Colors.grey, BlendMode.saturation)
                                    : null,
                              ),
                            ),
                          ),
                          if (status == 'active')
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.autorenew,
                                    size: 14, color: Colors.green),
                              ),
                            ),
                          if (status == 'draft')
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Center(
                                    child: Icon(Icons.edit_note,
                                        color: Colors.white)),
                              ),
                            )
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer['title'],
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white
                                    : Colors.blueGrey[900],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: statusColor.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    status.substring(0, 1).toUpperCase() +
                                        status.substring(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '• ${offer['type'] ?? 'Discount'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action / Toggle
                      if (isDraft)
                        IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.more_vert,
                                color: Colors.grey[400]))
                      else
                        Switch(
                          value: isActive,
                          onChanged: (val) {
                            // Mock toggle
                            setState(() {
                              offer['status'] = val ? 'active' : 'paused';
                            });
                          },
                          activeColor: _primaryColor,
                          thumbColor: MaterialStateProperty.all(Colors.white),
                          trackColor: MaterialStateProperty.resolveWith(
                              (states) =>
                                  states.contains(MaterialState.selected)
                                      ? _primaryColor
                                      : Colors.grey[300]),
                        )
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Footer
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[200]!))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CODE',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500]),
                            ),
                            Text(
                              offer['code'] ?? '---',
                              style: GoogleFonts.robotoMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.blueGrey[700]),
                            ),
                          ],
                        ),
                        if (isDraft)
                          TextButton(
                              onPressed: () {},
                              child: Text('Finish Setup',
                                  style: TextStyle(
                                      color: _primaryColor,
                                      fontWeight: FontWeight.bold)))
                        else if (offer['expiry'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'EXPIRES',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[500]),
                              ),
                              Text(
                                offer['expiry'],
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.blueGrey[700]),
                              ),
                            ],
                          )
                        else
                          InkWell(
                            onTap: () => _showOfferDialog(offer: offer),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.edit,
                                      size: 14, color: _primaryColor),
                                  const SizedBox(width: 4),
                                  Text('Edit Offer',
                                      style: TextStyle(
                                          color: _primaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600))
                                ],
                              ),
                            ),
                          )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferDialog({Map<String, dynamic>? offer}) {
    final titleController = TextEditingController(text: offer?['title']);
    final codeController = TextEditingController(text: offer?['code'] ?? offer?['code_prefix']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(offer == null ? 'New Campaign' : 'Edit Campaign'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Title', hintText: 'e.g., 20% Off Reusable Cups'),
              controller: titleController,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration:
                  const InputDecoration(labelText: 'Code', hintText: 'e.g., ECO20'),
              controller: codeController,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final code = codeController.text.trim();
              
              if (title.isEmpty || code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                return;
              }

              Navigator.pop(context);
              
              try {
                if (offer == null) {
                   // Create
                   await _supabase.from('offers').insert({
                     'brand_id': _brandId,
                     'title': title,
                     'code_prefix': code,
                     'is_active': true,
                     'type': 'Discount' 
                   });
                } else {
                  // Update
                  await _supabase.from('offers').update({
                    'title': title,
                    'code_prefix': code,
                  }).eq('id', offer['id']);
                }
                
                // Refresh
                _fetchOffers();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
              }
            },
            child: const Text('Save'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
