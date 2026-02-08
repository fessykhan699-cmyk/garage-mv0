import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  LocalStorage._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _initialized = true;
  }

  static Future<Box<T>> openBox<T>(String name) async {
    await init();
    return Hive.openBox<T>(name);
  }

  static Future<Box<Map<String, dynamic>>> authBox() =>
      openBox<Map<String, dynamic>>(_BoxNames.auth);

  static Future<Box<Map<String, dynamic>>> garageBox() =>
      openBox<Map<String, dynamic>>(_BoxNames.garages);

  // Additional boxes for local-first architecture
  static Future<Box<Map<String, dynamic>>> appBox() =>
      openBox<Map<String, dynamic>>(_BoxNames.app);

  static Future<Box<Map<String, dynamic>>> usersBox() =>
      openBox<Map<String, dynamic>>(_BoxNames.users);

  static Future<Box<Map<String, dynamic>>> customersBox() =>
      openBox<Map<String, dynamic>>(_BoxNames.customers);

  static Future<Box<Map<String, dynamic>>> vehiclesBox() =>
      openBox<Map<String, dynamic>>(_BoxNames.vehicles);

  static Future<Box<Map<String, dynamic>>> jobCardsBox() =>
      openBox<Map<String, dynamic>>(_BoxNames.jobCards);

  static Future<Box<Map<String, dynamic>>> quotationsBox() =>
      openBox<Map<String, dynamic>>(_BoxNames.quotations);

  static Future<Box<Map<String, dynamic>>> invoicesBox() =>
      openBox<Map<String, dynamic>>(_BoxNames.invoices);

  static Future<Box<Map<String, dynamic>>> paymentsBox() =>
      openBox<Map<String, dynamic>>(_BoxNames.payments);

  // Helper to get current session garageId
  static Future<String?> getSessionGarageId() async {
    final box = await appBox();
    return box.get('sessionGarageId') as String?;
  }

  // Helper to set current session garageId
  static Future<void> setSessionGarageId(String? garageId) async {
    final box = await appBox();
    if (garageId == null) {
      await box.delete('sessionGarageId');
    } else {
      await box.put('sessionGarageId', garageId);
    }
  }
}

class _BoxNames {
  static const auth = 'auth';
  static const garages = 'garages';
  static const app = 'app';
  static const users = 'users';
  static const customers = 'customers';
  static const vehicles = 'vehicles';
  static const jobCards = 'jobCards';
  static const quotations = 'quotations';
  static const invoices = 'invoices';
  static const payments = 'payments';
}
