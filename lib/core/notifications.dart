import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId} - ${message.notification?.title}');
}

abstract interface class NotificationService {
  Future<void> initialize();
  Future<void> subscribeToSection(String sectionId);
  Future<void> unsubscribeFromSection(String sectionId);
  Future<String?> getToken();
  Stream<RemoteMessage> get onMessage;
  Stream<Map<String, dynamic>> get onNotificationTapped;
}

class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _tapStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<RemoteMessage> get onMessage => _messageStreamController.stream;

  @override
  Stream<Map<String, dynamic>> get onNotificationTapped => _tapStreamController.stream;

  @override
  Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM Authorization status: ${settings.authorizationStatus}');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message received: ${message.notification?.title} - ${message.notification?.body}');
        _messageStreamController.add(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification clicked while in background: ${message.data}');
        _tapStreamController.add(message.data);
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from terminated state via notification: ${initialMessage.data}');
        _tapStreamController.add(initialMessage.data);
      }
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }
  }

  @override
  Future<void> subscribeToSection(String sectionId) async {
    try {
      final topic = _sanitizeTopic('section_$sectionId');
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to section topic: $e');
    }
  }

  @override
  Future<void> unsubscribeFromSection(String sectionId) async {
    try {
      final topic = _sanitizeTopic('section_$sectionId');
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from section topic: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  String _sanitizeTopic(String name) {
    // FCM topics must match regex: [a-zA-Z0-9-_.~%]+
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
  }

  void dispose() {
    _messageStreamController.close();
    _tapStreamController.close();
  }
}

class MockNotificationService implements NotificationService {
  final StreamController<RemoteMessage> _controller =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _tapController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<RemoteMessage> get onMessage => _controller.stream;

  @override
  Stream<Map<String, dynamic>> get onNotificationTapped => _tapController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> subscribeToSection(String sectionId) async {}

  @override
  Future<void> unsubscribeFromSection(String sectionId) async {}

  @override
  Future<String?> getToken() async => 'mock-fcm-token';

  void dispose() {
    _controller.close();
    _tapController.close();
  }
}
