// ignore_for_file: use_super_parameters, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';
import 'add_order_page.dart';

class ManajemenOrderPage extends StatefulWidget {
  const ManajemenOrderPage({Key? key}) : super(key: key);

  @override
  State<ManajemenOrderPage> createState() => _ManajemenOrderPageState();
}

class _ManajemenOrderPageState extends State<ManajemenOrderPage> {
  final _supabaseService = SupabaseService();
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Order'),
        elevation: 0,
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
                _buildFilterChip('pickup', 'Pickup'),
                const SizedBox(width: 8),
                _buildFilterChip('washing', 'Cuci'),
                const SizedBox(width: 8),
                _buildFilterChip('ready', 'Siap'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Selesai'),
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
                  padding: const EdgeInsets.all(12),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.to(() => const AddOrderPage());
          if (result == true) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Order'),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.3),
          child: Icon(Icons.shopping_bag, color: statusColor),
        ),
        title: Text(
          order.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${order.serviceType} • ${order.orderDate.day}/${order.orderDate.month}',
        ),
        trailing: Chip(
          label: Text(statusLabel),
          backgroundColor: statusColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
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
                _buildInfoRow(
                  'Biaya',
                  'Rp ${order.totalCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Status', statusLabel),
                if (order.notes != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Catatan', order.notes!),
                ],
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    // Edit Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showEditDialog(order);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showDeleteConfirmation(order);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Hapus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Status Update Button
                if (order.status != 'completed')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showStatusUpdateDialog(order);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: Text(_getNextStatusLabel(order.status)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'pickup':
        return Colors.blue;
      case 'washing':
        return Colors.purple;
      case 'ready':
        return Colors.teal;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'pickup':
        return 'Pickup';
      case 'washing':
        return 'Sedang Cuci';
      case 'ready':
        return 'Siap Ambil';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  String _getNextStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Mark as Pickup';
      case 'pickup':
        return 'Start Washing';
      case 'washing':
        return 'Mark as Ready';
      case 'ready':
        return 'Mark as Completed';
      default:
        return 'Update Status';
    }
  }

  String _getNextStatus(String status) {
    switch (status) {
      case 'pending':
        return 'pickup';
      case 'pickup':
        return 'washing';
      case 'washing':
        return 'ready';
      case 'ready':
        return 'completed';
      default:
        return status;
    }
  }

  void _showStatusUpdateDialog(Order order) {
    final nextStatus = _getNextStatus(order.status);
    final nextStatusLabel = _getStatusLabel(nextStatus);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status Order'),
        content: Text('Ubah status menjadi $nextStatusLabel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabaseService.updateOrderStatus(order.id!, nextStatus);
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Status diubah ke $nextStatusLabel'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Order order) {
    final nameController = TextEditingController(text: order.customerName);
    final serviceController = TextEditingController(text: order.serviceType);
    final costController = TextEditingController(
      text: order.totalCost.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: serviceController,
                decoration: const InputDecoration(labelText: 'Jenis Layanan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Biaya'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
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
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order berhasil diupdate'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Order'),
        content: Text('Hapus order dari ${order.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabaseService.deleteOrder(order.id!);
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
