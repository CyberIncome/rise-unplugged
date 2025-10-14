import 'package:flutter_test/flutter_test.dart';

import 'package:rise_unplugged/features/alarms/models/alarm.dart';
import 'package:rise_unplugged/features/alarms/models/alarm_mission.dart';
import 'package:rise_unplugged/features/alarms/services/alarm_mission_catalog.dart';

void main() {
  test('Alarm mission serializes and deserializes accurately', () {
    final mission = AlarmMissionCatalog.buildMission(
      type: AlarmMissionType.mathQuiz,
      difficulty: AlarmMissionDifficulty.intense,
    );
    final json = mission.toJson();
    final restored = AlarmMission.fromJson(json);

    expect(restored, equals(mission));
    expect(restored.id, equals(mission.id));
  });

  test('Alarm persists mission payload in json', () {
    final mission = AlarmMissionCatalog.buildMission(
      type: AlarmMissionType.focusTap,
      difficulty: AlarmMissionDifficulty.focused,
    );
    final alarm = Alarm(
      label: 'Test',
      scheduledTime: DateTime(2030, 1, 1, 6, 30),
      mission: mission,
    );

    final restored = Alarm.fromJson(alarm.toJson());
    expect(restored.mission, equals(mission));
    expect(restored.mission?.target, equals(mission.target));
  });
}
