import 'package:flutter/material.dart';

/// Renders a colored pill badge displaying order state.
class OrderStatusBadge extends StatelessWidget {
  final String state;
  final String label;

  const OrderStatusBadge({
    super.key,
    required this.state,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String state) {
    switch (state) {
      case 'draft':
        return Colors.orange.shade700;
      case 'sent':
        return Colors.blue.shade700;
      case 'sale':
        return Colors.green.shade700;
      case 'done':
        return Colors.teal.shade700;
      case 'cancel':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
