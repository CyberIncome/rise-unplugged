import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/health/health_integration_service.dart';
import '../../alarms/models/alarm.dart';
import '../models/sleep_session.dart';
import '../services/sleep_debt_repository.dart';

class SleepDebtState {
  const SleepDebtState({
    required this.sessions,
    required this.weeklyDebt,
    required this.goalPerNight,
    this.tooltipsSeen = const {},
  });

  final List<SleepSession> sessions;
  final Map<DateTime, Duration> weeklyDebt;
  final Duration goalPerNight;
  final Set<String> tooltipsSeen;

  SleepDebtState copyWith({
    List<SleepSession>? sessions,
    Map<DateTime, Duration>? weeklyDebt,
    Duration? goalPerNight,
    Set<String>? tooltipsSeen,
  }) {
    return SleepDebtState(
      sessions: sessions ?? this.sessions,
      weeklyDebt: weeklyDebt ?? this.weeklyDebt,
      goalPerNight: goalPerNight ?? this.goalPerNight,
      tooltipsSeen: tooltipsSeen ?? this.tooltipsSeen,
    );
  }
}

enum SleepImportResult { unavailable, permissionDenied, noData, imported }

final sleepDebtRepositoryProvider =
    FutureProvider<SleepDebtRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SleepDebtRepository(prefs);
});

final sleepDebtProvider =
    StateNotifierProvider<SleepDebtNotifier, SleepDebtState>((ref) {
  return SleepDebtNotifier(ref);
});

class SleepDebtNotifier extends StateNotifier<SleepDebtState> {
  SleepDebtNotifier(this._ref)
      : super(
          const SleepDebtState(
            sessions: [],
            weeklyDebt: {},
            goalPerNight: Duration(hours: 8),
          ),
        ) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final repository = await _ref.read(sleepDebtRepositoryProvider.future);
    final sessions = await repository.loadSessions();
    final goal = await repository.loadGoal(const Duration(hours: 8));
    final tooltips = await repository.loadTooltips();
    _recalculateState(sessions, goalPerNight: goal, tooltipsSeen: tooltips);
  }

  Future<void> addSession(SleepSession session) async {
    if (!session.end.isAfter(session.start)) {
      throw ArgumentError(
          'Sleep session end time must be after the start time.');
    }
    final updated = [...state.sessions, session];
    _recalculateState(updated);
    await _persistSessions();
  }

  Future<SleepImportResult> importFromHealth(
      HealthIntegrationService service) async {
    if (!await service.isAvailable()) {
      return SleepImportResult.unavailable;
    }
    if (!await service.requestPermissions()) {
      return SleepImportResult.permissionDenied;
    }
    final sessions = await service.fetchRecentSessions();
    if (sessions.isEmpty) {
      return SleepImportResult.noData;
    }
    final combined = {...state.sessions, ...sessions}.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    _recalculateState(combined);
    await _persistSessions();
    return SleepImportResult.imported;
  }

  Future<void> recordUpcomingAlarm(Alarm alarm) async {
    final recommendation = alarm.smartWakeWindow;
    if (recommendation == null) {
      return;
    }
    final tooltipKey = 'smart_window_${alarm.id}';
    if (state.tooltipsSeen.contains(tooltipKey)) {
      return;
    }
    final updated = {...state.tooltipsSeen}..add(tooltipKey);
    state = state.copyWith(tooltipsSeen: updated);
    await _persistTooltips();
  }

  void dismissTooltip(String key) {
    final updated = {...state.tooltipsSeen}..add(key);
    state = state.copyWith(tooltipsSeen: updated);
    unawaited(_persistTooltips());
  }

  Future<void> setGoalPerNight(Duration goal) async {
    _recalculateState(state.sessions, goalPerNight: goal);
    await _persistGoal();
  }

  void _recalculateState(
    List<SleepSession> sessions, {
    Duration? goalPerNight,
    Set<String>? tooltipsSeen,
  }) {
    final goal = goalPerNight ?? state.goalPerNight;
    final sortedSessions = [...sessions]
      ..sort((a, b) => a.start.compareTo(b.start));
    final grouped = groupBy(sortedSessions, (SleepSession session) {
      final date =
          DateTime(session.end.year, session.end.month, session.end.day);
      return date;
    });

    final weeklyDebt = <DateTime, Duration>{};
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final sessionsForDay = grouped[day] ?? [];
      final total = sessionsForDay.fold<Duration>(
          Duration.zero, (value, session) => value + session.duration);
      final debt = Duration(minutes: max(0, goal.inMinutes - total.inMinutes));
      weeklyDebt[day] = debt;
    }

    state = state.copyWith(
      sessions: sortedSessions,
      weeklyDebt: weeklyDebt,
      goalPerNight: goal,
      tooltipsSeen: tooltipsSeen ?? state.tooltipsSeen,
    );
  }

  Future<void> _persistSessions() async {
    final repository = await _ref.read(sleepDebtRepositoryProvider.future);
    await repository.saveSessions(state.sessions);
  }

  Future<void> _persistGoal() async {
    final repository = await _ref.read(sleepDebtRepositoryProvider.future);
    await repository.saveGoal(state.goalPerNight);
  }

  Future<void> _persistTooltips() async {
    final repository = await _ref.read(sleepDebtRepositoryProvider.future);
    await repository.saveTooltips(state.tooltipsSeen);
  }
}
