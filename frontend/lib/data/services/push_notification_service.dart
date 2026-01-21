import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/data/services/notification_service.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationService _backendNotificationService;

  PushNotificationService(this._backendNotificationService);

  Future<void> initialize() async {
    // yêu cầu quyền thông báo
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');

      // lấy token và gửi lên backend
      try {
        String? token = await _fcm.getToken();
        if (token != null) {
          log('FCM Token: $token');
          await _backendNotificationService.registerDevice(token);
        }
      } catch (e) {
        log('Error getting/registering token: $e');
      }

      // listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        try {
          await _backendNotificationService.registerDevice(newToken);
        } catch (e) {
          log('Error refreshing token: $e');
        }
      });

      // khởi tạo local notifications cho foreground
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // xử lý khi click vào thông báo ở foreground
          log('Notification clicked: ${details.payload}');
        },
      );

      // handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Got a message whilst in the foreground!');
        log('Message data: ${message.data}');

        if (message.notification != null) {
          log('Message also contained a notification: ${message.notification}');
          _showLocalNotification(message);
        }
      });

      // handle background/terminated state click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('A new onMessageOpenedApp event was published!');
        // xử lý điều hướng ở đây nếu cần
      });
    } else {
      log('User declined or has not accepted permission');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'zen_channel_id',
          'Zen Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }
}
