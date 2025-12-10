// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/user_service.dart';
import '../services/weather_service.dart';

class TrackingScreen extends StatefulWidget {
  final Order order;
  const TrackingScreen({super.key, required this.order});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final UserService _userService = UserService();
  final WeatherService _weatherService = WeatherService();
  final MapController _mapController = MapController();

  // ignore: unused_field
  Map<String, dynamic>? _weatherData;
  bool _isBadWeather = false;

  @override
  void initState() {
    super.initState();
    _checkWeather();
  }

  Future<void> _checkWeather() async {
    final data = await _weatherService.getCurrentWeather();
    if (mounted && data.isNotEmpty) {
      setState(() {
        _weatherData = data;
        if (data['weather'] != null && data['weather'].isNotEmpty) {
          final id = data['weather'][0]['id'] as int;
          _isBadWeather = (id >= 200 && id <= 531);
        }
      });
    }
  }

  int _getCurrentStep(String status) {
    if (status == 'pending') return 0;
    if (status == 'pickup') return 1;
    if (status == 'process' || status == 'washing' || status == 'ironing') return 2;
    if (status == 'delivery') return 3;
    if (status == 'completed') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final userLat = widget.order.latitude ?? -7.9666;
    final userLng = widget.order.longitude ?? 112.6326;
    final userPos = LatLng(userLat, userLng);

    final bool hasCourier = widget.order.courierId != null;
    
    final bool isTrackingActive = 
        (widget.order.status == 'pickup' || widget.order.status == 'delivery') && hasCourier;

    return Scaffold(
      appBar: AppBar(
        title: Text("Lacak Order #${widget.order.id?.substring(0, 5) ?? ''}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                StreamBuilder<Map<String, dynamic>?>(
                  stream: isTrackingActive 
                      ? _userService.streamCourierLocation(widget.order.courierId!)
                      : Stream.value(null),
                  builder: (context, snapshot) {
                    LatLng? courierPos;
                    if (snapshot.hasData && snapshot.data != null) {
                      final lat = snapshot.data!['current_lat'];
                      final lng = snapshot.data!['current_lng'];
                      if (lat != null && lng != null) {
                        courierPos = LatLng(lat, lng);
                      }
                    }

                    return FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: userPos,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.laundry3b.user',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: userPos,
                              width: 50,
                              height: 50,
                              child: const Icon(LucideIcons.home, color: Colors.blue, size: 40),
                            ),
                            if (courierPos != null)
                              Marker(
                                point: courierPos,
                                width: 50,
                                height: 50,
                                child: const Icon(LucideIcons.bike, color: Colors.orange, size: 40),
                              ),
                          ],
                        ),
                        if (courierPos != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [userPos, courierPos],
                                strokeWidth: 3,
                                color: Colors.blueAccent,
                                isDotted: true,
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
                
                if (_isBadWeather)
                  Positioned(
                    top: 10, left: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.cloudRain, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(child: Text("Cuaca buruk terdeteksi. Pengantaran mungkin terlambat.", style: TextStyle(color: Colors.white, fontSize: 12))),
                        ],
                      ),
                    ),
                  ),
                  
                if (!hasCourier && (widget.order.status == 'pickup' || widget.order.status == 'delivery'))
                   Positioned(
                    bottom: 10, left: 20, right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                      child: const Text("Menunggu Admin menugaskan kurir...", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                   ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getStatusTitle(widget.order.status), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_getStatusDesc(widget.order.status), style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    _buildTimeline(_getCurrentStep(widget.order.status)),
                    const SizedBox(height: 24),
                    const Divider(),
                    _buildInfoRow("Total Biaya", NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.order.totalPrice)),
                    const SizedBox(height: 8),
                    _buildInfoRow("Metode", widget.order.deliveryMethod == 'pickup' ? "Jemput & Antar" : "Antar Sendiri"),
                    if (widget.order.pickupSchedule != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow("Jadwal", DateFormat('dd MMM, HH:mm').format(widget.order.pickupSchedule!)),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'pending': return "Menunggu Konfirmasi";
      case 'pickup': return "Proses Penjemputan";
      case 'process': return "Sedang Dicuci";
      case 'delivery': return "Proses Pengantaran";
      case 'completed': return "Selesai";
      default: return "Dalam Proses";
    }
  }

  String _getStatusDesc(String status) {
    switch (status) {
      case 'pending': return "Pesananmu sedang dicek admin.";
      case 'pickup': return "Kurir akan segera menuju lokasimu.";
      case 'process': return "Pakaianmu sedang dibuat bersih & wangi.";
      case 'delivery': return "Pakaian bersih sedang OTW ke rumahmu.";
      case 'completed': return "Terima kasih sudah laundry di sini!";
      default: return "Mohon tunggu update selanjutnya.";
    }
  }

  Widget _buildTimeline(int step) {
    // PERBAIKAN: Ganti washingMachine (error) ke shirt
    final icons = [LucideIcons.clock, LucideIcons.bike, LucideIcons.shirt, LucideIcons.package, LucideIcons.checkCircle];
    final labels = ['Pending', 'Jemput', 'Cuci', 'Antar', 'Selesai'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(icons.length, (i) {
        final active = i <= step;
        return Expanded(
          child: Column(
            children: [
              Icon(icons[i], color: active ? Colors.blue : Colors.grey[300]),
              const SizedBox(height: 4),
              Text(labels[i], style: TextStyle(fontSize: 10, color: active ? Colors.blue : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}