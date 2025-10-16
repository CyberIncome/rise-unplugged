import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rise_unplugged/features/alarms/models/alarm.dart';
import 'package:rise_unplugged/features/alarms/services/alarm_repository.dart';
import 'package:rise_unplugged/shared/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('returns empty list when nothing stored', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = AlarmRepository(prefs, const AppLogger());

    final alarms = await repository.fetchAlarms();

    expect(alarms, isEmpty);
  });

  test('migrates legacy payload and removes old key', () async {
    final alarm = Alarm(
      label: 'Legacy',
      scheduledTime: DateTime(2030, 1, 1, 7, 30),
    );
    final legacy = jsonEncode([alarm.toJson()]);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'alarms': legacy,
    });
    final prefs = await SharedPreferences.getInstance();
    final repository = AlarmRepository(prefs, const AppLogger());

    final restored = await repository.fetchAlarms();

    expect(restored, hasLength(1));
    expect(restored.first.label, 'Legacy');
    expect(prefs.getString('alarms'), isNull);
  });

  test('persists alarms with schema wrapper', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = AlarmRepository(prefs, const AppLogger());
    final alarm = Alarm(
      label: 'Structured',
      scheduledTime: DateTime(2035, 5, 5, 6, 45),
    );

    await repository.saveAlarms([alarm]);

    final stored = prefs.getString('alarms_v2');
    expect(stored, isNotNull);
    final decoded = jsonDecode(stored!) as Map<String, dynamic>;
    expect(decoded['version'], equals(1));
    expect(decoded['alarms'], isA<List<dynamic>>());
    final restored = await repository.fetchAlarms();
    expect(restored.single.label, 'Structured');
  });

  test('gracefully handles corrupted payloads', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'alarms_v2': '{not json',
    });
    final prefs = await SharedPreferences.getInstance();
    final repository = AlarmRepository(prefs, const AppLogger());

    final restored = await repository.fetchAlarms();

    expect(restored, isEmpty);
  });
}
