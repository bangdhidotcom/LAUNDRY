import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  UserMetadata? get userMetadata => _supabase.auth.currentUser?.userMetadata;

  Future<void> login({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Gagal login: ${e.toString()}');
    }
  }

  Future<void> register({required String email, required String password, required String name, required String phone}) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'phone': phone},
      );
    } catch (e) {
      throw Exception('Gagal mendaftar: ${e.toString()}');
    }
  }

  Future<void> logout() async => await _supabase.auth.signOut();

  Future<List<ServicePrice>> getServices() async {
    try {
      final response = await _supabase.from('pricing').select().order('service_name', ascending: true);
      return (response as List).map((e) => ServicePrice.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBanners() async {
    try {
      final response = await _supabase.from('banners').select().eq('is_active', true).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getOutlets() async {
    try {
      final response = await _supabase.from('outlets').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<double> getMaxRadiusKm() async {
    try {
      final response = await _supabase.from('app_config').select('value').eq('key', 'max_pickup_radius_km').maybeSingle();
      if (response != null) return double.tryParse(response['value'].toString()) ?? 5.0;
      return 5.0;
    } catch (e) {
      return 5.0;
    }
  }

  Future<void> createOrder(Order order) async {
    if (currentUserId == null) throw Exception("Harus login untuk memesan");
    try {
      final data = order.toMap();
      data['user_id'] = currentUserId;
      // Hapus ID jika null agar digenerate DB
      data.remove('id'); 
      await _supabase.from('orders').insert(data);
    } catch (e) {
      throw Exception('Gagal membuat pesanan: $e');
    }
  }

  Stream<List<Order>> getMyOrdersStream() {
    if (currentUserId == null) return Stream.value([]);
    return _supabase.from('orders').stream(primaryKey: ['id']).eq('user_id', currentUserId!).order('order_date', ascending: false).map((data) => data.map((e) => Order.fromMap(e)).toList());
  }

  // --- REAL TIME TRACKING ---
  Stream<Map<String, dynamic>?> streamCourierLocation(int courierId) {
    return _supabase
        .from('couriers')
        .stream(primaryKey: ['id'])
        .eq('id', courierId)
        .map((event) => event.isNotEmpty ? event.first : null);
  }
}