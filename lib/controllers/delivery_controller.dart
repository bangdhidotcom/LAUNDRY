// [GANTI SELURUH ISI FILE lib/controllers/delivery_controller.dart]

import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:laundry3b1titik0/models/weather_model.dart';
import 'package:laundry3b1titik0/models/forecast_model.dart';

class DeliveryController extends GetxController {
  // --- Variabel State Utama ---
  var isLoading = true.obs;
  var weatherData = Rx<WeatherModel?>(null);
  var forecastList = <ForecastItem>[].obs;
  var errorMessage = ''.obs;

  // --- Variabel Status Baru ---
  var networkStatus = "Menginisialisasi...".obs;
  var isOnline = false.obs;

  // --- Konfigurasi ---
  final String _apiKey = '70497336d3d17d0f79edd66a0b679ff4';
  final String _cityName = 'Malang';
  late String _apiUrl;
  late String _forecastApiUrl;

  final Dio _dio = Dio();
  late Box<WeatherModel> _weatherBox;
  late Box<ForecastItem> _forecastBox;

  @override
  void onInit() {
    super.onInit();
    _apiUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$_cityName&appid=$_apiKey&units=metric&lang=id';
    _forecastApiUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=$_cityName&appid=$_apiKey&units=metric&lang=id';
    
    // Panggil fungsi master secara otomatis
    _initializeAndLoadWeather();
  }

  Future<void> _initializeAndLoadWeather() async {
    await _initializeHiveBoxes();
    await _loadWeather();
  }

  Future<void> _initializeHiveBoxes() async {
    _weatherBox = await Hive.openBox<WeatherModel>('weather');
    _forecastBox = await Hive.openBox<ForecastItem>('forecast');
    // ignore: avoid_print
    print('Hive boxes initialized');
  }

  // --- FUNGSI MASTER BARU ---
  Future<void> _loadWeather() async {
    isLoading.value = true;
    errorMessage.value = '';
    networkStatus.value = "Memuat data cache...";
    isOnline.value = false;

    // LANGKAH A: Muat dari Cache (Offline-First)
    _loadCachedData();
    if (weatherData.value != null) {
      networkStatus.value = "Offline | Menampilkan data cache";
    } else {
      networkStatus.value = "Offline | Cache kosong";
    }

    // LANGKAH B: Coba Ambil dari API (Cek Online)
    try {
      networkStatus.value = "Menghubungi server...";
      
      // Ambil data cuaca baru
      final weatherResponse = await _dio.get(_apiUrl);
      final newWeather = WeatherModel.fromJson(weatherResponse.data);
      
      // Ambil data perkiraan cuaca baru
      final forecastResponse = await _dio.get(_forecastApiUrl);
      final newForecastList = ForecastModel.fromJson(forecastResponse.data).list;

      // Jika BERHASIL (Online)
      isOnline.value = true;
      networkStatus.value = "Online | Data berhasil diperbarui";
      
      // Update UI
      weatherData.value = newWeather;
      forecastList.value = newForecastList;

      // Simpan data baru ke Hive
      await _saveCachedData(newWeather, newForecastList);

    } catch (e) {
      // Jika GAGAL (Offline)
      isOnline.value = false;
      if (weatherData.value != null) {
        // Jika ada data cache, ini bukan error, hanya info
        networkStatus.value = "Offline | Menampilkan data cache terakhir";
        errorMessage.value = "Koneksi gagal. Menampilkan data offline.";
      } else {
        // Jika tidak ada data cache, ini baru error
        networkStatus.value = "Offline | Gagal memuat data";
        errorMessage.value = "Koneksi gagal dan tidak ada data cache.";
      }
      // ignore: avoid_print
      print('Gagal mengambil data API: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void _loadCachedData() {
    if (_weatherBox.isNotEmpty) {
      final stopwatch = Stopwatch()..start();
      weatherData.value = _weatherBox.getAt(0);
      print('Loaded cached weather data: ${weatherData.value?.cityName}');
      stopwatch.stop();
      print('===== LAPORAN KECEPATAN (BACA) =====');
      print('Baca Hive (1 data cuaca): ${stopwatch.elapsedMicroseconds} microseconds');
      print('====================================');
    }
    if (_forecastBox.isNotEmpty) {
      forecastList.clear();
      forecastList.addAll(_forecastBox.values);
      print('Loaded ${forecastList.length} cached forecast items');
    }
  }

  Future<void> _saveCachedData(
    WeatherModel weather,
    List<ForecastItem> forecasts,
  ) async {
    await _weatherBox.clear();

    final stopwatch = Stopwatch()..start();
    await _weatherBox.add(weather);
    stopwatch.stop();
    print('===== LAPORAN KECEPATAN (TULIS) =====');
    print('Tulis Hive (1 data cuaca): ${stopwatch.elapsedMicroseconds} microseconds');
    print('=====================================');

    await _forecastBox.clear();
    await _forecastBox.addAll(forecasts); // Gunakan addAll untuk efisiensi
    
    print('Data baru berhasil disimpan ke Hive cache');
  }

  // Fungsi getWeatherAdvice tetap sama (tidak perlu diubah)
  String getWeatherAdvice(WeatherModel weather) {
    String description = weather.description.toLowerCase();
    final now = DateTime.now();

    if (description.contains('hujan') || description.contains('gerimis')) {
      return 'REKOMENDASI (Hujan Sekarang): Sedang hujan! Ingatkan kurir bawa jas hujan & perlengkapan anti-air. Prioritaskan pickup di zona rawan macet.';
    }
    if (description.contains('cerah')) {
      return 'INFO (Cerah): Kondisi ideal. Operasional kurir dan penjemuran (jika ada) berjalan normal.';
    }

    if (description.contains('awan') || description.contains('mendung')) {
      if (forecastList.isEmpty) {
        return 'INFO (Mendung): Cuaca saat ini mendung. Belum bisa memuat data perkiraan cuaca.';
      }

      final upcomingForecastsToday = forecastList
          .where(
            (item) =>
                item.dateTime.isAfter(now) && item.dateTime.day == now.day,
          )
          .toList();

      if (upcomingForecastsToday.isEmpty) {
        return 'INFO (Mendung): Cuaca mendung. Sisa hari ini aman (tidak ada perkiraan hujan).';
      }

      final firstRainEvent =
          upcomingForecastsToday.cast<ForecastItem?>().firstWhere(
                (item) =>
                    item != null &&
                    (item.description.contains('hujan') ||
                        item.description.contains('gerimis')),
                orElse: () => null,
              )
              as ForecastItem?;

      if (firstRainEvent == null) {
        return 'INFO (Mendung): Cuaca mendung, namun perkiraan cuaca sisa hari ini **AMAN** (tidak ada tanda hujan). Operasional normal.';
      } else {
        final rainStartTime = firstRainEvent.dateTime;
        final rainTimeStr = '${rainStartTime.hour}:00';

        final clearWeatherAfterRain =
            forecastList.cast<ForecastItem?>().firstWhere(
                  (item) =>
                      item != null &&
                      item.dateTime.isAfter(rainStartTime) &&
                      !(item.description.contains('hujan') ||
                          item.description.contains('gerimis')),
                  orElse: () => null,
                )
                as ForecastItem?;

        if (clearWeatherAfterRain != null) {
          final clearTimeStr = '${clearWeatherAfterRain.dateTime.hour}:00';
          return 'WASPADA (Mendung): Ada potensi hujan hari ini sekitar jam $rainTimeStr. \nREKOMENDASI: Selesaikan pickup sebelum jam itu. \nINFO: Hujan diperkirakan akan reda sekitar jam $clearTimeStr.';
        } else {
          return 'WASPADA (Mendung): Ada potensi hujan hari ini sekitar jam $rainTimeStr dan diperkirakan berlangsung lama. \nREKOMENDASI: Selesaikan semua pickup SEBELUM jam $rainTimeStr.';
        }
      }
    }

    if (description.contains('kabut') || description.contains('asap')) {
      return 'INFO (Berkabut): Jarak pandang kurir mungkin terbatas. Ingatkan tim untuk hati-hati di jalan.';
    }

    return 'Data cuaca diterima: $description. Belum ada rekomendasi khusus.';
  }
}