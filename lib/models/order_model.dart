class Order {
  final String? id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<OrderItem> items;
  final int totalPrice;
  final String status;
  final DateTime orderDate;
  final String? outletId;

  Order({
    this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.totalPrice,
    this.status = 'pending',
    required this.orderDate,
    this.outletId,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'address': customerAddress,
      'items': items.map((x) => x.toMap()).toList(),
      'total_cost': totalPrice,
      'status': status,
      'order_date': orderDate.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'] ?? '',
      customerAddress: map['address'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((x) => OrderItem.fromMap(x))
              .toList() ??
          [],
      totalPrice: (map['total_cost'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'pending',
      orderDate: DateTime.parse(map['order_date']),
      outletId: map['outlet_id']?.toString(),
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

  Map<String, dynamic> toMap() {
    return {
      'service_name': serviceName,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      serviceName: map['service_name'] ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unit: map['unit'] ?? 'kg',
    );
  }
}

class ServicePrice {
  final int id;
  final String name;
  final int price;
  final String unit;

  ServicePrice({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
  });

  factory ServicePrice.fromMap(Map<String, dynamic> map) {
    return ServicePrice(
      id: map['id'],
      name: map['service_name'] ?? 'Layanan',
      price: (map['price'] as num?)?.toInt() ?? 0,
      unit: map['unit'] ?? 'kg',
    );
  }
}
