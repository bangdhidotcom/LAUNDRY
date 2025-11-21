// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:marquee/marquee.dart'; // Library Teks Berjalan
import 'package:laundry3b1titik0/controllers/delivery_controller.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeliveryController controller = Get.put(DeliveryController());
    
    // Controller untuk menggerakkan peta saat list diklik
    final MapController mapController = MapController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kurir'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => controller.refreshMapData()),
        ],
      ),
      body: Stack(
        children: [
          // 1. MAP LAYER
          Obx(() {
            if (controller.isMapLoading.value && controller.mapMarkers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: controller.centerLocation,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.laundry3b',
                ),
                MarkerLayer(markers: controller.mapMarkers.toList()),
              ],
            );
          }),

          // 2. WEATHER SMART BAR (ATAS)
          Positioned(
            top: 10, left: 10, right: 10,
            child: _buildWeatherBar(context, controller),
          ),

          // 3. LIST ANTRIAN (BOTTOM SHEET - DRAGGABLE)
          DraggableScrollableSheet(
            initialChildSize: 0.25, // Tinggi awal (25% layar)
            minChildSize: 0.15,     // Tinggi minimal saat digeser ke bawah
            maxChildSize: 0.6,      // Tinggi maksimal saat ditarik ke atas
            builder: (context, scrollController) {
              final isDark = Get.isDarkMode;
              final sheetColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
              final textColor = isDark ? Colors.white : Colors.black;

              return Container(
                decoration: BoxDecoration(
                  color: sheetColor, // <-- Warna Dinamis
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
                ),
                child: Obx(() {
                  final orders = controller.orders; // Pastikan controller punya list order ini
                  
                  return Column(
                    children: [
                      // Handle Bar (Garis kecil buat narik)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 10),
                          width: 40, height: 5,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      
                      // Judul List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Antrian Pengantaran (${orders.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Icon(Icons.list, color: Colors.blue),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // List Data
                      Expanded(
                        child: orders.isEmpty 
                        ? const Center(child: Text("Tidak ada pengantaran aktif"))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final data = orders[index];
                              final lat = data['latitude'] as double?;
                              final lng = data['longitude'] as double?;
                              final status = data['status'] as String;
                              final id = data['id'] as String?; // Pastikan ID diambil sebagai String (Supabase ID)

                              // Tentukan UI berdasarkan status
                              final isPickup = status == 'pickup';
                              final color = isPickup ? Colors.red : Colors.blue;
                              final statusText = isPickup ? "Jemput" : "Antar";
                              final buttonText = isPickup ? "Selesai Jemput" : "Selesai Antar";

                              return Card(
                                color: isDark ? Colors.grey[900] : Colors.white, // <-- Card Dinamis
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: color.withOpacity(0.2),
                                    child: Icon(
                                      isPickup ? Icons.location_on : Icons.local_shipping, 
                                      color: color // Warna ikon tetap (Merah/Biru) biar jelas fungsinya
                                    ),
                                  ),
                                  title: Text(
                                    data['customer_name'] ?? 'No Name', 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor) // <-- Teks Dinamis
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['address'] ?? '-', style: TextStyle(color: textColor.withOpacity(0.7))), // <-- Subtitle Dinamis
                                      Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Tombol Aksi Cepat (Ganti Status)
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                        tooltip: buttonText,
                                        onPressed: () {
                                          if (id != null) {
                                            // Panggil fungsi update status di controller
                                            controller.advanceOrderStatus(id, status);
                                          }
                                        },
                                      ),
                                      // Tombol Zoom Peta
                                      IconButton(
                                        icon: const Icon(Icons.map, color: Colors.grey),
                                        onPressed: () {
                                          if (lat != null && lng != null) {
                                            mapController.move(LatLng(lat, lng), 16.0);
                                          } else {
                                            Get.snackbar('Info', 'Order ini belum ada pin lokasinya');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherBar(BuildContext context, DeliveryController controller) {
    return Obx(() {
      final weather = controller.weatherData.value;
      final advice = controller.weatherAdvice.value;
      
      if (weather == null) return const SizedBox.shrink();

      // DETEKSI TEMA (Gelap/Terang)
      final isDark = Get.isDarkMode;

      // PALET WARNA DINAMIS
      final cardColor = isDark ? const Color(0xFF1E1E1E).withOpacity(0.95) : Colors.white.withOpacity(0.95);
      final iconBgColor = isDark ? Colors.grey[800] : Colors.blue[50];
      final textColor = isDark ? Colors.white : Colors.black87;
      final tempColor = isDark ? Colors.blue[200] : Colors.blue[800];
      
      // Warna Teks Marquee (Peringatan tetap Merah/Kuning biar waspada)
      final marqueeColor = advice.contains("HUJAN") 
          ? (isDark ? Colors.redAccent : Colors.red[800]) 
          : (isDark ? Colors.blueAccent : Colors.blue[900]);

      return Card(
        elevation: 6,
        // Tambahkan border tipis di mode gelap agar batasnya jelas
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: isDark ? BorderSide(color: Colors.grey[700]!, width: 0.5) : BorderSide.none,
        ),
        color: cardColor, 
        child: Container(
          height: 55, // Sedikit lebih tinggi biar lega
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // 1. IKON CUACA (Kontras Tinggi)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor, 
                  shape: BoxShape.circle,
                  // Efek bayangan tipis
                  boxShadow: [
                    if (!isDark) 
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Image.network(
                  weather.getIconUrl(),
                  width: 32, height: 32,
                  errorBuilder: (_,__,___) => Icon(Icons.cloud_off, size: 20, color: textColor),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 2. SUHU & KOTA
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.toStringAsFixed(0)}°C',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: tempColor),
                  ),
                  Text(
                    weather.cityName,
                    style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6)),
                  ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // 3. GARIS PEMBATAS
              Container(width: 1, height: 30, color: textColor.withOpacity(0.2)),
              
              const SizedBox(width: 12),
              
              // 4. TEKS BERJALAN (Marquee)
              Expanded(
                child: SizedBox(
                  height: 20,
                  child: Marquee(
                    text: "$advice  |  INFO: ${controller.customMarquee.value}      ",
                    style: TextStyle(
                      color: marqueeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    blankSpace: 20.0,
                    velocity: 30.0,
                    pauseAfterRound: const Duration(seconds: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}