// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Notifikasi Background: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // GANTI ICON DISINI: gunakan 'logo_notif'
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('logo_notif');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print("Notifikasi Lokal diklik: ${details.payload}");
      },
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Pesan diterima saat Foreground: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    String? token = await _firebaseMessaging.getToken();
    print("FCM TOKEN SAYA: $token");
    
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
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
            'high_importance_channel',
            'Penting',
            channelDescription: 'Notifikasi penting status laundry',
            importance: Importance.max,
            priority: Priority.high,
            // GANTI ICON DISINI JUGA
            icon: 'logo_notif',
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('customers')
          .update({'fcm_token': token})
          .eq('auth_id', userId);
          
      print("Token FCM berhasil disimpan ke Database!");
    } catch (e) {
      print("Gagal simpan token: $e");
    }
  }
}