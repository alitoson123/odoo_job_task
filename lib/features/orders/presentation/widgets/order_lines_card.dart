import 'package:flutter/material.dart';
import '../../data/models/sale_order_details_model.dart';
import 'order_line_item.dart';

/// Card displaying order items or an empty state message.
class OrderLinesCard extends StatelessWidget {
  final List<SaleOrderDetailsModel> lines;

  const OrderLinesCard({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            if (lines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No items found in this order.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...lines.map((line) => OrderLineItem(line: line)),
          ],
        ),
      ),
    );
  }
}
