import 'package:flutter/material.dart';

/// Form component for editing customer phone number.
class CustomerPhoneEditForm extends StatelessWidget {
  final TextEditingController controller;
  final bool isUpdating;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const CustomerPhoneEditForm({
    super.key,
    required this.controller,
    required this.isUpdating,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          enabled: !isUpdating,
          decoration: const InputDecoration(
            hintText: 'Enter new phone number',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isUpdating ? null : onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isUpdating ? null : onSave,
              child: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
