import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry3b1titik0/controllers/delivery_controller.dart';

class DeliveryScreen extends GetView<DeliveryController> {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeliveryController controller = Get.put(DeliveryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kurir & Cuaca'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Analisis Risiko Operasional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => controller.checkOperationalImpact(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Cek Dampak (Cuaca + Berita)',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            const Text(
              'Cek Cepat (Cuaca Saja)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.fetchWeatherHttp(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cek (HTTP)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.fetchWeatherDio(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cek (Dio)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.isNotEmpty) {
                return Center(
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (controller.operationalWarning.isNotEmpty) {
                final String warningText = controller.operationalWarning.value;
                final bool isWarning = warningText.startsWith('PERINGATAN');

                return Card(
                  elevation: 4,
                  color: isWarning ? Colors.red[50] : Colors.green[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isWarning ? Colors.red : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWarning
                              ? 'PERINGATAN OPERASIONAL'
                              : 'INFO OPERASIONAL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isWarning
                                ? Colors.red[800]
                                : Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(warningText, style: const TextStyle(fontSize: 16)),
                        if (controller.fetchTimeChain.value.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Waktu Respon (Rantai): ${controller.fetchTimeChain.value}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              if (controller.weatherData.value != null) {
                final weather = controller.weatherData.value!;
                final advice = controller.getWeatherAdvice(weather);
                final timeHttp = controller.fetchTimeHttp.value;
                final timeDio = controller.fetchTimeDio.value;
                String fetchTimeText = '';
                if (timeHttp.isNotEmpty) {
                  fetchTimeText = 'Waktu Respon (HTTP): $timeHttp';
                } else if (timeDio.isNotEmpty) {
                  fetchTimeText = 'Waktu Respon (Dio): $timeDio';
                }

                return Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Cuaca: ${weather.cityName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color.fromARGB(
                                255,
                                150,
                                157,
                                255,
                              ),
                              child: Image.network(
                                weather.getIconUrl(),
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.cloud_off,
                                      size: 30,
                                      color: Colors.grey[700],
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${weather.description.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')} (${weather.temperature.toStringAsFixed(1)}°C)',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rekomendasi Operasional:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(advice),
                        const SizedBox(height: 10),
                        if (fetchTimeText.isNotEmpty)
                          Text(
                            fetchTimeText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }
              return const Center(
                child: Text(
                  'Tekan tombol di atas untuk menganalisis kondisi operasional.',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
