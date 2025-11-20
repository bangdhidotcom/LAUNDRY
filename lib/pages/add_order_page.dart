// ignore_for_file: use_super_parameters, curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({Key? key}) : super(key: key);

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedService;
  double _selectedPrice = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      // Modifikasi: Tambahkan .order() agar daftar layanan terurut
      final pricing = await _supabaseService.getPricing().then(
            (data) => data
              ..sort((a, b) => (a['service_name'] as String)
                  .compareTo(b['service_name'] as String)),
          );

      // Jika SupabaseService Anda diperbarui untuk mendukung order:
      // final pricing = await _supabaseService.getPricing(orderBy: 'service_name');
      
      setState(() {
        _services = pricing;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading services: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis layanan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final order = Order(
        customerName: _nameController.text,
        serviceType: _selectedService!,
        totalCost: _selectedPrice,
        address: 'Pending', // Akan diisi saat pickup
        orderDate: DateTime.now(),
        status: 'pending',
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await _supabaseService.addOrder(order);

      if (!mounted) return;

      // Clear form
      _nameController.clear();
      _phoneController.clear();
      _notesController.clear();
      setState(() {
        _selectedService = null;
        _selectedPrice = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Order Baru'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Form Pemesanan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Nama Pelanggan
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pelanggan',
                  hintText: 'Masukkan nama pelanggan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Nomor HP
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Nomor HP',
                  hintText: '08xxxxxxxxxx',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Nomor HP tidak boleh kosong';
                  if (!RegExp(r'^(\+62|62|0)[0-9]{9,12}$').hasMatch(value!)) {
                    return 'Format nomor HP tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Jenis Layanan Dropdown
              const Text(
                'Jenis Layanan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _services.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedService,
                      decoration: InputDecoration(
                        labelText: 'Pilih Layanan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.local_laundry_service),
                      ),
                      items: _services.map((service) {
                        final name = service['service_name'] ?? 'Unknown';
                        final price = service['price'] ?? 0;
                        return DropdownMenuItem<String>(
                          value: name as String,
                          child: Text('$name - Rp ${price.toStringAsFixed(0)}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedService = value;
                          if (value != null) {
                            final service = _services.firstWhere(
                              (s) => s['service_name'] == value,
                              orElse: () => {'price': 0},
                            );
                            _selectedPrice = (service['price'] ?? 0).toDouble();
                          }
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Pilih jenis layanan' : null,
                    ),
              const SizedBox(height: 24),

              // Total Harga (Display Only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Biaya',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${_selectedPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Catatan
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Tambahkan catatan khusus...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005f9f),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Tambah Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
