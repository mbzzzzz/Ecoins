import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ecoins/ui/widgets/scale_button.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _leaders = [];
  final List<Map<String, dynamic>> _squads = []; // Squads feature pending backend implementation
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
          if(mounted) setState(() => _isLoading = false);
          return;
      }

      final data = await _supabase
          .from('leaderboard')
          .select('*')
          .order('points_balance', ascending: false)
          .limit(20);

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Leaderboards',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppTheme.accentYellow,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Global Warriors'),
              Tab(text: 'Top Squads'),
            ],
          ),
        ),
        body: Stack(
          children: [
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
                  : TabBarView(
                      children: [
                        _buildGlobalList(),
                        _buildSquadList(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _leaders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _leaders[index];
        final isMe = user['user_id'] == _supabase.auth.currentUser?.id ||
            user['user_id'] == 'me';
        final rank = user['rank'];

        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: ScaleButton(
            onTap: () {
               HapticFeedback.lightImpact();
            },
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              opacity: isMe ? 0.3 : (rank <= 3 ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(20),
              border: isMe 
                  ? Border.all(color: AppTheme.accentYellow, width: 2)
                  : (rank == 1 ? Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)) : null),
              child: Row(
                children: [
                   SizedBox(
                     width: 40, 
                     child: rank <= 3 
                         ? ZoomIn(delay: Duration(milliseconds: 300 + (index*100)), child: _buildRankBadge(rank)) 
                         : _buildRankBadge(rank)
                   ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: rank == 1 ? [
                         const BoxShadow(color: Color(0xFFFFD700), blurRadius: 10, spreadRadius: 1)
                      ] : null
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        (user['display_name'] ?? 'U')[0],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['display_name'] ?? 'User',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (isMe)
                          Text(
                            'That\'s You!',
                            style: GoogleFonts.inter(
                              color: AppTheme.accentYellow,
                              fontSize: 10,
                              fontWeight: FontWeight.w600
                            ),
                          )
                      ],
                    ),
                  ),
                  _buildPointsBadge(user['points_balance'], rank),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSquadList() {
    if (_squads.isEmpty) {
        return Center(
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.groups, size: 48, color: Colors.white.withOpacity(0.3)),
               const SizedBox(height: 16),
               Text('Squads coming soon!', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18)),
             ],
          ),
        );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _squads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final squad = _squads[index];
        final rank = squad['rank'];

        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: ScaleButton(
            onTap: () {
               HapticFeedback.lightImpact();
            },
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              opacity: 0.15,
              child: Row(
                children: [
                  SizedBox(width: 40, child: _buildRankBadge(rank)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(squad['icon'], color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          squad['name'],
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${squad['members']} members',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPointsBadge(squad['points'], rank),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPointsBadge(int points, int rank) {
    Color textColor = AppTheme.accentYellow;
    if (rank == 1) textColor = const Color(0xFFFFD700);
    if (rank == 2) textColor = const Color(0xFFE0E0E0);
    if (rank == 3) textColor = const Color(0xFFCD7F32);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3))
      ),
      child: Row(
        children: [
          Text(
            '$points',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.stars, color: textColor, size: 14),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    switch (rank) {
      case 1:
        color = const Color(0xFFFFD700);
        break;
      case 2:
        color = const Color(0xFFC0C0C0);
        break;
      case 3:
        color = const Color(0xFFCD7F32);
        break;
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
