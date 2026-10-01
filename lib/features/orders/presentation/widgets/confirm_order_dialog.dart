import 'package:flutter/material.dart';

/// Dialog requesting user confirmation before confirming an Odoo sales order.
class ConfirmOrderDialog extends StatelessWidget {
  final String orderName;

  const ConfirmOrderDialog({super.key, required this.orderName});

  /// Displays the dialog and returns true if user confirms.
  static Future<bool?> show(BuildContext context, String orderName) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmOrderDialog(orderName: orderName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Order'),
      content: Text(
        'Are you sure you want to confirm sales order $orderName? '
        'This will change its status from Quotation to Confirmed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
