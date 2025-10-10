import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';

class AlarmRepository {
  AlarmRepository(this._prefs);

  static const _storageKey = 'alarms';
  final SharedPreferences _prefs;

  Future<List<Alarm>> fetchAlarms() async {
    final stored = _prefs.getString(_storageKey);
    if (stored == null) {
      return [];
    }
    final decoded = jsonDecode(stored) as List<dynamic>;
    return decoded
        .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAlarms(List<Alarm> alarms) async {
    final encoded = jsonEncode(alarms.map((e) => e.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
