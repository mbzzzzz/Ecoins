import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';

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
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  late final String _conversationId;

  @override
  void initState() {
    super.initState();
    final friendId = widget.friend['id'] ?? widget.friend['friend']?['id'];
    if (friendId == null) {
      // Handle the error gracefully, perhaps by popping the screen after a frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Invalid Friend ID')));
         Navigator.pop(context);
      });
      _conversationId = ''; // Dummy assignment
      _messagesStream = const Stream.empty(); // Satisfy late initialization
      return; 
    }
    _conversationId = friendId;
    
    final myId = Supabase.instance.client.auth.currentUser!.id;

    // Stream messages
    _messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data.where((msg) {
           final sender = msg['sender_id'];
           final receiver = msg['receiver_id'];
           return (sender == myId && receiver == _conversationId) || 
                  (sender == _conversationId && receiver == myId);
        }).toList());

    if (widget.initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendMessage(widget.initialMessage!);
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final myId = Supabase.instance.client.auth.currentUser!.id;

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id': myId,
        'receiver_id': _conversationId,
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
      _controller.clear();
      // Scroll to bottom handled by StreamBuilder usually, or we can trigger it
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  Future<void> _clearChat() async {
     final myId = Supabase.instance.client.auth.currentUser!.id;
     // Delete messages for this conversation
     await Supabase.instance.client.from('messages').delete().or(
       'and(sender_id.eq.$myId,receiver_id.eq.$_conversationId),and(sender_id.eq.$_conversationId,receiver_id.eq.$myId)'
     );
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
    // Safety check for display name
    final friendNameRaw = widget.friend['display_name'] ?? 
                       widget.friend['friend']?['display_name'] ?? 
                       'Friend';
    final friendName = friendNameRaw.isEmpty ? 'Friend' : friendNameRaw;

    final avatarUrl = widget.friend['avatar_url'] ?? 
                      widget.friend['friend']?['avatar_url'];
    final myId = Supabase.instance.client.auth.currentUser?.id;

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
                  ? Text(friendName.isNotEmpty ? friendName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)) 
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () {
               showDialog(
                 context: context, 
                 builder: (ctx) => AlertDialog(
                   title: const Text('Clear Chat?'),
                   content: const Text('This will delete the conversation history permanently.'),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                     TextButton(onPressed: () {
                       _clearChat();
                       Navigator.pop(ctx);
                     }, child: const Text('Clear', style: TextStyle(color: Colors.red))),
                   ],
                 )
               );
            },
          )
        ],
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
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final messages = snapshot.data!;
                    
                    if (messages.isEmpty) {
                      return Center(child: Text('Start the conversation!', style: GoogleFonts.inter(color: Colors.white60)));
                    }

                    // Auto-scroll on new data
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                       if (_scrollController.hasClients && _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
                          _scrollToBottom();
                       }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender_id'] == myId;
                        
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
                                  msg['content'],
                                  style: GoogleFonts.inter(
                                    color: isMe ? Colors.white : AppTheme.textDark,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeago.format(DateTime.parse(msg['created_at']), locale: 'en_short'),
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
                    );
                  }
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
