import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _leaders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        // MOCK DATA
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            _leaders = [
              {
                'rank': 1,
                'display_name': 'GreenGiant',
                'points_balance': 3500,
                'user_id': 'mock1'
              },
              {
                'rank': 2,
                'display_name': 'EcoWarrior',
                'points_balance': 3200,
                'user_id': 'mock2'
              },
              {
                'rank': 3,
                'display_name': 'LeafyLogic',
                'points_balance': 2950,
                'user_id': 'mock3'
              },
              {
                'rank': 4,
                'display_name': 'PlanetSaver',
                'points_balance': 2100,
                'user_id': 'mock4'
              },
              {
                'rank': 5,
                'display_name': 'You',
                'points_balance': 1250,
                'user_id': 'me'
              }, // Assuming user score
            ];
            _isLoading = false;
          });
        }
        return;
      }

      final data = await _supabase
          .from('leaderboard') // Assuming a view exists or we query profiles
          .select('*')
          .order('points_balance', ascending: false) // Usually points desc
          .limit(20);

      // Add ranks
      final rankedData =
          List<Map<String, dynamic>>.from(data).asMap().entries.map((entry) {
        return {
          ...entry.value,
          'rank': entry.key + 1,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _leaders = rankedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Top Eco Warriors',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = _leaders[index];
                      final isMe =
                          user['user_id'] == _supabase.auth.currentUser?.id ||
                              user['user_id'] == 'me';
                      final rank = user['rank'];

                      return GlassContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        opacity: isMe ? 0.3 : 0.15,
                        border: isMe
                            ? Border.all(color: AppTheme.accentYellow, width: 2)
                            : null,
                        child: Row(
                          children: [
                            // Rank
                            SizedBox(
                              width: 40,
                              child: _buildRankBadge(rank),
                            ),
                            const SizedBox(width: 16),
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                (user['display_name'] ?? 'U')[0],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name
                            Expanded(
                              child: Text(
                                user['display_name'] ?? 'User',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            // Points
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${user['points_balance']}',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.accentYellow,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.stars,
                                      color: AppTheme.accentYellow, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    switch (rank) {
      case 1:
        color = const Color(0xFFFFD700);
        break; // Gold
      case 2:
        color = const Color(0xFFC0C0C0);
        break; // Silver
      case 3:
        color = const Color(0xFFCD7F32);
        break; // Bronze
      default:
        return Text(
          '#$rank',
          style: GoogleFonts.outfit(
              color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
        );
    }

    return Icon(Icons.emoji_events, color: color, size: 28);
  }
}
