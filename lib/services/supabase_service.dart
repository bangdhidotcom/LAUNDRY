import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== ORDERS ====================
  Future<void> addOrder(Order order) async {
    try {
      await _supabase.from('orders').insert(order.toMap());
    } catch (e) {
      throw Exception('Gagal menambah order: $e');
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('order_date', ascending: false);
      return (response as List)
          .map((item) => Order.fromMap(item, item['id'].toString()))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil orders: $e');
    }
  }

  Future<List<Order>> getOrdersByStatus(String status) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('status', status)
          .order('order_date', ascending: false);
      return (response as List)
          .map((item) => Order.fromMap(item, item['id'].toString()))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil orders: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Gagal update status: $e');
    }
  }

  Future<void> updateOrder(
    String orderId,
    String customerName,
    String serviceType,
    double totalCost,
  ) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'customer_name': customerName,
            'service_type': serviceType,
            'total_cost': totalCost,
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Gagal update order: $e');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _supabase.from('orders').delete().eq('id', orderId);
    } catch (e) {
      throw Exception('Gagal hapus order: $e');
    }
  }

  // ==================== OUTLETS ====================
  Future<void> addOutlet(Map<String, dynamic> outlet) async {
    try {
      await _supabase.from('outlets').insert(outlet);
    } catch (e) {
      throw Exception('Gagal menambah outlet: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOutlets() async {
    try {
      return await _supabase.from('outlets').select();
    } catch (e) {
      throw Exception('Gagal mengambil outlets: $e');
    }
  }

  // ==================== CUSTOMERS ====================
  Future<void> addCustomer(Map<String, dynamic> customer) async {
    try {
      await _supabase.from('customers').insert(customer);
    } catch (e) {
      throw Exception('Gagal menambah customer: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      return await _supabase.from('customers').select();
    } catch (e) {
      throw Exception('Gagal mengambil customers: $e');
    }
  }

  // ==================== PRICING ====================
  Future<void> setPricing(Map<String, dynamic> pricing) async {
    try {
      await _supabase.from('pricing').insert(pricing);
    } catch (e) {
      throw Exception('Gagal menetapkan harga: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPricing() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _supabase
          .from('pricing')
          .select()
          .order('service_name', ascending: true);
          
      stopwatch.stop();
      print('===== LAPORAN KECEPATAN (BACA) =====');
      print('Baca Supabase (Semua pricing): ${stopwatch.elapsedMilliseconds} milliseconds');
      print('====================================');
          
      return response;
    } catch (e) {
      stopwatch.stop();
      print('Gagal Baca Supabase: ${e.toString()}');
      throw Exception('Gagal mengambil pricing: $e');
    }
  }

  Future<void> updatePricing(int id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('pricing').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Gagal update harga: $e');
    }
  }

  Future<void> deletePricing(int id) async {
    try {
      await _supabase.from('pricing').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal hapus harga: $e');
    }
  }

  Future<String> uploadServiceImage(XFile image) async {
    try {
      final file = File(image.path);
      final fileExtension = p.extension(image.name);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'public/$fileName'; // 'public' adalah nama Bucket Anda

      // 1. Upload file
      await _supabase.storage.from('gambar_layanan').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // 2. Dapatkan URL publik
      final publicUrl = _supabase.storage
          .from('gambar_layanan') // Nama Bucket
          .getPublicUrl(filePath); // Path file yang sama

      return publicUrl;
    } catch (e) {
      throw Exception('Gagal upload gambar: $e');
    }
  }

  /// Menghapus gambar layanan dari Supabase Storage berdasarkan URL
  Future<void> deleteServiceImage(String imageUrl) async {
    try {
      // Ekstrak file path dari URL
      // Contoh URL: https://.../storage/v1/object/public/gambar_layanan/public/12345.jpg
      // Kita perlu mengambil 'public/12345.jpg'
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length > 2) {
        // Ambil path setelah nama bucket
        final filePath = pathSegments.sublist(pathSegments.indexOf('public')).join('/');
        
        await _supabase.storage.from('gambar_layanan').remove([filePath]);
      }
    } catch (e) {
      // Tidak perlu throw error fatal, cukup log saja
      print('Gagal hapus gambar lama (mungkin sudah tidak ada): $e');
    }
  }

  // ==================== PROMOS ====================
  Future<void> addPromo(Map<String, dynamic> promo) async {
    try {
      await _supabase.from('promos').insert(promo);
    } catch (e) {
      throw Exception('Gagal menambah promo: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPromos() async {
    try {
      return await _supabase.from('promos').select();
    } catch (e) {
      throw Exception('Gagal mengambil promos: $e');
    }
  }
}
