import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );
     // Request permissions for Android 13+
     _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showLocalNotification(
      {required int id,
      required String title,
      required String body,
      String? payload}) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'eco_rewards_channel',
      'Eco Rewards Notifications',
      channelDescription: 'Notifications for achievements and social updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentSound: true),
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  // Hook into Supabase Realtime for messages/notifications
  void listenToUserNotifications(String userId) {
    Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final latest = data.first;
            // Basic dup check by timestamp or ID could be added here
            showLocalNotification(
              id: latest['id'].hashCode,
              title: latest['title'] ?? 'New Notification',
              body: latest['body'] ?? '',
              payload: 'notification_screen'
            );
          }
        });
        
    // Also listen for new messages to trigger system notification
    Supabase.instance.client
         .from('messages') // Assuming a messages table exists or will exist
         .stream(primaryKey: ['id'])
         .eq('receiver_id', userId) 
         .listen((data) {
             if(data.isNotEmpty) {
                 final msg = data.first;
                 showLocalNotification(
                     id: msg['id'].hashCode,
                     title: 'New Message',
                     body: msg['content'] ?? 'You have a new message',
                     payload: 'chat/${msg['sender_id']}'
                 );
             }
         });
  }
}
