import 'package:ecoins/core/level_system.dart';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> friend;
  final String? initialMessage;

  const ChatScreen({super.key, required this.friend, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  late final String _conversationId;

  @override
  void initState() {
    super.initState();
    final friendId = widget.friend['id'] ?? widget.friend['friend']?['id'];
    if (friendId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Invalid Friend ID')));
        Navigator.pop(context);
      });
      _conversationId = '';
      _messagesStream = const Stream.empty();
      return;
    }
    _conversationId = friendId;

    final myId = _supabase.auth.currentUser!.id;

    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data.where((msg) {
              final sender = msg['sender_id'];
              final receiver = msg['receiver_id'];
              return (sender == myId && receiver == _conversationId) ||
                  (sender == _conversationId && receiver == myId);
            }).toList());

    // Pre-fill text (does NOT auto-send — just populates the field)
    if (widget.initialMessage != null) {
      _controller.text = widget.initialMessage!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final myId = _supabase.auth.currentUser!.id;
    try {
      await _supabase.from('messages').insert({
        'sender_id': myId,
        'receiver_id': _conversationId,
        'content': text.trim(),
        'message_type': 'text',
      });
      _controller.clear();
      Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  Future<void> _sendRichMessage({
    required String content,
    required String messageType,
    required Map<String, dynamic> metadata,
  }) async {
    final myId = _supabase.auth.currentUser!.id;
    try {
      await _supabase.from('messages').insert({
        'sender_id': myId,
        'receiver_id': _conversationId,
        'content': content,
        'message_type': messageType,
        'metadata': metadata,
      });
      Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  Future<void> _shareAchievement() async {
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

    await _sendRichMessage(
      content: '🏆 Shared an achievement: ${level.name}',
      messageType: 'achievement',
      metadata: {
        'level_name': level.name,
        'level_asset': level.assetPath,
        'points': points,
      },
    );
    HapticFeedback.lightImpact();
  }

  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                _attachOption(
                  icon: Icons.emoji_events_rounded,
                  label: 'Achievement',
                  color: Colors.amber,
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareAchievement();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );

  Future<void> _clearChat() async {
    try {
      final myId = _supabase.auth.currentUser!.id;
      await _supabase.from('messages').delete().or(
          'and(sender_id.eq.$myId,receiver_id.eq.$_conversationId),and(sender_id.eq.$_conversationId,receiver_id.eq.$myId)');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Chat cleared.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendName =
        (widget.friend['display_name'] ?? widget.friend['friend']?['display_name'] ?? 'Friend')
            .toString()
            .trim()
            .isEmpty
            ? 'Friend'
            : (widget.friend['display_name'] ?? widget.friend['friend']?['display_name'] ?? 'Friend').toString();

    final avatarUrl =
        widget.friend['avatar_url'] ?? widget.friend['friend']?['avatar_url'];
    final myId = _supabase.auth.currentUser?.id;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      friendName.isNotEmpty
                          ? friendName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friendName,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('Eco Community',
                    style: GoogleFonts.inter(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Clear Chat?'),
                content: const Text(
                    'This will delete the conversation history permanently.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () {
                        _clearChat();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark.withValues(alpha: 0.8),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: GlassContainer(
              opacity: 0.1,
              borderRadius: BorderRadius.zero,
              child: Container()),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png',
                fit: BoxFit.cover),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style:
                                  const TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!;

                    if (messages.isEmpty) {
                      return Center(
                          child: Text('Start the conversation!',
                              style: GoogleFonts.inter(
                                  color: Colors.white60)));
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients &&
                          _scrollController.position.pixels >=
                              _scrollController.position.maxScrollExtent -
                                  80) {
                        _scrollToBottom();
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding:
                          const EdgeInsets.fromLTRB(20, 110, 20, 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender_id'] == myId;
                        final ts = msg['created_at'] as String?;
                        final createdAt = ts != null
                            ? DateTime.tryParse(ts)?.toLocal() ??
                                DateTime.now()
                            : DateTime.now();

                        bool showDateHeader = false;
                        if (index == 0) {
                          showDateHeader = true;
                        } else {
                          final prevTs =
                              messages[index - 1]['created_at'] as String?;
                          final prevDate = prevTs != null
                              ? DateTime.tryParse(prevTs)?.toLocal() ??
                                  DateTime.now()
                              : DateTime.now();
                          if (prevDate.day != createdAt.day ||
                              prevDate.month != createdAt.month ||
                              prevDate.year != createdAt.year) {
                            showDateHeader = true;
                          }
                        }

                        bool isFirstInGroup = true;
                        if (index > 0 && !showDateHeader) {
                          if (messages[index - 1]['sender_id'] ==
                              msg['sender_id']) {
                            isFirstInGroup = false;
                          }
                        }

                        return FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            children: [
                              if (showDateHeader)
                                _buildDateHeader(createdAt),
                              Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: 4,
                                    top: isFirstInGroup ? 12 : 0,
                                  ),
                                  constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context)
                                              .size
                                              .width *
                                          0.78),
                                  child: _buildMessageBubble(
                                      msg, isMe, createdAt,
                                      isFirstInGroup: isFirstInGroup),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Input area
              Container(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 28),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2))
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showAttachMenu,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white70, size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: TextField(
                          controller: _controller,
                          textCapitalization:
                              TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          minLines: 1,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle:
                                GoogleFonts.inter(color: Colors.white60),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _sendMessage(_controller.text);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.4),
                                blurRadius: 8),
                          ],
                        ),
                        child: const Icon(Icons.send,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> msg, bool isMe, DateTime createdAt,
      {bool isFirstInGroup = true}) {
    final type = msg['message_type'] as String? ?? 'text';

    if (type == 'achievement') {
      return _buildAchievementBubble(msg, isMe, createdAt);
    }
    if (type == 'coupon') {
      return _buildCouponBubble(msg, isMe, createdAt);
    }
    return _buildTextBubble(msg, isMe, createdAt, isFirstInGroup: isFirstInGroup);
  }

  Widget _buildTextBubble(
      Map<String, dynamic> msg, bool isMe, DateTime createdAt,
      {bool isFirstInGroup = true}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.primaryGreen
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe
                ? const Radius.circular(20)
                : (isFirstInGroup ? Radius.zero : const Radius.circular(5)),
            bottomRight: isMe
                ? (isFirstInGroup ? Radius.zero : const Radius.circular(5))
                : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg['content'] ?? '',
              style: GoogleFonts.inter(
                  color: isMe ? Colors.white : AppTheme.textDark,
                  fontSize: 15,
                  height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(createdAt, locale: 'en_short'),
              style: GoogleFonts.inter(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.4),
                  fontSize: 10),
            ),
          ],
        ),
      );

  Widget _buildAchievementBubble(
      Map<String, dynamic> msg, bool isMe, DateTime createdAt) {
    final meta = msg['metadata'] != null
        ? Map<String, dynamic>.from(msg['metadata'] as Map)
        : <String, dynamic>{};
    final levelName = meta['level_name'] as String? ?? 'Eco Level';
    final levelAsset = meta['level_asset'] as String? ?? '';
    final points = (meta['points'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMe
              ? [const Color(0xFF065F46), AppTheme.primaryGreen]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              Text('Achievement Unlocked!',
                  style: GoogleFonts.inter(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (levelAsset.isNotEmpty)
                Image.asset(levelAsset,
                    width: 48, height: 48,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 48))
              else
                const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 48),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(levelName,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('${points.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} XP',
                      style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeago.format(createdAt, locale: 'en_short'),
            style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponBubble(
      Map<String, dynamic> msg, bool isMe, DateTime createdAt) {
    final meta = msg['metadata'] != null
        ? Map<String, dynamic>.from(msg['metadata'] as Map)
        : <String, dynamic>{};
    final offerTitle = meta['offer_title'] as String? ?? 'Coupon';
    final brandName = meta['brand_name'] as String? ?? 'Partner';
    final brandLogo = meta['brand_logo'] as String?;
    final promoCode = meta['promo_code'] as String? ?? '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMe
              ? [const Color(0xFF1E3A5F), const Color(0xFF2563EB)]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: Color(0xFFFCD34D), size: 16),
              const SizedBox(width: 6),
              Text('Gifted Coupon 🎁',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFFCD34D),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (brandLogo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(brandLogo,
                      width: 40, height: 40, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.store_rounded,
                          color: Colors.white54, size: 40)),
                )
              else
                const Icon(Icons.store_rounded,
                    color: Colors.white54, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offerTitle,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Text(brandName,
                        style: GoogleFonts.inter(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(promoCode,
                    style: GoogleFonts.robotoMono(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: promoCode));
                    HapticFeedback.lightImpact();
                  },
                  child: const Icon(Icons.copy_rounded,
                      color: Colors.white54, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timeago.format(createdAt, locale: 'en_short'),
            style:
                GoogleFonts.inter(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    final String text;
    if (checkDate == today) {
      text = 'Today';
    } else if (checkDate == yesterday) {
      text = 'Yesterday';
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text,
              style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
