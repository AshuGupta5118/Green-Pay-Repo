import 'package:flutter/foundation.dart';

class Logger {
  static void debug(dynamic message) {
    if (kDebugMode) {
      print('💙 DEBUG: $message');
    }
  }

  static void info(dynamic message) {
    if (kDebugMode) {
      print('💚 INFO: $message');
    }
  }

  static void warning(dynamic message) {
    if (kDebugMode) {
      print('💛 WARNING: $message');
    }
  }

  static void error(dynamic message) {
    if (kDebugMode) {
      print('❤️ ERROR: $message');
    }
  }

  static void network(dynamic message) {
    if (kDebugMode) {
      print('💜 NETWORK: $message');
    }
  }
}
