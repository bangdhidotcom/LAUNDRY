import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';

import 'providers/app_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart'; // Pastikan ini mengarah ke file yang baru diperbaiki di langkah 3
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  try {
    await Firebase.initializeApp();
    
    await NotificationService().init();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        await NotificationService().init();
      }
    });

  } catch (e) {
    // Error handling silent
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'Laundry3B User',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          useMaterial3: true,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        ),
        home: isLoggedIn ? const MainScreen() : const AuthScreen(),
      ),
    );
  }
}