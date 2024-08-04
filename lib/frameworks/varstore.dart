

import 'package:logger/web.dart';

class SameProcessStorage {
  static final Map<String, dynamic> _store = <String, dynamic>{};

  
  static void clear() {
    _store.clear();
  }

  
  static void delete(String key) {
    _store.remove(key);
  }

  
  static bool exists(String key) {
    return _store.containsKey(key);
  }

  
  static dynamic read(String key) {
    return _store[key];
  }

  
  static void write(String key, dynamic value) {
    _store[key] = value;
  }
  
}

class SquareLogger {
  static final Logger _logger = Logger();

  
  static void debug(String message) {
    _logger.d(message);
  }

  
  static void error(String message) {
    _logger.e(message);
  }

  
  static void info(String message) {
    _logger.i(message);
  }

  
  static void warning(String message) {
    _logger.w(message);
  }
}