import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final data = await _supabase
          .from('leaderboard')
          .select('*')
          .order('rank', ascending: true)
          .limit(20);

      if (mounted) {
        setState(() {
          _leaders = List<Map<String, dynamic>>.from(data);
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
      appBar: AppBar(title: const Text('Top Eco Warriors')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _leaders.length,
              itemBuilder: (context, index) {
                final user = _leaders[index];
                final isMe = user['user_id'] == _supabase.auth.currentUser?.id;
                
                return ListTile(
                  tileColor: isMe ? const Color(0xFF10B981).withOpacity(0.1) : null,
                  leading: CircleAvatar(
                    backgroundColor: _getRankColor(index + 1),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: index < 3 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user['display_name'] ?? 'User ${index + 1}',
                    style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${user['points_balance']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.stars, color: Colors.amber, size: 16),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700); // Gold
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return Colors.grey.shade200;
    }
  }
}
