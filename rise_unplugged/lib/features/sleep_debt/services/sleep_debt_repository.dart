import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sleep_persona.dart';
import '../models/sleep_session.dart';

class SleepDebtRepository {
  SleepDebtRepository(this._prefs);

  static const _sessionsKey = 'sleep_sessions';
  static const _goalKey = 'sleep_goal_minutes';
  static const _tooltipsKey = 'sleep_tooltips';
  static const _personaKey = 'sleep_persona';
  static const _digestKey = 'sleep_weekly_digest_enabled';

  final SharedPreferences _prefs;

  Future<List<SleepSession>> loadSessions() async {
    final stored = _prefs.getString(_sessionsKey);
    if (stored == null) {
      return [];
    }
    final decoded = jsonDecode(stored) as List<dynamic>;
    return decoded
        .map((e) => SleepSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSessions(List<SleepSession> sessions) async {
    final encoded = jsonEncode(sessions.map((e) => e.toJson()).toList());
    await _prefs.setString(_sessionsKey, encoded);
  }

  Future<Duration> loadGoal(Duration fallback) async {
    final minutes = _prefs.getInt(_goalKey);
    if (minutes == null) {
      return fallback;
    }
    return Duration(minutes: minutes);
  }

  Future<void> saveGoal(Duration goal) async {
    await _prefs.setInt(_goalKey, goal.inMinutes);
  }

  Future<Set<String>> loadTooltips() async {
    final stored = _prefs.getStringList(_tooltipsKey) ?? <String>[];
    return stored.toSet();
  }

  Future<void> saveTooltips(Set<String> tooltips) async {
    await _prefs.setStringList(_tooltipsKey, tooltips.toList());
  }

  Future<SleepPersona?> loadPersona() async {
    final stored = _prefs.getString(_personaKey);
    if (stored == null) {
      return null;
    }
    final decoded = jsonDecode(stored) as Map<String, dynamic>;
    return SleepPersona.fromJson(decoded);
  }

  Future<void> savePersona(SleepPersona persona) async {
    await _prefs.setString(_personaKey, jsonEncode(persona.toJson()));
  }

  Future<bool> loadWeeklyDigestEnabled(bool fallback) async {
    return _prefs.getBool(_digestKey) ?? fallback;
  }

  Future<void> saveWeeklyDigestEnabled(bool enabled) async {
    await _prefs.setBool(_digestKey, enabled);
  }
}
