import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> initialize() async {
    // 1. Request permissions for iOS and Web (auto-granted on Android).
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // 2. Fetch the FCM push token and save it to the current user
      final currentUserId = _firebaseService.currentUserId;
      if (currentUserId != null) {
        String? token = await _messaging.getToken();
        if (token != null) {
          await _firebaseService.updatePushToken(currentUserId, token);
        }

        // Listen for token refreshes
        _messaging.onTokenRefresh.listen((newToken) {
          _firebaseService.updatePushToken(currentUserId, newToken);
        });
      }

      // 3. Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          
          if (currentUserId != null) {
            // Save to internal firestore for history
            final notifModel = NotificationModel(
              notificationId: const Uuid().v4(),
              recipientId: currentUserId,
              title: message.notification!.title ?? 'New Notification',
              body: message.notification!.body ?? '',
              timestamp: DateTime.now(),
              dataPayload: message.data,
            );
            await _firebaseService.saveNotification(notifModel);
          }
        }
      });

      // 5. Handle tapping the notification (when app is in background or terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        _handleNotificationInteraction(message);
      });

      // Handle terminal state tap
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationInteraction(initialMessage);
      }
    } else {
      print('User declined or has not accepted permission');
    }
  }

  void _handleNotificationInteraction(RemoteMessage message) {
    if (message.data.containsKey('requestId')) {
      final requestId = message.data['requestId'];
      // Depending on your navigation setup, you will redirect the user to the Request Details Screen here.
      // Example: NavigationContext.navigatorKey.currentState.pushNamed('/request', arguments: requestId);
      print("User tapped notification relating to Request ID: $requestId");
    }
  }
}
