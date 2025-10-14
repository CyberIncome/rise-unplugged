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
import '../services/rem_cycle_service.dart';
import '../../sleep_debt/providers/sleep_debt_provider.dart';

final alarmSchedulerProvider = Provider<AlarmScheduler>((ref) {
  final plugin = FlutterLocalNotificationsPlugin();
  return AlarmScheduler(plugin);
});

final alarmRepositoryProvider = FutureProvider<AlarmRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return AlarmRepository(prefs);
});

final alarmScheduleProvider =
    StateNotifierProvider<AlarmScheduleNotifier, AsyncValue<List<Alarm>>>(
  (ref) => AlarmScheduleNotifier(ref),
);

class AlarmScheduleNotifier extends StateNotifier<AsyncValue<List<Alarm>>> {
  AlarmScheduleNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  final Ref _ref;

  Future<void> _loadInitial() async {
    try {
      final repository = await _ref.read(alarmRepositoryProvider.future);
      final stored = await repository.fetchAlarms();
      state = AsyncValue.data(stored);
      if (stored.isNotEmpty) {
        await _rescheduleAll(stored);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> bootstrap() async {
    try {
      final repository = await _ref.read(alarmRepositoryProvider.future);
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
          ),
          FollowUpAlarm(
            delay: Duration(minutes: 20),
            message: 'Last call to stay on track!',
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
      await _ref.read(alarmSchedulerProvider).cancelAlarm(previous);
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
      await _ref.read(alarmSchedulerProvider).cancelAlarm(alarm);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleAlarm(Alarm alarm, bool enabled) async {
    final updated = alarm.copyWith(enabled: enabled);
    await updateAlarm(updated);
    if (!enabled) {
      await _ref.read(alarmSchedulerProvider).cancelAlarm(alarm);
    }
  }

  Future<void> applyRemSuggestion(Alarm alarm, DateTime bedtime) async {
    const remService = RemCycleService();
    final updated = remService.applySmartWindow(alarm, bedtime);
    await updateAlarm(updated);
  }

  Future<void> _persist(List<Alarm> alarms) async {
    final repository = await _ref.read(alarmRepositoryProvider.future);
    await repository.saveAlarms(alarms);
  }

  Future<void> _schedule(Alarm alarm) async {
    if (!alarm.enabled) return;
    await _ref.read(alarmSchedulerProvider).scheduleAlarm(alarm);
    await _ref.read(sleepDebtProvider.notifier).recordUpcomingAlarm(alarm);
  }

  Future<void> _rescheduleAll(List<Alarm> alarms) async {
    for (final alarm in alarms) {
      if (alarm.enabled) {
        await _ref.read(alarmSchedulerProvider).scheduleAlarm(alarm);
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

  List<Alarm> _currentAlarms() => state.value ?? <Alarm>[];
}
