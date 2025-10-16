import 'package:flutter_test/flutter_test.dart';

import 'package:rise_unplugged/features/sleep_debt/models/sleep_persona.dart';

void main() {
  group('SleepPersona', () {
    test('serialises and deserialises correctly', () {
      const persona = SleepPersona(
        chronotype: SleepChronotype.sunriseSeeker,
        challenge: WakeChallenge.heavySleeper,
        morningFocus: MorningFocus.productivityBoost,
      );

      final json = persona.toJson();
      final restored = SleepPersona.fromJson(json);

      expect(restored.chronotype, SleepChronotype.sunriseSeeker);
      expect(restored.challenge, WakeChallenge.heavySleeper);
      expect(restored.morningFocus, MorningFocus.productivityBoost);
    });

    test('provides friendly labels and suggestions', () {
      final chronotype = SleepChronotype.nightNavigator;
      final challenge = WakeChallenge.snoozeProne;
      final focus = MorningFocus.energisedStart;

      expect(chronotype.label, contains('navigator'));
      expect(chronotype.summary, contains('focus later'));
      expect(challenge.label, contains('snooze'));
      expect(challenge.insight, contains('movement'));
      expect(focus.label, contains('Energised'));
      expect(focus.ritualSuggestion, contains('movement'));
    });
  });
}
