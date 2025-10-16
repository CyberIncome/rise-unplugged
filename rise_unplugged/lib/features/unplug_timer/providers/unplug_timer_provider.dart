import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/unplug_timer.dart';
import '../services/unplug_timer_repository.dart';

class UnplugTimerState {
  const UnplugTimerState({
    required this.config,
    this.remaining,
    this.isRunning = false,
    this.verificationPassed = false,
  });

  final UnplugTimerConfig config;
  final Duration? remaining;
  final bool isRunning;
  final bool verificationPassed;

  UnplugTimerState copyWith({
    UnplugTimerConfig? config,
    Duration? remaining,
    bool? isRunning,
    bool? verificationPassed,
  }) {
    return UnplugTimerState(
      config: config ?? this.config,
      remaining: remaining ?? this.remaining,
      isRunning: isRunning ?? this.isRunning,
      verificationPassed: verificationPassed ?? this.verificationPassed,
    );
  }
}

final unplugTimerRepositoryProvider =
    FutureProvider<UnplugTimerRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return UnplugTimerRepository(prefs);
});

final unplugTimerProvider =
    NotifierProvider<UnplugTimerNotifier, UnplugTimerState>(
  UnplugTimerNotifier.new,
);

class UnplugTimerNotifier extends Notifier<UnplugTimerState> {
  Timer? _timer;

  @override
  UnplugTimerState build() {
    unawaited(_load());
    ref.onDispose(() => _timer?.cancel());
    return const UnplugTimerState(
      config: UnplugTimerConfig(duration: Duration(minutes: 10)),
    );
  }

  Future<void> _load() async {
    final repository = await ref.read(unplugTimerRepositoryProvider.future);
    final config = await repository.load();
    state = state.copyWith(config: config);
  }

  Future<void> configure(UnplugTimerConfig config) async {
    state = state.copyWith(config: config);
    await _persist(config);
  }

  void start() {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: true,
      remaining: state.config.duration,
      verificationPassed: !state.config.requireVerification,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.remaining?.inSeconds ?? 0;
      if (remaining <= 1) {
        timer.cancel();
        state = state.copyWith(isRunning: false, remaining: Duration.zero);
      } else {
        state = state.copyWith(remaining: Duration(seconds: remaining - 1));
      }
    });
  }

  void verifyWake() {
    state = state.copyWith(verificationPassed: true);
  }

  void stop() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, remaining: Duration.zero);
  }

  Future<void> _persist(UnplugTimerConfig config) async {
    final repository = await ref.read(unplugTimerRepositoryProvider.future);
    await repository.save(config);
  }
}
