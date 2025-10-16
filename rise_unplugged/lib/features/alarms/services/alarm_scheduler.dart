import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../shared/utils/app_logger.dart';
import 'notifications_adapter.dart';
import '../models/alarm.dart';
import '../models/follow_up_alarm.dart';

class AlarmScheduler {
  AlarmScheduler(this._notifications, this._logger);

  final NotificationsAdapter _notifications;
  final AppLogger _logger;

  Completer<void>? _initialization;

  Future<void> ensureInitialized() {
    final existing = _initialization;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<void>();
    _initialization = completer;
    _notifications
        .initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(requestSoundPermission: true),
          ),
        )
        .then(completer.complete)
        .catchError((Object error, StackTrace stackTrace) {
      _logger.error('Failed to initialize local notifications', error, stackTrace);
      _initialization = null;
      completer.completeError(error, stackTrace);
    });

    return completer.future;
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    await ensureInitialized();
    await _schedulePrimaryAlarm(alarm);
    for (final followUp in alarm.followUps) {
      await _scheduleFollowUp(alarm, followUp);
    }
  }

  Future<void> cancelAlarm(Alarm alarm) async {
    await ensureInitialized();
    await _notifications.cancel(_primaryId(alarm));
    for (final followUp in alarm.followUps) {
      await _notifications.cancel(_followUpId(alarm, followUp));
    }
  }

  Future<void> _schedulePrimaryAlarm(Alarm alarm) async {
    final scheduled = _toTz(alarm.scheduledTime);
    final missionBody = alarm.mission?.description;
    await _notifications.scheduleZoned(
      id: _primaryId(alarm),
      title: alarm.label,
      body: missionBody ?? 'Good morning! Your day is ready to begin.',
      scheduledDate: scheduled,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarms',
          'Morning Alarms',
          channelDescription: 'Smart alarm notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('sunrise'),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: alarm.id,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleFollowUp(Alarm alarm, FollowUpAlarm followUp) async {
    final scheduled = _toTz(alarm.scheduledTime.add(followUp.delay));
    await _notifications.scheduleZoned(
      id: _followUpId(alarm, followUp),
      title: followUp.message,
      body: followUp.recommendation ??
          'Take a stretch and hydrate to shake off sleep inertia.',
      scheduledDate: scheduled,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'follow_ups',
          'Follow-up Alarms',
          channelDescription: 'Gentle nudges after the main alarm',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: alarm.id,
      matchDateTimeComponents: null,
    );
  }

  int _primaryId(Alarm alarm) => alarm.id.hashCode;

  int _followUpId(Alarm alarm, FollowUpAlarm followUp) =>
      Object.hash(alarm.id, followUp.delay.inMinutes, followUp.message);

  tz.TZDateTime _toTz(DateTime dateTime) {
    final location = tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }
}
