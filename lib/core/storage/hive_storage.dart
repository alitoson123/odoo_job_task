import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';

/// Centralized local storage manager using Hive.
class HiveStorage {
  static const String boxCustomers = 'customers';
  static const String boxPendingOps = 'pending_ops';
  static const String boxOrders = 'orders';

  /// Initializes Hive and opens required boxes for offline caching.
  static Future<void> init([String? path]) async {
    try {
      if (path != null) {
        Hive.init(path);
      } else {
        await Hive.initFlutter();
      }
      await _openBoxes();
    } catch (_) {
      try {
        final tempDir = Directory.systemTemp.createTempSync('hive_test');
        Hive.init(tempDir.path);
        await _openBoxes();
      } catch (_) {}
    }
  }

  static Future<void> _openBoxes() async {
    await Future.wait([
      if (!Hive.isBoxOpen(boxCustomers)) Hive.openBox(boxCustomers),
      if (!Hive.isBoxOpen(boxPendingOps)) Hive.openBox(boxPendingOps),
      if (!Hive.isBoxOpen(boxOrders)) Hive.openBox(boxOrders),
    ]);
  }

  /// Accessor for customer cache box.
  static Box get customersBox => Hive.box(boxCustomers);

  /// Accessor for pending offline operations queue box.
  static Box get pendingOpsBox => Hive.box(boxPendingOps);

  /// Accessor for sales orders cache box.
  static Box get ordersBox => Hive.box(boxOrders);

  /// Closes all open Hive boxes.
  static Future<void> close() async {
    await Hive.close();
  }
}
