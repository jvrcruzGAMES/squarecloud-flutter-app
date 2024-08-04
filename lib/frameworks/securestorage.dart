import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static FlutterSecureStorage? storage;

  static void init (){
    storage ??= const FlutterSecureStorage();
  }

  static Future<String?> read(String key) async {
    if (storage == null) {
      init();
    }
    return storage!.read(key: key);
  }

  static Future<void> write(String key, String value) async {
    return storage!.write(key: key, value: value);
  }

  static Future<void> delete(String key) async {
    return storage!.delete(key: key);
  }

  static Future<bool> contains(String key) async {
    return storage!.containsKey(key: key);
  }
}