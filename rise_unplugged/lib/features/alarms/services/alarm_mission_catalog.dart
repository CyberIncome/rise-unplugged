import '../models/alarm_mission.dart';

class AlarmMissionCatalog {
  const AlarmMissionCatalog._();

  static const AlarmMission defaultMission = AlarmMission(
    type: AlarmMissionType.breathwork,
    difficulty: AlarmMissionDifficulty.focused,
    name: 'Mindful breathing check-in',
    description:
        'Complete four deep breaths to steady your nervous system before starting your day.',
    target: 4,
  );

  static List<AlarmMission> missionsForDifficulty(
    AlarmMissionDifficulty difficulty,
  ) {
    return AlarmMissionType.values
        .map((type) => buildMission(type: type, difficulty: difficulty))
        .toList(growable: false);
  }

  static AlarmMission buildMission({
    required AlarmMissionType type,
    AlarmMissionDifficulty difficulty = AlarmMissionDifficulty.focused,
  }) {
    switch (type) {
      case AlarmMissionType.breathwork:
        final target = switch (difficulty) {
          AlarmMissionDifficulty.gentle => 3,
          AlarmMissionDifficulty.focused => 4,
          AlarmMissionDifficulty.intense => 5,
        };
        return AlarmMission(
          type: type,
          difficulty: difficulty,
          name: 'Mindful breathing check-in',
          description:
              'Complete $target deep belly breaths, inhaling for four counts and exhaling for six.',
          target: target,
        );
      case AlarmMissionType.mathQuiz:
        final description = switch (difficulty) {
          AlarmMissionDifficulty.gentle =>
            'Solve a two-step addition problem to prove you are alert.',
          AlarmMissionDifficulty.focused =>
            'Answer a mixed addition and subtraction challenge to clear the fog.',
          AlarmMissionDifficulty.intense =>
            'Tackle a multiplication or division problem to kickstart your focus.',
        };
        return AlarmMission(
          type: type,
          difficulty: difficulty,
          name: 'Brainy math wake-up',
          description: description,
          target: 1,
        );
      case AlarmMissionType.focusTap:
        final target = switch (difficulty) {
          AlarmMissionDifficulty.gentle => 3,
          AlarmMissionDifficulty.focused => 4,
          AlarmMissionDifficulty.intense => 5,
        };
        return AlarmMission(
          type: type,
          difficulty: difficulty,
          name: 'Focus pattern taps',
          description:
              'Tap the numbers in ascending order to activate hand-eye coordination.',
          target: target,
        );
    }
  }
}
