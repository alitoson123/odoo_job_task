import 'package:flutter/material.dart';
import '../../data/models/sale_order_model.dart';

/// Card showing untaxed, tax, and total amounts for a sales order.
class OrderTotalsCard extends StatelessWidget {
  final SaleOrderModel order;

  const OrderTotalsCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRow(
              'Untaxed Amount',
              '\$${order.amountUntaxed.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildRow(
              'Taxes',
              '\$${order.amountTax.toStringAsFixed(2)}',
            ),
            const Divider(height: 24),
            _buildRow(
              'Total',
              '\$${order.amountTotal.toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black87 : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? Colors.blue.shade800 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
