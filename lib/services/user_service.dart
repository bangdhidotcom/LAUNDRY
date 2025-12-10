import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<void> login({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Gagal login: ${e.toString()}');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'phone': phone,
        },
      );
    } catch (e) {
      throw Exception('Gagal mendaftar: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<List<ServicePrice>> getServices() async {
    try {
      final response = await _supabase
          .from('pricing')
          .select()
          .order('service_name', ascending: true);

      return (response as List).map((e) => ServicePrice.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createOrder(Order order) async {
    if (currentUserId == null) throw Exception("Harus login untuk memesan");

    try {
      final data = order.toMap();
      data['user_id'] = currentUserId;

      await _supabase.from('orders').insert(data);
    } catch (e) {
      throw Exception('Gagal membuat pesanan: $e');
    }
  }

  Stream<List<Order>> getMyOrdersStream() {
    if (currentUserId == null) return Stream.value([]);

    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .order('order_date', ascending: false)
        .map((data) => data.map((e) => Order.fromMap(e)).toList());
  }
}
