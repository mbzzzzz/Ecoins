import 'dart:async';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;
  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _challenge;
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  bool _isJoined = false;
  bool _isCreator = false;
  late Timer _ticker;
  late RealtimeChannel _channel;

  String? get _uid => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _channel = _supabase
        .channel('challenge_${widget.challengeId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'challenge_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'challenge_id',
            value: widget.challengeId,
          ),
          callback: (payload) {
            final updated = Map<String, dynamic>.from(payload.newRecord);
            if (!mounted) return;
            setState(() {
              final idx = _participants
                  .indexWhere((p) => p['id'] == updated['id']);
              if (idx >= 0) {
                _participants[idx] = {
                  ..._participants[idx],
                  'current_value': updated['current_value'],
                  'completed': updated['completed'],
                };
                _sortParticipants();
              }
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'challenge_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'challenge_id',
            value: widget.challengeId,
          ),
          callback: (_) => _fetchData(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _ticker.cancel();
    _supabase.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final challengeRes = await _supabase
          .from('eco_challenges')
          .select('*')
          .eq('id', widget.challengeId)
          .single();

      final participantsRes = await _supabase
          .from('challenge_participants')
          .select('*')
          .eq('challenge_id', widget.challengeId);

      final participants = List<Map<String, dynamic>>.from(participantsRes);
      participants.sort((a, b) =>
          ((b['current_value'] as num?) ?? 0)
              .compareTo((a['current_value'] as num?) ?? 0));

      if (mounted) {
        setState(() {
          _challenge = Map<String, dynamic>.from(challengeRes);
          _participants = participants;
          _isJoined = participants.any((p) => p['user_id'] == uid);
          _isCreator = challengeRes['creator_id'] == uid;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Challenge detail error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sortParticipants() {
    _participants.sort((a, b) =>
        ((b['current_value'] as num?) ?? 0)
            .compareTo((a['current_value'] as num?) ?? 0));
  }

  Future<void> _join() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final profile = await _supabase
          .from('profiles')
          .select('display_name, avatar_url')
          .eq('id', uid)
          .maybeSingle();
      await _supabase.from('challenge_participants').insert({
        'challenge_id': widget.challengeId,
        'user_id': uid,
        'display_name': profile?['display_name'],
        'avatar_url': profile?['avatar_url'],
        'current_value': 0,
      });
      HapticFeedback.lightImpact();
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _leave() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _supabase
          .from('challenge_participants')
          .delete()
          .eq('challenge_id', widget.challengeId)
          .eq('user_id', uid);
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showInviteFriends() async {
    final uid = _uid;
    if (uid == null) return;

    final friendsRes = await _supabase
        .from('friendships')
        .select('requester_id, addressee_id, requester:requester_id(id, display_name, avatar_url), addressee:addressee_id(id, display_name, avatar_url)')
        .or('requester_id.eq.$uid,addressee_id.eq.$uid')
        .eq('status', 'accepted');

    final friends = (friendsRes as List).map<Map<String, dynamic>>((f) {
      final isRequester = f['requester_id'] == uid;
      return Map<String, dynamic>.from(
          (isRequester ? f['addressee'] : f['requester']) as Map);
    }).toList();

    // Get already-invited friends
    final invitedRes = await _supabase
        .from('challenge_invites')
        .select('invitee_id')
        .eq('challenge_id', widget.challengeId);
    final invitedIds =
        (invitedRes as List).map((r) => r['invitee_id'] as String).toSet();
    final joinedIds =
        _participants.map((p) => p['user_id'] as String).toSet();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scrollController) => GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('Invite Friends',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Challenge your squad to join you!',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 20),
              if (friends.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No friends to invite yet.',
                        style: GoogleFonts.inter(color: Colors.white60)),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: friends.length,
                    itemBuilder: (_, i) {
                      final f = friends[i];
                      final fid = f['id'] as String;
                      final alreadyInvited = invitedIds.contains(fid);
                      final alreadyJoined = joinedIds.contains(fid);
                      final name = f['display_name'] as String? ?? 'Friend';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              backgroundImage: f['avatar_url'] != null
                                  ? NetworkImage(f['avatar_url'])
                                  : null,
                              child: f['avatar_url'] == null
                                  ? Text(name[0],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(name,
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                            if (alreadyJoined)
                              Text('Joined',
                                  style: GoogleFonts.inter(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600))
                            else if (alreadyInvited)
                              Text('Invited',
                                  style: GoogleFonts.inter(
                                      color: Colors.white38,
                                      fontSize: 12))
                            else
                              GestureDetector(
                                onTap: () async {
                                  await _inviteFriend(fid, name);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('Invite',
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }

  Future<void> _inviteFriend(String friendId, String friendName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('challenge_invites').insert({
        'challenge_id': widget.challengeId,
        'inviter_id': user.id,
        'invitee_id': friendId,
      });
      await _supabase.from('notifications').insert({
        'user_id': friendId,
        'title': 'Challenge Invite 🏁',
        'body':
            '${user.userMetadata?['display_name'] ?? 'A friend'} challenged you: ${_challenge?['title'] ?? 'Eco Challenge'}',
        'type': 'challenge',
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invited $friendName! 🏁')));
      }
    } catch (e) {
      debugPrint('Invite error: $e');
    }
  }

  String _countdown(String endDateStr) {
    final end =
        DateTime.tryParse(endDateStr)?.add(const Duration(days: 1)) ??
            DateTime.now();
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (d > 0) return '${d}d ${h}h ${m}m left';
    if (h > 0) return '${h}h ${m}m ${s}s left';
    return '${m}m ${s}s left';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Positioned.fill(
                child: Image.asset('assets/images/background.png',
                    fit: BoxFit.cover)),
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          ],
        ),
      );
    }

    final c = _challenge!;
    final uid = _uid;
    final targetValue = (c['target_value'] as num).toDouble();
    final targetType = c['target_type'] as String? ?? 'points';
    final isGlobal = c['is_global'] == true;
    final endDate = c['end_date'] as String? ?? '';
    final myParticipant = _isJoined
        ? _participants.firstWhere((p) => p['user_id'] == uid,
            orElse: () => {})
        : null;
    final myValue = myParticipant != null
        ? (myParticipant['current_value'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final myProgress =
        targetValue > 0 ? (myValue / targetValue).clamp(0.0, 1.0) : 0.0;
    final myRank = _isJoined
        ? _participants.indexWhere((p) => p['user_id'] == uid) + 1
        : null;

    const medals = ['🥇', '🥈', '🥉'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isGlobal ? '🌍 Community Challenge' : '🤝 Friend Challenge',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png',
                fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    color: AppTheme.primaryGreen,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        // Header card
                        FadeInDown(
                          duration: const Duration(milliseconds: 400),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(20),
                            borderRadius: BorderRadius.circular(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['title'] ?? '',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                if (c['description'] != null) ...[
                                  const SizedBox(height: 6),
                                  Text(c['description'],
                                      style: GoogleFonts.inter(
                                          color: Colors.white70, fontSize: 14)),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _pill(
                                        targetType == 'co2_kg'
                                            ? '🌿 CO₂ Goal'
                                            : '⚡ Points Goal',
                                        Colors.white24),
                                    const SizedBox(width: 8),
                                    _pill(
                                        targetType == 'co2_kg'
                                            ? '${targetValue.toStringAsFixed(1)} kg'
                                            : '${targetValue.toInt()} pts',
                                        AppTheme.primaryGreen
                                            .withValues(alpha: 0.3)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.amber
                                                .withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.timer_outlined,
                                              color: Colors.amber, size: 14),
                                          const SizedBox(width: 4),
                                          Text(_countdown(endDate),
                                              style: GoogleFonts.inter(
                                                  color: Colors.amber,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isJoined) ...[
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.white12),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text('Your progress ',
                                              style: GoogleFonts.inter(
                                                  color: Colors.white70,
                                                  fontSize: 13)),
                                          if (myRank != null)
                                            Text(
                                              myRank <= 3
                                                  ? medals[myRank - 1]
                                                  : '#$myRank',
                                              style: const TextStyle(
                                                  fontSize: 16),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        targetType == 'co2_kg'
                                            ? '${myValue.toStringAsFixed(1)} / ${targetValue.toStringAsFixed(1)} kg'
                                            : '${myValue.toInt()} / ${targetValue.toInt()} pts',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: myProgress,
                                      backgroundColor: Colors.white12,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        myParticipant?['completed'] == true
                                            ? Colors.greenAccent
                                            : AppTheme.primaryGreen,
                                      ),
                                      minHeight: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Leaderboard
                        Row(
                          children: [
                            const Text('🏆',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text('Leaderboard',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text(
                              '${_participants.length} joined',
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_participants.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 40,
                                      color:
                                          Colors.white.withValues(alpha: 0.3)),
                                  const SizedBox(height: 8),
                                  Text('No participants yet — be first!',
                                      style: GoogleFonts.inter(
                                          color: Colors.white38)),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(_participants.length, (i) {
                            final p = _participants[i];
                            final isMe = p['user_id'] == uid;
                            final val =
                                (p['current_value'] as num?)?.toDouble() ??
                                    0.0;
                            final prog = targetValue > 0
                                ? (val / targetValue).clamp(0.0, 1.0)
                                : 0.0;
                            final done = p['completed'] == true;
                            final name =
                                p['display_name'] as String? ?? 'Anonymous';
                            final medal = i < 3 ? medals[i] : '${i + 1}.';

                            return FadeInUp(
                              delay: Duration(milliseconds: i * 60),
                              duration: const Duration(milliseconds: 350),
                              child: GlassContainer(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  decoration: isMe
                                      ? BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppTheme.primaryGreen
                                                  .withValues(alpha: 0.4),
                                              width: 1.5),
                                        )
                                      : null,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        child: Text(medal,
                                            style: TextStyle(
                                                fontSize: i < 3 ? 20 : 14,
                                                color: i < 3
                                                    ? null
                                                    : Colors.white54),
                                            textAlign: TextAlign.center),
                                      ),
                                      const SizedBox(width: 10),
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isMe
                                            ? AppTheme.primaryGreen
                                                .withValues(alpha: 0.3)
                                            : Colors.white
                                                .withValues(alpha: 0.15),
                                        backgroundImage:
                                            p['avatar_url'] != null
                                                ? NetworkImage(p['avatar_url'])
                                                : null,
                                        child: p['avatar_url'] == null
                                            ? Text(name[0].toUpperCase(),
                                                style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold))
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    isMe ? '$name (You)' : name,
                                                    style: GoogleFonts.outfit(
                                                      color: isMe
                                                          ? AppTheme.primaryGreen
                                                          : Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (done)
                                                  const Text('✅',
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                    child:
                                                        LinearProgressIndicator(
                                                      value: prog,
                                                      backgroundColor:
                                                          Colors.white12,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        done
                                                            ? Colors.greenAccent
                                                            : (isMe
                                                                ? AppTheme
                                                                    .primaryGreen
                                                                : Colors.white54),
                                                      ),
                                                      minHeight: 4,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  targetType == 'co2_kg'
                                                      ? '${val.toStringAsFixed(1)} kg'
                                                      : '${val.toInt()} pts',
                                                  style: GoogleFonts.inter(
                                                      color: isMe
                                                          ? AppTheme.primaryGreen
                                                          : Colors.white54,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),

                // Bottom action bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      if (_isCreator)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showInviteFriends,
                            icon: const Icon(Icons.person_add_outlined,
                                size: 18),
                            label: Text('Invite Friends',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      if (_isCreator) const SizedBox(width: 12),
                      Expanded(
                        flex: _isCreator ? 1 : 2,
                        child: ElevatedButton(
                          onPressed: _isJoined ? _leave : _join,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isJoined
                                ? Colors.white.withValues(alpha: 0.15)
                                : AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            _isJoined ? 'Leave Challenge' : 'Join Challenge',
                            style: GoogleFonts.outfit(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
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

  Widget _pill(String text, Color bg) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );
}
