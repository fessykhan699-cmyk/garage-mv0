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
}

class _BoxNames {
  static const auth = 'auth';
  static const garages = 'garages';
}
