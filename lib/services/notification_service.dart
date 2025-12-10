import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Handler untuk notifikasi saat aplikasi dimatikan (Terminated)
// Harus di luar class (Top Level Function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Notifikasi Background: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Setup Awal
  Future<void> init() async {
    // 1. Minta Izin Notifikasi (Wajib untuk Android 13+)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup Local Notification (Untuk Foreground)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Settingan iOS (Jika nanti butuh)
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle jika notifikasi lokal diklik
        print("Notifikasi Lokal diklik: ${details.payload}");
      },
    );

    // 3. Setup Handler Firebase
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Saat aplikasi dibuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Pesan diterima saat Foreground: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // 4. Dapatkan Token FCM & Simpan ke Supabase
    String? token = await _firebaseMessaging.getToken();
    print("FCM TOKEN SAYA: $token"); // <-- Cek ini di Debug Console nanti!
    
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Listener jika token berubah (Refresh)
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  // Menampilkan Notifikasi Lokal (Pop-up)
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
            'high_importance_channel', // Id Channel
            'Penting', // Nama Channel
            channelDescription: 'Notifikasi penting status laundry',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  // Simpan Token ke Tabel Profile User di Supabase
  Future<void> _saveTokenToDatabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Kita asumsikan ada kolom 'fcm_token' di tabel customers
      // Kita update berdasarkan auth_id
      await Supabase.instance.client
          .from('customers')
          .update({'fcm_token': token}) // <--- Nanti kita buat kolom ini
          .eq('auth_id', userId);
          
      print("Token FCM berhasil disimpan ke Database!");
    } catch (e) {
      print("Gagal simpan token: $e");
    }
  }
}