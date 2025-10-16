import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Lightweight logging wrapper so services can depend on a common surface.
class AppLogger {
  const AppLogger();

  void debug(String message) {
    _print('[DEBUG] $message');
  }

  void info(String message) {
    _print('[INFO] $message');
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _print('[WARN] $message');
    if (error != null) {
      _print('  error: $error');
    }
    if (stackTrace != null) {
      _print('  stackTrace: $stackTrace');
    }
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _print('[ERROR] $message');
    if (error != null) {
      _print('  error: $error');
    }
    if (stackTrace != null) {
      _print('  stackTrace: $stackTrace');
    }
  }

  void _print(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
    developer.log(message, name: 'RiseUnplugged');
  }
}

final appLoggerProvider = Provider<AppLogger>((ref) => const AppLogger());
