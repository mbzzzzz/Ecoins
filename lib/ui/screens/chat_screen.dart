import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> friend;
  final String? initialMessage;

  const ChatScreen({super.key, required this.friend, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Static memory storage for demo purposes (persists during app session)
  static final Map<String, List<Map<String, dynamic>>> _chatHistory = {};

  late String _conversationId;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    final friendId = widget.friend['id'] ?? widget.friend['friend']?['id'] ?? 'unknown';
    _conversationId = friendId;
    
    // Initialize history if empty
    if (!_chatHistory.containsKey(_conversationId)) {
      _chatHistory[_conversationId] = [];
    }
    
    _messages = _chatHistory[_conversationId]!;

    // Send initial message if provided (e.g. from share actions)
    if (widget.initialMessage != null) {
      // Add slightly delayed to allow UI to build
      Future.delayed(const Duration(milliseconds: 300), () {
        _sendMessage(widget.initialMessage!, isSystem: false);
      });
    }
  }

  void _sendMessage(String text, {bool isSystem = false}) {
    if (text.trim().isEmpty) return;

    setState(() {
      final newMessage = {
        'text': text,
        'isMe': true, 
        'timestamp': DateTime.now(),
        'isSystem': isSystem,
      };
      
      _messages.add(newMessage);
      _chatHistory[_conversationId] = _messages;
    });

    _controller.clear();
    _scrollToBottom();

    // Auto-reply simulation for "real feel"
    if (!isSystem) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
             _messages.add({
              'text': "That's awesome! thanks for sharing! 🌿",
              'isMe': false,
              'timestamp': DateTime.now(),
              'isSystem': false,
            });
             _scrollToBottom();
          });
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendName = widget.friend['display_name'] ?? 
                       widget.friend['friend']?['display_name'] ?? 
                       'Friend';
    final avatarUrl = widget.friend['avatar_url'] ?? 
                      widget.friend['friend']?['avatar_url'];

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
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null 
                  ? Text(friendName[0], style: const TextStyle(color: Colors.white)) 
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
                Text('Online',
                    style: GoogleFonts.inter(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: GlassContainer(opacity: 0.1, borderRadius: BorderRadius.zero, child: Container()),
        ),
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
          
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['isMe'] as bool;
                    final isSystem = msg['isSystem'] as bool;

                    if (isSystem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              msg['text'],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryGreen : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg['text'],
                              style: GoogleFonts.inter(
                                color: isMe ? Colors.white : AppTheme.textDark,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeago.format(msg['timestamp'], locale: 'en_short'),
                              style: GoogleFonts.inter(
                                color: isMe ? Colors.white70 : Colors.black45,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Input Area
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // SafeArea bottom padding
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (value) => _sendMessage(value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _sendMessage(_controller.text),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send, color: Colors.white, size: 20),
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
}
