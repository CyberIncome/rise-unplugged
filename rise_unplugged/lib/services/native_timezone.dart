import 'package:flutter/services.dart';

class NativeTimezone {
  static const _channel = MethodChannel('com.rise.unplugged/timezone');

  static Future<String> getLocalTimezone() async {
    final timezone =
        await _channel.invokeMethod<String>('getLocalTimezone');
    return timezone ?? 'UTC';
  }

  static Future<List<String>> getAvailableTimezones() async {
    final zones =
        await _channel.invokeListMethod<String>('getAvailableTimezones');
    return zones ?? const <String>[];
  }
}
