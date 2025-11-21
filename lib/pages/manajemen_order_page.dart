// ignore_for_file: use_super_parameters, deprecated_member_use, use_build_context_synchronously, prefer_final_fields, prefer_final_fields, duplicate_ignore, unused_field

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';
import 'add_order_page.dart'; // Pastikan import ini ada

class ManajemenOrderPage extends StatefulWidget {
  const ManajemenOrderPage({Key? key}) : super(key: key);

  @override
  State<ManajemenOrderPage> createState() => _ManajemenOrderPageState();
}

class _ManajemenOrderPageState extends State<ManajemenOrderPage> {
  final _supabaseService = SupabaseService();
  String _filterStatus = 'all';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Order'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('pickup', 'Jemput'),
                const SizedBox(width: 8),
                _buildFilterChip('process', 'Cuci'), // Ganti washing jadi process biar konsisten DB
                const SizedBox(width: 8),
                _buildFilterChip('delivery', 'Antar'),
                const SizedBox(width: 8),
                _buildFilterChip('done', 'Selesai'),
              ],
            ),
          ),
          
          // Order List
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _filterStatus == 'all'
                  ? _supabaseService.getOrders()
                  : _supabaseService.getOrdersByStatus(_filterStatus),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada order'));
                }

                final orders = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 80),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // TOMBOL TAMBAH ORDER (TETAP ADA)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.to(() => const AddOrderPage());
          if (result == true) {
            setState(() {}); // Refresh jika ada order baru
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Order', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF005f9f),
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = status;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF005f9f),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    
    // Format Rupiah manual (sesuai kode lama bos)
    final formattedPrice = 'Rp ${order.totalCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            order.status == 'pickup' ? Icons.location_on :
            order.status == 'delivery' ? Icons.local_shipping :
            Icons.shopping_bag, 
            color: statusColor
          ),
        ),
        title: Text(
          order.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${order.serviceType} • $formattedPrice',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Pelanggan', order.customerName),
                const SizedBox(height: 8),
                _buildInfoRow('Layanan', order.serviceType),
                const SizedBox(height: 8),
                _buildInfoRow('Alamat', order.address),
                const SizedBox(height: 8),
                _buildInfoRow('Biaya', formattedPrice),
                if (order.notes != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Catatan', order.notes!),
                ],
                
                const SizedBox(height: 16),
                const Divider(),
                
                // --- BARIS TOMBOL AKSI ---
                Row(
                  children: [
                    // 1. Tombol Edit
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditDialog(order),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 2. Tombol Hapus
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmation(order),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),

                // 3. TOMBOL STATUS KHUSUS (Fitur Baru yang kita bahas)
                if (order.status == 'process')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(order.id!, 'delivery'),
                      icon: const Icon(Icons.local_shipping, color: Colors.white),
                      label: const Text('SIAP ANTAR (Panggil Kurir)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    ),
                  )
                else if (order.status == 'pickup')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: null, // Disabled
                      icon: const Icon(Icons.timelapse),
                      label: const Text('Menunggu Kurir Jemput'),
                    ),
                  )
                else if (order.status == 'delivery')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: null, // Disabled
                      icon: const Icon(Icons.directions_bike),
                      label: const Text('Sedang Diantar Kurir'),
                    ),
                  )
                else if (order.status == 'pending')
                   SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(order.id!, 'pickup'),
                      icon: const Icon(Icons.check),
                      label: const Text('Konfirmasi Jemput'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI LOGIKA ---

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await _supabaseService.updateOrderStatus(id, newStatus);
      setState(() {}); // Refresh UI
      Get.snackbar('Sukses', 'Status diubah ke ${newStatus.toUpperCase()}', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Gagal: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'pickup': return Colors.red;
      case 'process': return Colors.purple; // Cuci
      case 'washing': return Colors.purple; // Jaga2 kalau ada data lama
      case 'delivery': return Colors.blue;
      case 'done': return Colors.green;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Menunggu';
      case 'pickup': return 'Dijemput';
      case 'process': return 'Dicuci';
      case 'washing': return 'Dicuci';
      case 'delivery': return 'Diantar';
      case 'done': return 'Selesai';
      case 'completed': return 'Selesai';
      default: return status.toUpperCase();
    }
  }

  // --- DIALOG EDIT (KEMBALI SEPERTI KODE BOS) ---
  void _showEditDialog(Order order) {
    final nameController = TextEditingController(text: order.customerName);
    final serviceController = TextEditingController(text: order.serviceType);
    final costController = TextEditingController(text: order.totalCost.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
              const SizedBox(height: 12),
              TextField(controller: serviceController, decoration: const InputDecoration(labelText: 'Jenis Layanan')),
              const SizedBox(height: 12),
              TextField(controller: costController, decoration: const InputDecoration(labelText: 'Biaya'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supabaseService.updateOrder(
                  order.id!,
                  nameController.text,
                  serviceController.text,
                  double.parse(costController.text),
                );
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {}); // Refresh
                Get.snackbar('Sukses', 'Order berhasil diupdate', backgroundColor: Colors.green, colorText: Colors.white);
              } catch (e) {
                Get.snackbar('Error', '$e', backgroundColor: Colors.red, colorText: Colors.white);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // --- DIALOG HAPUS (KEMBALI SEPERTI KODE BOS) ---
  void _showDeleteConfirmation(Order order) {
    Get.defaultDialog(
      title: 'Hapus Order?',
      middleText: 'Hapus order dari ${order.customerName}?',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back(); // Tutup dialog
        try {
          await _supabaseService.deleteOrder(order.id!);
          setState(() {}); // Refresh
          Get.snackbar('Sukses', 'Order dihapus', backgroundColor: Colors.green, colorText: Colors.white);
        } catch (e) {
          Get.snackbar('Error', '$e', backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }
}