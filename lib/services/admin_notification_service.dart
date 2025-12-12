// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Admin Background Notif: ${message.messageId}");
}

class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _firebaseMessaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // FOREGROUND HANDLER (Lokal Notif)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    String? token = await _firebaseMessaging.getToken();
    print("TOKEN ADMIN (Untuk Debug): $token");
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'admin_order_channel', 
            'Order Masuk',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('notification'),
          ),
        ),
      );
    }
  }

  // --- LOGIKA PENGIRIM KE USER (HTTP V1) ---
  
  Future<String> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString('assets/service_account.json');
      final serviceAccount = ServiceAccountCredentials.fromJson(jsonString);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(serviceAccount, scopes);
      return client.credentials.accessToken.data;
    } catch (e) {
      throw Exception("Gagal baca service_account.json: $e");
    }
  }

  Future<String> _getProjectId() async {
    final jsonString = await rootBundle.loadString('assets/service_account.json');
    final map = jsonDecode(jsonString);
    return map['project_id'];
  }

  Future<bool> sendNotificationToUser({
    required String userToken,
    required String title,
    required String body,
  }) async {
    try {
      final String accessToken = await _getAccessToken();
      final String projectId = await _getProjectId();
      final String endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': userToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'high_importance_channel',
            }
          }
        }
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Gagal kirim notif: $e");
      return false;
    }
  }
}