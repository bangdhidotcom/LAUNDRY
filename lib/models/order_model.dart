class Order {
  final String? id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String address;
  final List<OrderItem> items;
  final int totalPrice;
  final String status;
  final DateTime orderDate;
  
  // Field Logistik
  final double? latitude;
  final double? longitude;
  final String deliveryMethod;
  final DateTime? pickupSchedule;
  final int? courierId; // <--- Field Baru untuk Tracking Real

  Order({
    this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.items,
    required this.totalPrice,
    this.status = 'pending',
    required this.orderDate,
    this.latitude,
    this.longitude,
    this.deliveryMethod = 'pickup',
    this.pickupSchedule,
    this.courierId,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'address': address,
      'items': items.map((x) => x.toMap()).toList(),
      'total_cost': totalPrice,
      'status': status,
      'order_date': orderDate.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'delivery_method': deliveryMethod,
      'pickup_schedule': pickupSchedule?.toIso8601String(),
      'courier_id': courierId,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'] ?? '',
      address: map['address'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((x) => OrderItem.fromMap(x))
              .toList() ??
          [],
      totalPrice: (map['total_cost'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'pending',
      orderDate: DateTime.parse(map['order_date']),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      deliveryMethod: map['delivery_method'] ?? 'pickup',
      pickupSchedule: map['pickup_schedule'] != null 
          ? DateTime.parse(map['pickup_schedule']) 
          : null,
      courierId: map['courier_id'] as int?, // Mapping dari DB
    );
  }
}

class OrderItem {
  final String serviceName;
  final int price;
  final int quantity;
  final String unit;

  OrderItem({
    required this.serviceName,
    required this.price,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toMap() => {
        'service_name': serviceName,
        'price': price,
        'quantity': quantity,
        'unit': unit,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        serviceName: map['service_name'] ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        unit: map['unit'] ?? 'kg',
      );
}

class ServicePrice {
  final int id;
  final String name;
  final int price;
  final String unit;

  ServicePrice({required this.id, required this.name, required this.price, required this.unit});

  factory ServicePrice.fromMap(Map<String, dynamic> map) => ServicePrice(
        id: map['id'],
        name: map['service_name'] ?? 'Layanan',
        price: (map['price'] as num?)?.toInt() ?? 0,
        unit: map['unit'] ?? 'kg',
      );
}