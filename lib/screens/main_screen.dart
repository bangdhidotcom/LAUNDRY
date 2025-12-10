import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/main_screen.dart'; // <--- Import file baru

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Debugging: Cek apakah env terbaca
  try {
    await dotenv.load(fileName: ".env");
    print("Env loaded. URL: ${dotenv.env['SUPABASE_URL']}"); // Cek di Debug Console
  } catch (e) {
    print("Gagal load .env: $e");
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cek session aman
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
          textTheme: GoogleFonts.interTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        ),
        home: isLoggedIn ? const MainScreen() : const AuthScreen(),
      ),
    );
  }
}