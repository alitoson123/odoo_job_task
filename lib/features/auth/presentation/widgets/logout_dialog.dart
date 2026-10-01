import 'package:flutter/material.dart';

/// Modal dialog confirming user intent to log out.
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  /// Displays the logout confirmation dialog and returns confirmation bool.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out of your session?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Log Out'),
        ),
      ],
    );
  }
}
