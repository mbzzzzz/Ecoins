import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago_lib;
import 'package:animate_do/animate_do.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  void _subscribeToRealtime() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    _subscription = _supabase
        .channel('public:notifications:user_id=eq.${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id
          ),
          callback: (payload) {
             final newNote = payload.newRecord;
             if (mounted) {
               setState(() {
                 _notifications.insert(0, newNote);
               });
               ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New Notification: ${newNote['title']}'),
                    backgroundColor: AppTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                  )
               );
             }
          }
        )
        .subscribe();
  }

  Future<void> _fetchNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
          setState(() => _isLoading = false);
          return;
      }
      
      final userId = user.id;
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', id);
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      // Silent error
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Notifications', 
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
        ),
      ),
      body: Stack(
        children: [
           // Background
           Positioned.fill(
              child: Container(
                color: const Color(0xFF111827),
                child: Image.asset(
                  'assets/images/background.png',
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.5),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
           ),
           
           SafeArea(
             child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 60, color: Colors.white.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('No notifications yet', style: GoogleFonts.inter(color: Colors.white60))
                          ],
                        )
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final note = _notifications[index];
                          final isRead = note['is_read'] as bool;
                          final created = DateTime.parse(note['created_at']);
      
                          return FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: Duration(milliseconds: index * 50),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16),
                              opacity: isRead ? 0.1 : 0.25,
                              border: isRead ? null : Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                              child: InkWell(
                                onTap: () => _markAsRead(note['id']),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Container(
                                       padding: const EdgeInsets.all(10),
                                       decoration: BoxDecoration(
                                         color: isRead ? Colors.white.withOpacity(0.05) : AppTheme.primaryGreen.withOpacity(0.2),
                                         shape: BoxShape.circle
                                       ),
                                       child: Icon(
                                          _getIcon(note['type']),
                                          color: isRead ? Colors.white60 : AppTheme.primaryGreen,
                                          size: 20
                                       ),
                                     ),
                                     const SizedBox(width: 16),
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Row(
                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                             children: [
                                               Expanded(
                                                 child: Text(
                                                   note['title'],
                                                   style: GoogleFonts.outfit(
                                                       color: Colors.white,
                                                       fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                                       fontSize: 16
                                                   ),
                                                 ),
                                               ),
                                               if (!isRead)
                                                 Container(
                                                   width: 8, height: 8,
                                                   decoration: const BoxDecoration(
                                                     color: AppTheme.accentYellow,
                                                     shape: BoxShape.circle
                                                   ),
                                                 )
                                             ],
                                           ),
                                           const SizedBox(height: 4),
                                           Text(
                                             note['message'],
                                             style: GoogleFonts.inter(
                                               color: Colors.white70,
                                               fontSize: 13,
                                               height: 1.4
                                             )
                                           ),
                                           const SizedBox(height: 8),
                                           Text(
                                             timeago_lib.format(created),
                                             style: GoogleFonts.inter(
                                                 fontSize: 10, color: Colors.white30),
                                           ),
                                         ],
                                       ),
                                     )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
           )
        ],
      )
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'challenge':
        return Icons.emoji_events;
      case 'reward':
        return Icons.card_giftcard;
      default:
        return Icons.notifications;
    }
  }
}
