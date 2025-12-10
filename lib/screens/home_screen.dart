import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_provider.dart';
import '../services/user_service.dart';
import '../services/weather_service.dart';
import 'map_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final WeatherService _weatherService = WeatherService();
  
  List<Map<String, dynamic>> _banners = [];
  Map<String, dynamic>? _weatherData;
  bool _isLoadingBanner = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _fetchBanners();
    _fetchWeather();
    Future.microtask(() => 
      Provider.of<AppProvider>(context, listen: false).fetchServices()
    );
  }

  Future<void> _fetchBanners() async {
    final data = await _userService.getBanners();
    if (mounted) {
      setState(() {
        _banners = data;
        _isLoadingBanner = false;
      });
    }
  }

  Future<void> _fetchWeather() async {
    final data = await _weatherService.getCurrentWeather();
    if (mounted) {
      setState(() => _weatherData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = _userService.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Pelanggan';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(userName),
            const SizedBox(height: 20),
            _buildWeatherWidget(),
            const SizedBox(height: 20),
            _buildBannerSlider(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                "Layanan Kami",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            _buildServiceGrid(provider),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: provider.cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCartSheet(context),
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(LucideIcons.shoppingCart, color: Colors.white),
              label: Text(
                  "${provider.cart.length} Item - ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(provider.totalCartPrice)}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Halo, $name 👋",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Pakaian kotor numpuk? Serahkan pada kami!",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.bell, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    if (_weatherData == null) return const SizedBox.shrink();

    final temp = (_weatherData!['main']['temp'] as num).toInt();
    final desc = _weatherData!['weather'][0]['description'];
    final iconCode = _weatherData!['weather'][0]['icon'];
    final city = _weatherData!['name'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.network(
            'https://openweathermap.org/img/wn/$iconCode@2x.png',
            width: 50,
            height: 50,
            errorBuilder: (_,__,___) => const Icon(LucideIcons.cloud, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$temp°C - $desc",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "Lokasi Anda: $city",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSlider() {
    if (_isLoadingBanner) {
      return Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_banners.isEmpty) return const SizedBox.shrink();

    return CarouselSlider(
      options: CarouselOptions(
        height: 160.0,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        aspectRatio: 16/9,
        autoPlayCurve: Curves.fastOutSlowIn,
      ),
      items: _banners.map((banner) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(banner['image_url']),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Text(
                  banner['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildServiceGrid(AppProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("Belum ada layanan tersedia"),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85, 
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.services.length,
      itemBuilder: (context, index) {
        final service = provider.services[index];
        final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shirt, color: Color(0xFF2563EB), size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                service.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "${currency.format(service.price)} / ${service.unit}",
                style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () => provider.addToCart(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text("Tambah", style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => const CartSheet());
  }
}

class CartSheet extends StatefulWidget {
  const CartSheet({super.key});

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(); // Alamat Text

  // State Baru
  double? _selectedLat;
  double? _selectedLng;
  String _deliveryMethod = 'pickup'; // 'pickup' (Jemput) atau 'dropoff' (Antar Sendiri)
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (ctx) => const MapPickerScreen())
    );

    if (result != null && result is Map) {
      setState(() {
        _selectedLat = result['lat'];
        _selectedLng = result['lng'];
        _addressController.text = result['address'];
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24),
      child: SingleChildScrollView( // Tambah Scroll agar tidak overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Keranjang Cucian", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.red),
                  onPressed: () { provider.clearCart(); Navigator.pop(context); },
                )
              ],
            ),
            
            // --- OPSI PENGANTARAN ---
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text("Kurir Jemput"),
                    selected: _deliveryMethod == 'pickup',
                    onSelected: (val) => setState(() => _deliveryMethod = 'pickup'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text("Antar Sendiri"),
                    selected: _deliveryMethod == 'dropoff',
                    onSelected: (val) => setState(() => _deliveryMethod = 'dropoff'),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Form Standar
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(LucideIcons.user)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Nomor WhatsApp', prefixIcon: Icon(LucideIcons.phone)),
              keyboardType: TextInputType.phone,
            ),

            // --- BAGIAN DINAMIS (Jemput vs Antar) ---
            if (_deliveryMethod == 'pickup') ...[
              const SizedBox(height: 16),
              const Text("Lokasi Penjemputan", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickLocation,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.mapPin, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _addressController.text.isEmpty 
                              ? "Klik untuk pilih titik di peta" 
                              : _addressController.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text("Jadwal (Opsional)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, color: Colors.orange),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate == null 
                          ? "Pilih Tanggal & Jam" 
                          : "${DateFormat('dd MMM yyyy').format(_selectedDate!)}, ${_selectedTime!.format(context)}",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isEmpty || _phoneController.text.isEmpty) return;
                  
                  // Validasi Lokasi jika Pickup
                  if (_deliveryMethod == 'pickup' && (_selectedLat == null || _selectedLng == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon pilih lokasi di peta")));
                    return;
                  }

                  // Gabung Tanggal + Jam
                  DateTime? finalSchedule;
                  if (_selectedDate != null && _selectedTime != null) {
                    finalSchedule = DateTime(
                      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
                      _selectedTime!.hour, _selectedTime!.minute
                    );
                  }

                  final success = await provider.checkout(
                      name: _nameController.text,
                      phone: _phoneController.text,
                      address: _deliveryMethod == 'pickup' ? _addressController.text : 'Antar Sendiri ke Outlet',
                      deliveryMethod: _deliveryMethod,
                      lat: _selectedLat,
                      lng: _selectedLng,
                      pickupSchedule: finalSchedule,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Pesanan Berhasil!"), backgroundColor: Colors.green));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Buat Pesanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}