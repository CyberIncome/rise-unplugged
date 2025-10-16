import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';
import '../models/alarm_mission.dart';
import '../models/follow_up_alarm.dart';
import '../models/ringtone.dart';
import '../services/alarm_mission_catalog.dart';
import '../services/alarm_repository.dart';
import '../services/alarm_scheduler.dart';
import '../services/notifications_adapter.dart';
import '../services/rem_cycle_service.dart';
import '../../../shared/utils/app_logger.dart';
import '../../sleep_debt/providers/sleep_debt_provider.dart';

final alarmSchedulerProvider = Provider<AlarmScheduler>((ref) {
  final plugin = FlutterLocalNotificationsPlugin();
  final adapter = FlutterLocalNotificationsAdapter(plugin);
  final logger = ref.watch(appLoggerProvider);
  return AlarmScheduler(adapter, logger);
});

final alarmRepositoryProvider = FutureProvider<AlarmRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final logger = ref.read(appLoggerProvider);
  return AlarmRepository(prefs, logger);
});

final alarmScheduleProvider =
    AsyncNotifierProvider<AlarmScheduleNotifier, List<Alarm>>(
  AlarmScheduleNotifier.new,
);

class AlarmScheduleNotifier extends AsyncNotifier<List<Alarm>> {
  AlarmScheduler get _scheduler => ref.read(alarmSchedulerProvider);

  Future<AlarmRepository> get _repository =>
      ref.read(alarmRepositoryProvider.future);

  @override
  Future<List<Alarm>> build() async {
    final repository = await _repository;
    final stored = await repository.fetchAlarms();
    if (stored.isNotEmpty) {
      await _rescheduleAll(stored);
    }
    return stored;
  }

  Future<void> bootstrap() async {
    try {
      state = const AsyncValue.loading();
      final repository = await _repository;
      final stored = await repository.fetchAlarms();
      if (stored.isNotEmpty) {
        state = AsyncValue.data(stored);
        await _rescheduleAll(stored);
        return;
      }

      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, 7);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      final defaultAlarm = Alarm(
        label: 'Morning rise',
        scheduledTime: scheduled,
        followUps: const [
          FollowUpAlarm(
            delay: Duration(minutes: 10),
            message: 'Time to stretch and shine!',
            recommendation: 'Stand up, hydrate, and open the blinds.',
          ),
          FollowUpAlarm(
            delay: Duration(minutes: 20),
            message: 'Last call to stay on track!',
            recommendation: 'Review today\'s intention in the Rise brief.',
          ),
        ],
        mission: AlarmMissionCatalog.defaultMission,
      );
      final alarms = [defaultAlarm];
      state = AsyncValue.data(alarms);
      await repository.saveAlarms(alarms);
      await _schedule(defaultAlarm);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addAlarm({
    required String label,
    required TimeOfDay time,
    List<FollowUpAlarm> followUps = const [],
    Duration? smartWakeWindow,
    Ringtone? ringtone,
    AlarmMission? mission,
  }) async {
    try {
      final date = _nextOccurrence(time);
      final alarm = Alarm(
        label: label,
        scheduledTime: date,
        followUps: followUps,
        smartWakeWindow: smartWakeWindow,
        ringtone: ringtone ?? const Ringtone.defaultTone(),
        mission: mission,
      );
      final alarms = [..._currentAlarms(), alarm];
      state = AsyncValue.data(alarms);
      await _persist(alarms);
      await _schedule(alarm);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAlarm(Alarm alarm) async {
    try {
      final alarms = [..._currentAlarms()];
      final index = alarms.indexWhere((element) => element.id == alarm.id);
      if (index == -1) {
        return;
      }
      final previous = alarms[index];
      alarms[index] = alarm;
      state = AsyncValue.data(alarms);
      await _persist(alarms);
      await _scheduler.cancelAlarm(previous);
      await _schedule(alarm);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeAlarm(Alarm alarm) async {
    try {
      final alarms = [..._currentAlarms()]
        ..removeWhere((element) => element.id == alarm.id);
      state = AsyncValue.data(alarms);
      await _persist(alarms);
      await _scheduler.cancelAlarm(alarm);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleAlarm(Alarm alarm, bool enabled) async {
    final updated = alarm.copyWith(enabled: enabled);
    await updateAlarm(updated);
    if (!enabled) {
      await _scheduler.cancelAlarm(alarm);
    }
  }

  Future<void> applyRemSuggestion(Alarm alarm, DateTime bedtime) async {
    const remService = RemCycleService();
    final updated = remService.applySmartWindow(alarm, bedtime);
    await updateAlarm(updated);
  }

  Future<void> _persist(List<Alarm> alarms) async {
    final repository = await _repository;
    await repository.saveAlarms(alarms);
  }

  Future<void> _schedule(Alarm alarm) async {
    if (!alarm.enabled) return;
    await _scheduler.scheduleAlarm(alarm);
    await ref.read(sleepDebtProvider.notifier).recordUpcomingAlarm(alarm);
  }

  Future<void> _rescheduleAll(List<Alarm> alarms) async {
    for (final alarm in alarms) {
      if (alarm.enabled) {
        await _scheduler.scheduleAlarm(alarm);
      }
    }
  }

  DateTime _nextOccurrence(TimeOfDay time) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  List<Alarm> _currentAlarms() => state.value ?? const <Alarm>[];
}
