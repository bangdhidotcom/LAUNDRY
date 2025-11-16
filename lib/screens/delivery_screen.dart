// [GANTI SELURUH ISI FILE lib/screens/delivery_screen.dart]

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry3b1titik0/controllers/delivery_controller.dart';
import 'package:laundry3b1titik0/models/weather_model.dart'; // Import WeatherModel

class DeliveryScreen extends GetView<DeliveryController> {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Panggil Get.put() di sini agar controller diinisialisasi
    // saat halaman ini dibuka
    final DeliveryController controller = Get.put(DeliveryController());
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kurir & Cuaca'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // --- WIDGET STATUS BARU ---
            Obx(() {
              final isOnline = controller.isOnline.value;
              final statusText = controller.networkStatus.value;
              final icon = isOnline ? Icons.wifi : Icons.wifi_off_rounded;
              final color = isOnline ? Colors.green : Colors.grey[600];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color?.withOpacity(0.3) ?? Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            // --- AKHIR WIDGET STATUS ---

            const SizedBox(height: 24),

            // --- TAMPILAN UTAMA ---
            Obx(() {
              if (controller.isLoading.value && controller.weatherData.value == null) {
                // Tampilkan loading HANYA jika cache juga kosong
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.weatherData.value == null) {
                // Jika tidak loading dan data masih null (error & cache kosong)
                return Center(
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: colorScheme.error, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // Jika kita punya data (entah dari cache atau API)
              final weather = controller.weatherData.value!;
              final advice = controller.getWeatherAdvice(weather);

              return Column(
                children: [
                  // Tampilkan pesan error jika ada (saat gagal refresh)
                  if (controller.errorMessage.isNotEmpty && !controller.isOnline.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  
                  // Card Utama
                  _buildWeatherCard(context, weather, advice),
                ],
              );
              
            }),
          ],
        ),
      ),
    );
  }

  // Widget terpisah untuk card cuaca
  Widget _buildWeatherCard(BuildContext context, WeatherModel weather, String advice) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuaca Saat Ini: ${weather.cityName}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Image.network(
                    weather.getIconUrl(),
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.cloud_off,
                      size: 30,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weather.description.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
                        style: textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              'Rekomendasi Operasional:',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 8),
            Text(advice, style: textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}