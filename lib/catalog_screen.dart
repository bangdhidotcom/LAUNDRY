// [GANTI SELURUH ISI FILE lib/catalog_screen.dart]

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry3b1titik0/detail_screen.dart';
import 'package:laundry3b1titik0/controllers/catalog_controller.dart';

class LaundryService {
  final String name;
  final String price;
  final IconData icon;
  final String description;

  LaundryService({
    required this.name,
    required this.price,
    required this.icon,
    required this.description,
  });

  factory LaundryService.fromJson(Map<String, dynamic> json) {
    // --- PERBAIKAN LOGIKA IKON (SMART MAPPING) ---
    // Kita tidak membaca 'icon_name' dari Supabase
    // Kita MENGANALISIS 'service_name'
    final serviceName = json['service_name'] as String? ?? 'Unknown Service';
    final iconData = getIconFromString(serviceName);
    // --- AKHIR PERBAIKAN ---

    String priceString;
    final priceNum = (json['price'] as num?)?.toDouble();

    if (priceNum != null) {
      priceString = 'Rp ${priceNum.toStringAsFixed(0)}';
    } else {
      priceString = 'Harga tidak diatur';
    }

    return LaundryService(
      name: serviceName,
      price: priceString,
      icon: iconData, // Gunakan ikon dinamis hasil analisis
      description: json['description'] ?? '',
    );
  }

  // --- LOGIKA SMART MAPPING IKON ---
  static IconData getIconFromString(String serviceName) {
    String nameLower = serviceName.toLowerCase();

    if (nameLower.contains('sepatu')) {
      return Icons.ice_skating;
    }
    if (nameLower.contains('jas') || nameLower.contains('dry clean')) {
      return Icons.dry_cleaning;
    }
    if (nameLower.contains('bed cover') || nameLower.contains('sprei')) {
      return Icons.king_bed;
    }
    if (nameLower.contains('kemeja') || nameLower.contains('gaun')) {
      return Icons.checkroom;
    }
    if (nameLower.contains('setrika')) {
      return Icons.iron;
    }
    if (nameLower.contains('tas') || nameLower.contains('ransel')) {
      return Icons.shopping_bag; // Atau Icons.backpack
    }
    
    // Ikon Default
    return Icons.local_laundry_service;
  }
}

class CatalogScreen extends GetView<CatalogController> {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CatalogController catalogController = Get.put(CatalogController());

    final Size screenSize = MediaQuery.of(context).size;
    final int crossAxisCount = screenSize.width > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Layanan'),
        elevation: 1,
      ),
      // Background scaffold akan otomatis ikut tema
      body: Obx(() {
        if (catalogController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (catalogController.services.isEmpty) {
          return const Center(child: Text('Tidak ada layanan tersedia'));
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: catalogController.services.length,
            itemBuilder: (context, index) {
              return ServiceCard(service: catalogController.services[index]);
            },
          ),
        );
      }),
    );
  }
}

class ServiceCard extends StatefulWidget {
  const ServiceCard({super.key, required this.service});

  final LaundryService service;

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color cardColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final double elevation = _isPressed ? 8.0 : 2.0;
    final EdgeInsets padding = _isPressed
        ? const EdgeInsets.all(16.0)
        : const EdgeInsets.all(12.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) async {
        setState(() => _isPressed = false);
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) {
          Get.to(() => DetailScreen(service: widget.service));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: padding,
        decoration: BoxDecoration(
          color: cardColor, // Menggunakan warna kartu dari tema
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              // Ganti `Colors.black` dengan `shadowColor` dari tema
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: elevation,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < 180) {
              return buildCompactCard(context); // Beri context
            } else {
              return buildWideCard(context); // Beri context
            }
          },
        ),
      ),
    );
  }

  // Tambahkan `context` untuk mengambil warna tema
  Widget buildCompactCard(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'service_icon_${widget.service.name}',
          child: Material(
            type: MaterialType.transparency,
            child: Icon(
              widget.service.icon,
              size: 40,
              // Ganti warna statis dengan warna tema
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.service.name,
          textAlign: TextAlign.center,
          // Warna teks otomatis dari tema
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.service.price,
          // Biarkan merah, ini warna semantik untuk harga
          style: TextStyle(color: Colors.red[700], fontSize: 12),
        ),
      ],
    );
  }

  // Tambahkan `context` untuk mengambil warna tema
  Widget buildWideCard(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Hero(
          tag: 'service_icon_${widget.service.name}',
          child: Material(
            type: MaterialType.transparency,
            child: Icon(
              widget.service.icon,
              size: 48,
              // Ganti warna statis dengan warna tema
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.service.price,
                // Biarkan merah, ini warna semantik untuk harga
                style: TextStyle(color: Colors.red[700], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}