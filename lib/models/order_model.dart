class Order {
  final String? id;
  final String customerName;
  final String serviceType;
  final double totalCost; // Harga Laundry
  final String address;
  final DateTime orderDate;
  final String status;
  final String? notes;
  final int? outletId;
  
  // --- FIELD BARU UNTUK LOGISTIK ---
  final double? latitude;
  final double? longitude;
  final String deliveryType; // Hemat, Reguler, Express
  final double deliveryFee;  // Ongkir
  final String deliveryStatus; // 'pending', 'otw', 'arrived', 'completed'
  final String? proofPhotoUrl; // URL Bukti Foto

  Order({
    this.id,
    required this.customerName,
    required this.serviceType,
    required this.totalCost,
    required this.address,
    required this.orderDate,
    this.status = 'pending',
    this.notes,
    this.latitude,
    this.longitude,
    this.deliveryType = 'Reguler',
    this.deliveryFee = 0,
    this.deliveryStatus = 'pending', // Default
    this.proofPhotoUrl,
    this.outletId,
  });

  // Helper Logic
  bool get isPickup => status.toLowerCase() == 'pickup';
  bool get isDelivery => status.toLowerCase() == 'delivery';

  Map<String, dynamic> toMap() {
    return {
      'customer_name': customerName,
      'service_type': serviceType,
      'total_cost': totalCost,
      'address': address,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'delivery_type': deliveryType,
      'delivery_fee': deliveryFee,
      'delivery_status': deliveryStatus,
      'outlet_id': outletId,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, String docId) {
    return Order(
      id: docId,
      customerName: map['customer_name'] ?? '',
      serviceType: map['service_type'] ?? '',
      totalCost: (map['total_cost'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      orderDate: DateTime.parse(
        map['order_date'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      deliveryType: map['delivery_type'] ?? 'Reguler',
      deliveryFee: (map['delivery_fee'] ?? 0).toDouble(),
      // Ambil status logistik, default ke 'pending' jika null
      deliveryStatus: map['delivery_status'] ?? 'pending',
      proofPhotoUrl: map['pickup_proof_url'] ?? map['delivery_proof_url'],
      outletId: map['outlet_id'] as int?,
    );
  }
}