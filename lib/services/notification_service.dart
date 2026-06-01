import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/config/routes.dart';
import 'package:uniswap/services/firestore_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    // Background handler needs to be a top-level function.
    debugPrint('Background message: ${message.messageId}');
  }
}

class NotificationService {
  NotificationService(this._messaging, this._localNotifications, this._auth, this._firestoreService);

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  StreamSubscription<String>? _tokenSubscription;

  Future<void> initialize() async {
    await _requestPermissions();
    await _initLocalNotifications();
    await _syncFcmToken();
    _listenForMessages();
  }

  Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (_) {
      // Permission blocked on web should not crash the app.
    }
  }

  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route == null || route.isEmpty) return;
        _navigate(route);
      },
    );
  }

  Future<void> _syncFcmToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestoreService.updateFcmToken(userId: user.uid, token: token);
      }

      _tokenSubscription?.cancel();
      _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
        _firestoreService.updateFcmToken(userId: user.uid, token: token);
      });
    } catch (_) {
      // Permission blocked or unsupported environment.
    }
  }

  void _listenForMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNavigation(message);
    });

    _messaging.getInitialMessage().then((message) {
      if (message != null) _handleNavigation(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'uniswap_messages',
      'Messages',
      channelDescription: 'Incoming chat and swap updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['route'] as String?,
    );
  }

  void _handleNavigation(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route == null || route.isEmpty) return;
    _navigate(route);
  }

  void _navigate(String route) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    GoRouter.of(context).go(route);
  }

  void dispose() {
    _tokenSubscription?.cancel();
  }
}
