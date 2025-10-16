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
    cues: [
      'Inhale through the nose for four counts',
      'Hold briefly, exhale for six counts',
      'Repeat slowly until the animation completes',
    ],
  );

  static const Map<AlarmMissionDifficulty, List<AlarmMissionType>> _difficultyCatalog =
      {
    AlarmMissionDifficulty.gentle: [
      AlarmMissionType.breathwork,
      AlarmMissionType.affirmation,
      AlarmMissionType.memoryGrid,
      AlarmMissionType.photoProof,
    ],
    AlarmMissionDifficulty.focused: [
      AlarmMissionType.breathwork,
      AlarmMissionType.focusTap,
      AlarmMissionType.mathQuiz,
      AlarmMissionType.barcodeScan,
      AlarmMissionType.breathAndAffirm,
    ],
    AlarmMissionDifficulty.intense: [
      AlarmMissionType.mathQuiz,
      AlarmMissionType.barcodeScan,
      AlarmMissionType.stepCounter,
      AlarmMissionType.photoProof,
      AlarmMissionType.breathAndAffirm,
    ],
  };

  static List<AlarmMission> missionsForDifficulty(
    AlarmMissionDifficulty difficulty,
  ) {
    final catalog = _difficultyCatalog[difficulty] ?? AlarmMissionType.values;
    return catalog
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
          cues: const [
            'Follow the on-screen breathing rhythm',
            'Keep shoulders relaxed',
            'Finish every breath even if the alarm stops early',
          ],
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
          cues: const [
            'Take a breath before answering',
            'You must solve correctly to end the alarm',
          ],
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
          cues: const [
            'Watch the pattern closely',
            'Taps reset if you miss the order',
          ],
        );
      case AlarmMissionType.affirmation:
        return AlarmMission(
          type: type,
          difficulty: difficulty,
          name: 'Voice your intention',
          description:
              'Record and repeat a personal affirmation to anchor your mood.',
          target: 1,
          cues: const [
            'Speak clearly into the microphone',
            'Commit to the phrase before you dismiss the alarm',
          ],
        );
      case AlarmMissionType.barcodeScan:
        return AlarmMission(
          type: type,
          difficulty: difficulty,
          name: 'Scan to start moving',
          description:
              'Get out of bed and scan a preselected barcode to prove you are up.',
          target: 1,
          cues: const [
            'Choose a code far from the bed (like your kitchen coffee tin)',
            'Line up the camera with the barcode until it confirms the scan',
          ],
        );
      case AlarmMissionType.photoProof:
        return AlarmMission(
          type: type,
          difficulty: difficulty,
          name: 'Capture morning light',
          description:
              'Take a well-lit photo of a morning checkpoint to show you are moving.',
          target: 1,
          cues: const [
            'Stand near a window or lamp for clear lighting',
            'Ensure the subject fills the frame to complete the task',
          ],
        );
      case AlarmMissionType.stepCounter:
        final target = switch (difficulty) {
          AlarmMissionDifficulty.gentle => 20,
          AlarmMissionDifficulty.focused => 40,
          AlarmMissionDifficulty.intense => 60,
        };
        return AlarmMission(
          type: type,
          difficulty: difficulty,
          name: 'Morning steps challenge',
          description:
              'Walk around your space until you reach the step target to rev up circulation.',
          target: target,
          cues: const [
            'Keep your phone or wearable with you to track motion',
            'Short, brisk steps count—just keep moving until you finish',
          ],
        );
      case AlarmMissionType.memoryGrid:
        final target = switch (difficulty) {
          AlarmMissionDifficulty.gentle => 2,
          AlarmMissionDifficulty.focused => 3,
          AlarmMissionDifficulty.intense => 4,
        };
        return AlarmMission(
          type: type,
          difficulty: difficulty,
          name: 'Memory grid recall',
          description:
              'Memorize the highlighted tiles and tap them back in order to prove your focus.',
          target: target,
          cues: const [
            'Study the grid carefully before it hides',
            'A wrong tile will reset the pattern',
          ],
        );
      case AlarmMissionType.breathAndAffirm:
        final breaths = switch (difficulty) {
          AlarmMissionDifficulty.gentle => 2,
          AlarmMissionDifficulty.focused => 3,
          AlarmMissionDifficulty.intense => 4,
        };
        return AlarmMission(
          type: type,
          difficulty: difficulty,
          name: 'Breathe & affirm combo',
          description:
              'Blend calming breaths with a spoken affirmation to engage both body and mind.',
          target: breaths,
          cues: const [
            'Complete the guided breaths first',
            'Speak your affirmation with energy to finish',
          ],
        );
    }
  }
}
