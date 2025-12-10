import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../models/order_model.dart';
import 'tracking_screen.dart'; 

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: StreamBuilder<List<Order>>(
        stream: provider.myOrdersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.packageOpen, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Belum ada pesanan aktif", style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (ctx, index) {
              final order = orders[index];
              final isCompleted = order.status == 'completed';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    // Masuk ke Tracking Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TrackingScreen(order: order)),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Order #${order.id?.substring(0, 5) ?? '...'}", 
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(DateFormat('dd MMM, HH:mm').format(order.orderDate),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCompleted ? Colors.green[50] : Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted ? Colors.green : Colors.blue
                                ),
                              ),
                            )
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  order.deliveryMethod == 'pickup' ? LucideIcons.bike : LucideIcons.store,
                                  size: 16, color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  order.deliveryMethod == 'pickup' ? "Jemput Kurir" : "Antar Sendiri",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              currency.format(order.totalPrice),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}