// ignore_for_file: avoid_print, unnecessary_const

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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
        AndroidInitializationSettings('logo_notif');
        
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Update Token Admin di Tabel 'admins' (BUKAN CUSTOMERS)
    try {
      String? token = await _firebaseMessaging.getToken();
      final user = Supabase.instance.client.auth.currentUser;
      if (token != null && user != null) {
        // Kita gunakan upsert agar aman
        await Supabase.instance.client.from('admins').upsert({
          'id': user.id,
          'fcm_token': token,
          // Pastikan email ada agar tidak error constraint jika insert baru
          'email': user.email, 
        });
        print("TOKEN ADMIN Updated di Database");
      }
    } catch (e) {
      print("Gagal update token admin: $e");
    }
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
            icon: 'logo_notif',
            importance: Importance.max,
            priority: Priority.high,
            color: const Color(0xFF005f9f),
            sound: RawResourceAndroidNotificationSound('notification'),
          ),
        ),
      );
    }
  }

  // --- LOGIKA PENGIRIM KE USER (DENGAN SAFEGUARD) ---
  
  Future<String> _getAccessToken() async {
    final jsonString = await rootBundle.loadString('assets/service_account.json');
    final serviceAccount = ServiceAccountCredentials.fromJson(jsonString);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(serviceAccount, scopes);
    return client.credentials.accessToken.data;
  }

  Future<String> _getProjectId() async {
    final jsonString = await rootBundle.loadString('assets/service_account.json');
    final map = jsonDecode(jsonString);
    return map['project_id'];
  }

  /// Fungsi Utama untuk mengirim notifikasi status order
  /// Aman dari CRASH (Layar Merah)
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      print("---- MEMULAI PENGIRIMAN NOTIFIKASI KE USER ----");
      
      // 1. Ambil Token User dari Tabel Customers
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('customers')
          .select('fcm_token')
          .eq('auth_id', userId)
          .maybeSingle();

      if (response == null || response['fcm_token'] == null) {
        print("WARNING: Token User tidak ditemukan. Notifikasi skip.");
        return; 
      }

      String userToken = response['fcm_token'];

      // 2. Persiapan Kirim ke FCM
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

      // 3. Eksekusi Request
      final httpResponse = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (httpResponse.statusCode == 200) {
        print("SUKSES: Notifikasi terkirim ke user.");
      } else {
        print("GAGAL FCM: ${httpResponse.body}");
      }

    } catch (e) {
      // INI PENYELAMAT: Tangkap semua error agar aplikasi Admin tidak crash
      print("ERROR HANDLED (Safe): Gagal mengirim notifikasi -> $e");
    }
  }
}