import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/utils/app_logger.dart';
import '../models/alarm.dart';

class AlarmRepository {
  AlarmRepository(this._prefs, this._logger);

  static const _storageKey = 'alarms_v2';
  static const _legacyStorageKey = 'alarms';
  static const _schemaVersion = 1;

  final SharedPreferences _prefs;
  final AppLogger _logger;

  Future<List<Alarm>> fetchAlarms() async {
    try {
      final stored = _prefs.getString(_storageKey);
      if (stored != null) {
        return _parsePayload(stored);
      }

      final legacy = _prefs.getString(_legacyStorageKey);
      if (legacy != null) {
        _logger.info('Migrating legacy alarm payload to schema v$_schemaVersion');
        final alarms = _decodeLegacy(legacy);
        await saveAlarms(alarms);
        await _prefs.remove(_legacyStorageKey);
        return alarms;
      }

      return [];
    } catch (error, stackTrace) {
      _logger.error('Failed to load stored alarms', error, stackTrace);
      return [];
    }
  }

  Future<void> saveAlarms(List<Alarm> alarms) async {
    final payload = {
      'version': _schemaVersion,
      'alarms': alarms.map((alarm) => alarm.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _prefs.setString(_storageKey, jsonEncode(payload));
  }

  List<Alarm> _parsePayload(String stored) {
    final decoded = jsonDecode(stored);
    if (decoded is List) {
      // Guard for pre-schema saves that might still exist.
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Alarm.fromJson)
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      final version = decoded['version'] as int? ?? 0;
      if (version > _schemaVersion) {
        _logger.warning('Encountered newer alarm schema version: $version');
      }
      final payload = decoded['alarms'];
      if (payload is List<dynamic>) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(Alarm.fromJson)
            .toList();
      }
    }
    _logger.warning('Unable to parse stored alarms payload: $decoded');
    return [];
  }

  List<Alarm> _decodeLegacy(String stored) {
    final decoded = jsonDecode(stored) as List<dynamic>;
    return decoded
        .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
