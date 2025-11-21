// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart'; // Wajib ada untuk Peta
import 'package:flutter_map/flutter_map.dart'; // Wajib ada untuk Marker
import 'package:laundry3b1titik0/models/weather_model.dart';
import 'package:laundry3b1titik0/models/forecast_model.dart';
import 'package:laundry3b1titik0/services/supabase_service.dart';

class DeliveryController extends GetxController {
  // --- SERVICE ---
  final _supabaseService = SupabaseService();
  final Dio _dio = Dio();

  // --- STATE CUACA ---
  var weatherData = Rx<WeatherModel?>(null);
  var forecastList = <ForecastItem>[].obs;
  var weatherAdvice = ''.obs;
  var isWeatherLoading = true.obs;

  // --- STATE PETA & KURIR ---
  var mapMarkers = <Marker>[].obs;
  var couriers = <Map<String, dynamic>>[].obs;
  var orders = <Map<String, dynamic>>[].obs; // Order yg perlu pickup/delivery
  var isMapLoading = true.obs;
  
  // Posisi Default (Malang Kota) - Sesuaikan dengan kota Anda
  final LatLng centerLocation = const LatLng(-7.9666, 112.6326);

  // --- KONFIGURASI API CUACA ---
  final String _apiKey = '70497336d3d17d0f79edd66a0b679ff4';
  final String _cityName = 'Malang';

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // 1. Load Cuaca (Hive Cache + API)
    await _loadWeather();
    
    // 2. Load Data Peta (Supabase)
    await refreshMapData();
  }

  var customMarquee = ''.obs;

  Future<void> refreshMapData() async {
    isMapLoading.value = true;
    try {
      // 1. Ambil data Kurir & Data Order Logistik (Pickup + Delivery)
      final courierData = await _supabaseService.getCouriers();
      final activeOrders = await _supabaseService.getActiveLogisticsOrders();
      
      final configText = await _supabaseService.getConfigValue('marquee_text');
      if (configText.isNotEmpty) {
        customMarquee.value = configText;
      }

      // Update List untuk Bottom Sheet
      orders.value = activeOrders.map((e) => e.toMap()).toList();
      
      mapMarkers.clear();

      // A. MARKER OUTLET (Pusat) - Ikon Toko
      // (Nanti idealnya ambil dari tabel outlet, tapi sementara pakai centerLocation dulu gapapa)
      mapMarkers.add(
        Marker(
          point: centerLocation,
          width: 80, height: 80,
          child: const Column(
            children: [
              Icon(Icons.store, color: Colors.indigo, size: 40),
              Text('Pusat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
        ),
      );

      // B. MARKER ORDER (Merah = Pickup, Biru = Delivery)
      for (var order in activeOrders) {
        if (order.latitude != null && order.longitude != null) {
          // Tentukan Warna & Ikon berdasarkan Status
          final isPickup = order.status == 'pickup';
          final markerColor = isPickup ? Colors.red : Colors.blue;
          final markerIcon = isPickup ? Icons.location_on : Icons.local_shipping;
          final label = isPickup ? "Jemput" : "Antar";

          mapMarkers.add(
            Marker(
              point: LatLng(order.latitude!, order.longitude!),
              width: 80, height: 80,
              child: GestureDetector(
                onTap: () {
                  Get.snackbar(
                    '$label: ${order.customerName}', 
                    'Alamat: ${order.address}\nStatus: ${order.status.toUpperCase()}',
                    backgroundColor: Colors.white,
                    icon: Icon(markerIcon, color: markerColor),
                    duration: const Duration(seconds: 4),
                  );
                },
                child: Column(
                  children: [
                    Icon(markerIcon, color: markerColor, size: 40),
                    // Label kecil di bawah marker
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: markerColor),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: markerColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }

      // C. MARKER KURIR (Hijau)
      for (var c in courierData) {
        if (c['current_lat'] != null && c['current_lng'] != null) {
          mapMarkers.add(
            Marker(
              point: LatLng(c['current_lat'], c['current_lng']),
              width: 80, height: 80,
              child: const Column(
                children: [
                  Icon(Icons.motorcycle, color: Colors.green, size: 35),
                ],
              ),
            ),
          );
        }
      }

    } catch (e) {
      print('Error loading map data: $e');
    } finally {
      isMapLoading.value = false;
    }
  }
  
  // Fungsi Eksekusi Status (Dipanggil dari UI nanti)
  Future<void> advanceOrderStatus(String orderId, String currentStatus) async {
    String nextStatus = '';
    String message = '';

    // Logika Perubahan Status
    if (currentStatus == 'pickup') {
      nextStatus = 'process'; // Masuk pencucian -> Hilang dari peta
      message = 'Cucian diterima di outlet. Masuk proses cuci.';
    } else if (currentStatus == 'delivery') {
      nextStatus = 'done'; // Selesai -> Hilang dari peta
      message = 'Pesanan selesai diantar!';
    } else {
      return; // Status lain tidak diurus di halaman map
    }

    try {
      await _supabaseService.updateOrderStatus(orderId, nextStatus);
      await refreshMapData(); // Refresh peta biar markernya hilang
      Get.snackbar('Sukses', message, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Gagal update status: $e');
    }
  }

  // ==================== BAGIAN CUACA (Yg Lama, Disederhanakan) ====================

  Future<void> _loadWeather() async {
    isWeatherLoading.value = true;
    try {
      var box = await Hive.openBox<WeatherModel>('weather');
      if (box.isNotEmpty) {
        weatherData.value = box.getAt(0);
        _updateAdvice();
      }

      final response = await _dio.get(
          'https://api.openweathermap.org/data/2.5/weather?q=$_cityName&appid=$_apiKey&units=metric&lang=id');
      
      final newWeather = WeatherModel.fromJson(response.data);
      weatherData.value = newWeather;
      
      await box.clear();
      await box.add(newWeather);
      _updateAdvice();

    } catch (e) {
      print('Weather load error: $e');
    } finally {
      isWeatherLoading.value = false;
    }
  }

  void _updateAdvice() {
    if (weatherData.value == null) return;
    String desc = weatherData.value!.description.toLowerCase();
    
    if (desc.contains('hujan')) {
      weatherAdvice.value = "⚠️ HUJAN: Siapkan jas hujan & plastik pelindung!";
    } else if (desc.contains('mendung') || desc.contains('awan')) {
      weatherAdvice.value = "⛅ MENDUNG: Waspada potensi hujan, cek rute aman.";
    } else {
      weatherAdvice.value = "✅ CERAH: Kondisi aman untuk pengiriman cepat.";
    }
  }
}