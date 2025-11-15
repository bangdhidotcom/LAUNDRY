import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../catalog_screen.dart';

class KelolaLayananPage extends StatefulWidget {
  const KelolaLayananPage({Key? key}) : super(key: key);

  @override
  State<KelolaLayananPage> createState() => _KelolaLayananPageState();
}

class _KelolaLayananPageState extends State<KelolaLayananPage> {
  final _supabaseService = SupabaseService();
  final _serviceController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State untuk melacak mode edit
  bool _isEditing = false;
  int? _editingId;
  bool _isLoading = false;

  List<Map<String, dynamic>> _pricingList = [];
  bool _isListLoading = true;

  @override
  void dispose() {
    _serviceController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPricingList();
  }

  Future<void> _loadPricingList() async {
    if (!mounted) return;
    setState(() {
      _isListLoading = true;
    });

    try {
      final data = await _supabaseService.getPricing();
      if (!mounted) return;
      setState(() {
        _pricingList = data;
        _isListLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal memuat daftar: $e'),
            backgroundColor: Colors.red),
      );
      setState(() {
        _isListLoading = false;
      });
    }
  }

  void _clearForm() {
    _serviceController.clear();
    _priceController.clear();
    _descriptionController.clear();
    setState(() {
      _isEditing = false;
      _editingId = null;
    });
  }

  void _startEditing(Map<String, dynamic> item) {
    setState(() {
      _isEditing = true;
      _editingId = item['id'];
      _serviceController.text = item['service_name'] ?? '';
      _priceController.text = (item['price'] ?? 0).toString();
      _descriptionController.text = item['description'] ?? '';
    });
  }

  Future<void> _submitForm() async {
    if (_serviceController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi semua field wajib'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'service_name': _serviceController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (_isEditing) {
        // --- LOGIKA UPDATE ---
        await _supabaseService.updatePricing(_editingId!, data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // --- LOGIKA CREATE ---
        await _supabaseService.setPricing(data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _clearForm();
      await _loadPricingList(); // Refresh daftar layanan
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> item) async {
    // Simpan data item dan posisinya, untuk jaga-jaga kalau gagal hapus
    final int index = _pricingList.indexWhere((p) => p['id'] == item['id']);
    if (index == -1) return; // Item tidak ditemukan, aneh.
    final itemDihapus = _pricingList[index];

    // --- INI PERBAIKANNYA ---
    // 1. Langsung hapus dari UI (Optimistic)
    setState(() {
      _pricingList.removeAt(index);
    });

    // Tampilkan dialog konfirmasi
    final bool konfirmasiHapus = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Layanan'),
            content: Text(
                'Anda yakin ingin menghapus layanan "${item['service_name']}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // Batal
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true), // Hapus
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false; // Jika dialog ditutup (misal, tap di luar), anggap "Batal"

    // 2. Jika admin menekan "Hapus"
    if (konfirmasiHapus) {
      try {
        // 3. Hapus data di server (di latar belakang)
        await _supabaseService.deletePricing(item['id']);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        // UI sudah ter-update, tidak perlu _loadPricingList()
      } catch (e) {
        // 4. JIKA GAGAL: Tampilkan error dan kembalikan item ke UI
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menghapus: $e. Mengembalikan data.'),
              backgroundColor: Colors.red),
        );
        // Kembalikan item ke posisi semula
        setState(() {
          _pricingList.insert(index, itemDihapus);
        });
      }
    } else {
      // 5. Jika admin menekan "Batal"
      // Kembalikan item ke UI
      setState(() {
        _pricingList.insert(index, itemDihapus);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Layanan'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Layanan' : 'Tambah Layanan Baru',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serviceController,
              decoration: InputDecoration(
                labelText: 'Nama Layanan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.local_laundry_service),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Harga (Rp)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi / Catatan Tambahan (Opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Layanan'),
              ),
            ),
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _clearForm,
                  child: const Text('Batal Edit'),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Daftar Layanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPricingListView()
          ],
        ),
      ),
    );
  }

  Widget _buildPricingListView() {
    if (_isListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pricingList.isEmpty) {
      return const Center(child: Text('Belum ada harga')); //
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pricingList.length,
      itemBuilder: (context, index) {
        final item = _pricingList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              LaundryService.getIconFromString(item['service_name'] ?? ''),
            ),
            title: Text(item['service_name'] ?? ''),
            subtitle: Text(item['description'] ?? 'Tanpa deskripsi'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rp ${item['price']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _startEditing(item),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: Colors.red[700]),
                  onPressed: () => _showDeleteConfirmation(item),
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}