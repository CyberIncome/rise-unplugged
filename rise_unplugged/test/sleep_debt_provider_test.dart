import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rise_unplugged/features/sleep_debt/models/sleep_persona.dart';
import 'package:rise_unplugged/features/sleep_debt/models/sleep_session.dart';
import 'package:rise_unplugged/features/sleep_debt/providers/sleep_debt_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('setPersona updates state and persists the timestamp', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(sleepDebtProvider.notifier);

    final persona = SleepPersona(
      chronotype: SleepChronotype.nightNavigator,
      challenge: WakeChallenge.quickStarter,
      morningFocus: MorningFocus.energisedStart,
    );

    await notifier.setPersona(persona);

    final state = container.read(sleepDebtProvider);
    expect(state.persona?.chronotype, SleepChronotype.nightNavigator);
    expect(state.persona?.lastUpdated, isNotNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sleep_persona'), isNotNull);
  });

  test('setWeeklyDigestEnabled toggles value and persists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(sleepDebtProvider.notifier);

    await notifier.setWeeklyDigestEnabled(true);
    expect(container.read(sleepDebtProvider).weeklyDigestEnabled, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sleep_weekly_digest_enabled'), isTrue);
  });

  test('addSession recalculates weekly debt', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(sleepDebtProvider.notifier);

    final now = DateTime.now();
    await notifier.addSession(
      SleepSession(
        start: now.subtract(const Duration(hours: 7)),
        end: now,
      ),
    );

    final state = container.read(sleepDebtProvider);
    expect(state.sessions, hasLength(1));
    expect(state.weeklyDebt.length, 7);
    expect(state.weeklyDebt.values.where((d) => d.inMinutes >= 0), isNotEmpty);
  });
}
