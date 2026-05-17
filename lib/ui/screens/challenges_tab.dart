import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';

class ChallengesTab extends StatefulWidget {
  const ChallengesTab({super.key});

  @override
  State<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<ChallengesTab> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _challenges = [];
  Map<String, Map<String, dynamic>> _myParticipation = {};

  @override
  void initState() {
    super.initState();
    _fetchChallenges();
  }

  Future<void> _fetchChallenges() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) { setState(() => _isLoading = false); return; }
      final uid = user.id;

      final challengesRes = await _supabase
          .from('eco_challenges')
          .select('*')
          .or('is_global.eq.true,creator_id.eq.$uid,invited_user_id.eq.$uid')
          .gte('end_date', DateTime.now().toIso8601String().substring(0, 10))
          .order('is_global', ascending: false)
          .order('created_at', ascending: false);

      final participationRes = await _supabase
          .from('challenge_participants')
          .select('challenge_id, current_value, completed')
          .eq('user_id', uid);

      final participationMap = <String, Map<String, dynamic>>{};
      for (final p in participationRes as List) {
        participationMap[p['challenge_id'] as String] = Map<String, dynamic>.from(p);
      }

      final challengeIds = (challengesRes as List).map((c) => c['id'] as String).toList();
      final countMap = <String, int>{};
      if (challengeIds.isNotEmpty) {
        final countsRes = await _supabase
            .from('challenge_participants')
            .select('challenge_id')
            .inFilter('challenge_id', challengeIds);
        for (final row in countsRes as List) {
          final cid = row['challenge_id'] as String;
          countMap[cid] = (countMap[cid] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _challenges = challengesRes.map<Map<String, dynamic>>((c) => {
            ...Map<String, dynamic>.from(c),
            '_participant_count': countMap[c['id'] as String] ?? 0,
          }).toList();
          _myParticipation = participationMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Challenges fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinChallenge(String challengeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await _supabase
          .from('profiles')
          .select('display_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      await _supabase.from('challenge_participants').insert({
        'challenge_id': challengeId,
        'user_id': user.id,
        'display_name': profile?['display_name'],
        'avatar_url': profile?['avatar_url'],
        'current_value': 0,
      });
      _fetchChallenges();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _leaveChallenge(String challengeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('challenge_participants')
          .delete()
          .eq('challenge_id', challengeId)
          .eq('user_id', user.id);
      _fetchChallenges();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCreateChallenge() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '500');
    String targetType = 'points';
    int durationDays = 7;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: GlassContainer(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Create Challenge',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 16),
                _field('Title *', titleCtrl),
                const SizedBox(height: 12),
                _field('Description (optional)', descCtrl),
                const SizedBox(height: 16),
                Text('Goal Type', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _typeChip('points', '⚡ Points', targetType,
                        () => setModal(() => targetType = 'points')),
                    const SizedBox(width: 10),
                    _typeChip('co2_kg', '🌿 CO₂ kg', targetType,
                        () => setModal(() => targetType = 'co2_kg')),
                  ],
                ),
                const SizedBox(height: 12),
                _field(
                    'Target (${targetType == 'points' ? 'points' : 'kg CO₂'})', targetCtrl,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                Text('Duration: $durationDays days',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                Slider(
                  value: durationDays.toDouble(),
                  min: 1, max: 30, divisions: 29,
                  activeColor: AppTheme.primaryGreen,
                  inactiveColor: Colors.white24,
                  onChanged: (v) => setModal(() => durationDays = v.round()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      final target = double.tryParse(targetCtrl.text) ?? 500;
                      final user = _supabase.auth.currentUser;
                      if (user == null) return;
                      try {
                        final end = DateTime.now().add(Duration(days: durationDays));
                        final result = await _supabase.from('eco_challenges').insert({
                          'title': title,
                          'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          'target_type': targetType,
                          'target_value': target,
                          'start_date': DateTime.now().toIso8601String().substring(0, 10),
                          'end_date': end.toIso8601String().substring(0, 10),
                          'creator_id': user.id,
                          'is_global': false,
                          'reward_points': 50,
                        }).select().single();
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _joinChallenge(result['id'] as String);
                      } catch (e) {
                        debugPrint('Create challenge error: $e');
                      }
                    },
                    child: Text('Create & Join',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _typeChip(String value, String label, String current, VoidCallback onTap) {
    final selected = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryGreen : Colors.white24),
        ),
        child: Text(label,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return RefreshIndicator(
      onRefresh: _fetchChallenges,
      color: AppTheme.primaryGreen,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Row(
            children: [
              Text('This Week',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: _showCreateChallenge,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: AppTheme.primaryGreen, size: 16),
                      const SizedBox(width: 4),
                      Text('Create',
                          style: GoogleFonts.inter(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_challenges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 48, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No active challenges',
                        style: GoogleFonts.inter(color: Colors.white60)),
                    const SizedBox(height: 8),
                    Text('Create one or check back next week!',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_challenges.length, (index) {
              final c = _challenges[index];
              final cid = c['id'] as String;
              final p = _myParticipation[cid];
              final isJoined = p != null;
              final targetValue = (c['target_value'] as num).toDouble();
              final currentValue = isJoined ? (p['current_value'] as num).toDouble() : 0.0;
              final progress = targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
              final isCompleted = isJoined && (p['completed'] == true);
              final isGlobal = c['is_global'] == true;
              final targetType = c['target_type'] as String? ?? 'points';
              final endDate = DateTime.tryParse(c['end_date'] ?? '');
              final daysLeft = endDate != null ? endDate.difference(DateTime.now()).inDays + 1 : 0;
              final participantCount = c['_participant_count'] as int? ?? 0;
              final targetLabel = targetType == 'co2_kg'
                  ? '${targetValue.toStringAsFixed(1)} kg CO₂'
                  : '${targetValue.toInt()} pts';
              final currentLabel = targetType == 'co2_kg'
                  ? currentValue.toStringAsFixed(1)
                  : currentValue.toInt().toString();

              return FadeInUp(
                delay: Duration(milliseconds: index * 80),
                duration: const Duration(milliseconds: 400),
                child: GlassContainer(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _badge(
                            isGlobal ? '🌍 Community' : '🤝 Personal',
                            isGlobal ? Colors.amber : Colors.lightBlueAccent,
                          ),
                          const SizedBox(width: 8),
                          _badge(
                            targetType == 'co2_kg' ? '🌿 CO₂' : '⚡ Points',
                            Colors.white54,
                          ),
                          const Spacer(),
                          Text(
                            daysLeft > 1
                                ? '$daysLeft days left'
                                : daysLeft == 1
                                    ? 'Ends today'
                                    : 'Ended',
                            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(c['title'] ?? '',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      if (c['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(c['description'],
                            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isJoined ? '$currentLabel / $targetLabel' : targetLabel,
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                          ),
                          Text('${(progress * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                  color: isCompleted ? Colors.greenAccent : AppTheme.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted ? Colors.greenAccent : AppTheme.primaryGreen),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, color: Colors.white38, size: 14),
                          const SizedBox(width: 4),
                          Text('$participantCount joined',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('+${c['reward_points']} pts reward',
                                style: GoogleFonts.inter(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const Spacer(),
                          if (isCompleted)
                            _actionChip('✅ Done', Colors.greenAccent, null)
                          else if (isJoined)
                            _actionChip('Joined ✓', Colors.white54,
                                () => _leaveChallenge(cid))
                          else
                            _actionChip('Join', AppTheme.primaryGreen,
                                () => _joinChallenge(cid),
                                filled: true),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );

  Widget _actionChip(String label, Color color, VoidCallback? onTap,
      {bool filled = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: filled ? color : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: filled ? null : Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(label,
              style: GoogleFonts.inter(
                  color: filled ? Colors.white : color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      );
}
