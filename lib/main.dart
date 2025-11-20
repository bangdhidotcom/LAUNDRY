import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry3b1titik0/screens/splash_screen.dart';
import 'package:laundry3b1titik0/services/theme_service.dart';
import 'package:laundry3b1titik0/models/weather_model.dart';
import 'package:laundry3b1titik0/models/forecast_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  
  await Hive.initFlutter();
  Hive.registerAdapter(WeatherModelAdapter());
  Hive.registerAdapter(ForecastModelAdapter());
  Hive.registerAdapter(ForecastItemAdapter());

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await Get.putAsync(() => ThemeService().init());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = Get.find();

    return Obx(
      () => GetMaterialApp(
        title: 'Laundry 3B',
        theme: themeService.getLightTheme(),
        darkTheme: themeService.getDarkTheme(),
        themeMode: themeService.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
