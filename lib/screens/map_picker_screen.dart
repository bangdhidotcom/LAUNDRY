import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // <--- Import Baru
import 'package:lucide_icons/lucide_icons.dart';
import '../services/user_service.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final UserService _userService = UserService();
  
  LatLng? _currentCenter;
  bool _isLoading = true;
  String _statusMessage = "Memuat lokasi...";
  bool _isWithinRadius = false;
  double _distanceKm = 0.0;
  
  // Variabel baru untuk alamat asli
  String _realAddress = "Mengambil detail alamat..."; 
  bool _isFetchingAddress = false;
  
  List<Map<String, dynamic>> _outlets = [];
  double _maxRadius = 5.0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _outlets = await _userService.getOutlets();
    _maxRadius = await _userService.getMaxRadiusKm();

    try {
      Position pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentCenter = latLng;
        _isLoading = false;
      });
      _onLocationChanged(latLng); // Cek radius & ambil alamat
    } catch (e) {
      setState(() {
        // Fallback default jika GPS mati (misal ke pusat kota default)
        // User tetap bisa geser peta nanti
        _currentCenter = const LatLng(-6.2088, 106.8456); // Jakarta (Bisa diganti)
        _isLoading = false;
        _statusMessage = "GPS tidak terdeteksi, silakan geser peta manual.";
      });
    }
  }

  // Fungsi Logika Radius & Alamat
  Future<void> _onLocationChanged(LatLng point) async {
    _checkDistance(point);
    _getAddressFromLatLng(point);
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, p1, p2);
  }

  void _checkDistance(LatLng point) {
    if (_outlets.isEmpty) {
      setState(() {
        _isWithinRadius = true;
        _statusMessage = "Data outlet kosong (Mode Dev)";
      });
      return;
    }

    double minDistance = double.infinity;
    for (var outlet in _outlets) {
      if (outlet['latitude'] != null && outlet['longitude'] != null) {
        double d = _calculateDistance(
          point, 
          LatLng(outlet['latitude'], outlet['longitude'])
        );
        if (d < minDistance) minDistance = d;
      }
    }

    setState(() {
      _distanceKm = minDistance;
      if (minDistance <= _maxRadius) {
        _isWithinRadius = true;
        _statusMessage = "Terjangkau (${minDistance.toStringAsFixed(1)} km)";
      } else {
        _isWithinRadius = false;
        _statusMessage = "Di luar jangkauan (${minDistance.toStringAsFixed(1)} km)";
      }
    });
  }

  // --- FITUR BARU: REAL REVERSE GEOCODING ---
  Future<void> _getAddressFromLatLng(LatLng point) async {
    setState(() {
      _isFetchingAddress = true;
      _realAddress = "Mencari nama jalan...";
    });

    try {
      // Mengubah koordinat jadi daftar alamat
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude, 
        point.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Menyusun format alamat yang rapi
        // Contoh: "Jl. Merdeka No. 1, Klojen"
        String street = place.street ?? "";
        String subLocality = place.subLocality ?? "";
        String locality = place.locality ?? "";
        
        setState(() {
          _realAddress = "$street, $subLocality, $locality".replaceAll(RegExp(r'^, |,\s*$'), ''); 
          if (_realAddress.trim().isEmpty) _realAddress = "Lokasi Terpilih";
        });
      }
    } catch (e) {
      setState(() {
        _realAddress = "Gagal memuat nama jalan";
      });
    } finally {
      setState(() {
        _isFetchingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Lokasi Jemput")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter!,
                    initialZoom: 16,
                    // Saat peta berhenti digeser, update data
                    onMapEvent: (evt) {
                      if (evt is MapEventMoveEnd) {
                        final center = _mapController.camera.center;
                        setState(() => _currentCenter = center);
                        _onLocationChanged(center);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.laundry3b.user',
                    ),
                  ],
                ),
                // Pin selalu di tengah
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40.0), // Angkat dikit biar pas ujung pin
                    child: Icon(LucideIcons.mapPin, size: 50, color: Colors.red),
                  ),
                ),
                
                // Panel Info Bawah
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(blurRadius: 15, color: Colors.black12, offset: Offset(0, -2))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Radius
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isWithinRadius ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isWithinRadius ? "Area Terjangkau" : "Di Luar Area",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _isWithinRadius ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _statusMessage, // Jarak KM
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Alamat Real
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.mapPin, color: Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _isFetchingAddress
                                  ? const Text("Mencari alamat...", style: TextStyle(color: Colors.grey))
                                  : Text(
                                      _realAddress,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Tombol Pilih
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_isWithinRadius && !_isFetchingAddress)
                                ? () {
                                    // RETURN DATA REAL KE HOME SCREEN
                                    Navigator.pop(context, {
                                      'lat': _currentCenter!.latitude,
                                      'lng': _currentCenter!.longitude,
                                      'address': _realAddress // Alamat asli nama jalan!
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text("Konfirmasi Lokasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}