import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  static const String _themeKey = 'isDarkMode';
  late SharedPreferences _prefs;

  final isDarkMode = false.obs;

  static const Color _seedColor = Color(0xFF005f9f);
  static const Color _appBarColor = Color(0xFF005f9f);

  Future<ThemeService> init() async {
    _prefs = await SharedPreferences.getInstance();
    await loadTheme();
    return this;
  }

  Future<void> saveTheme(bool darkMode) async {
    isDarkMode.value = darkMode;
    await _prefs.setBool(_themeKey, darkMode);
    Get.changeThemeMode(darkMode ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> loadTheme() async {
    isDarkMode.value = _prefs.getBool(_themeKey) ?? false;
  }

  ThemeData getLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: _appBarColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData getDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: _appBarColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}