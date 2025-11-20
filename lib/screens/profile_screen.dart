import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry3b1titik0/services/theme_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Admin'),
      ),
      body: Obx(
        () => ListView(
          children: [
            SwitchListTile(
              title: const Text('Mode Gelap'),
              subtitle: const Text('Aktifkan tema gelap'),
              value: themeService.isDarkMode.value,
              onChanged: (value) {
                themeService.saveTheme(value);
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Panel untuk mengelola data outlet, laporan keuangan, dan akun staf.',
                style: TextStyle(fontSize: 18, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
