// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry3B',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[600],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.sparkles, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Selamat Datang!",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text("Pilih layanan laundry di bawah ini.",
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Daftar Layanan",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...provider.services.map((service) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(service.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "${currency.format(service.price)} / ${service.unit}"),
                        trailing: ElevatedButton(
                          onPressed: () => provider.addToCart(service),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white),
                          child: const Text("Tambah"),
                        ),
                      ),
                    )),
              ],
            ),
      floatingActionButton: provider.cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCartSheet(context),
              backgroundColor: Colors.blue[600],
              icon: const Icon(LucideIcons.shoppingCart, color: Colors.white),
              label: Text(
                  "${provider.cart.length} Item - ${currency.format(provider.totalCartPrice)}",
                  style: const TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
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
  final _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Keranjang",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.separated(
              itemCount: provider.cart.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, i) {
                final item = provider.cart[i];
                return ListTile(
                  dense: true,
                  title: Text(item.serviceName),
                  subtitle: Text(
                      "${item.quantity} ${item.unit} x ${currency.format(item.price)}"),
                  trailing: IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.red),
                      onPressed: () =>
                          provider.removeFromCart(item.serviceName)),
                );
              },
            ),
          ),
          const Divider(),
          TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap')),
          TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Nomor WA'),
              keyboardType: TextInputType.phone),
          TextField(
              controller: _addressController,
              decoration:
                  const InputDecoration(labelText: 'Alamat Penjemputan')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty ||
                    _addressController.text.isEmpty) return;
                final success = await provider.checkout(
                    name: _nameController.text,
                    phone: _phoneController.text,
                    address: _addressController.text);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Pesanan Berhasil!")));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white),
              child: const Text("Pesan Sekarang"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
