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
    expect(restored.cues, equals(mission.cues));
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
    expect(restored.mission?.cues, equals(mission.cues));
  });

  test('Catalog returns curated missions per difficulty', () {
    final gentle = AlarmMissionCatalog.missionsForDifficulty(
      AlarmMissionDifficulty.gentle,
    );
    final focused = AlarmMissionCatalog.missionsForDifficulty(
      AlarmMissionDifficulty.focused,
    );
    final intense = AlarmMissionCatalog.missionsForDifficulty(
      AlarmMissionDifficulty.intense,
    );

    expect(gentle.map((mission) => mission.type), contains(AlarmMissionType.affirmation));
    expect(focused.map((mission) => mission.type), contains(AlarmMissionType.barcodeScan));
    expect(intense.map((mission) => mission.type), contains(AlarmMissionType.stepCounter));
    expect(intense.map((mission) => mission.type), isNot(contains(AlarmMissionType.memoryGrid)));
  });
}
