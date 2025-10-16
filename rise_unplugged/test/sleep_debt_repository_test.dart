import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rise_unplugged/features/sleep_debt/models/sleep_persona.dart';
import 'package:rise_unplugged/features/sleep_debt/models/sleep_session.dart';
import 'package:rise_unplugged/features/sleep_debt/services/sleep_debt_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and loads sleep sessions and goals', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = SleepDebtRepository(prefs);
    final sessions = [
      SleepSession(
        start: DateTime(2024, 1, 1, 22),
        end: DateTime(2024, 1, 2, 6),
      ),
    ];

    await repository.saveSessions(sessions);
    await repository.saveGoal(const Duration(hours: 7));

    final loadedSessions = await repository.loadSessions();
    final goal = await repository.loadGoal(const Duration(hours: 8));

    expect(loadedSessions, sessions);
    expect(goal, const Duration(hours: 7));
  });

  test('persists persona preferences and weekly digest flag', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = SleepDebtRepository(prefs);
    final persona = SleepPersona(
      chronotype: SleepChronotype.steadyRiser,
      challenge: WakeChallenge.snoozeProne,
      morningFocus: MorningFocus.calmReset,
    );

    expect(await repository.loadPersona(), isNull);
    expect(await repository.loadWeeklyDigestEnabled(false), isFalse);

    await repository.savePersona(persona);
    await repository.saveWeeklyDigestEnabled(true);

    final restoredPersona = await repository.loadPersona();
    final digestEnabled = await repository.loadWeeklyDigestEnabled(false);

    expect(restoredPersona?.chronotype, SleepChronotype.steadyRiser);
    expect(restoredPersona?.challenge, WakeChallenge.snoozeProne);
    expect(restoredPersona?.morningFocus, MorningFocus.calmReset);
    expect(digestEnabled, isTrue);
  });
}
