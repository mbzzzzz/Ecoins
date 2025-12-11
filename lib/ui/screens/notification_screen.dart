import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
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
      await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications yet.'))
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final note = _notifications[index];
                    final isRead = note['is_read'] as bool;
                    final created = DateTime.parse(note['created_at']);

                    return ListTile(
                      tileColor: isRead ? null : Colors.blue.withOpacity(0.05),
                      leading: Icon(
                        _getIcon(note['type']),
                        color: isRead ? Colors.grey : const Color(0xFF10B981),
                      ),
                      title: Text(
                        note['title'],
                        style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note['message']),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(created),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      onTap: () => _markAsRead(note['id']),
                    );
                  },
                ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'friend_request': return Icons.person_add;
      case 'challenge': return Icons.emoji_events;
      case 'reward': return Icons.card_giftcard;
      default: return Icons.notifications;
    }
  }
}
