import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rise_unplugged/features/alarms/models/alarm.dart';
import 'package:rise_unplugged/features/alarms/models/follow_up_alarm.dart';
import 'package:rise_unplugged/features/alarms/services/alarm_scheduler.dart';
import 'package:rise_unplugged/features/alarms/services/notifications_adapter.dart';
import 'package:rise_unplugged/shared/utils/app_logger.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _FakeNotificationsAdapter implements NotificationsAdapter {
  int initializeCount = 0;
  final List<int> cancelled = <int>[];
  final List<_ScheduledCall> scheduled = <_ScheduledCall>[];

  @override
  Future<void> initialize({required InitializationSettings settings}) async {
    initializeCount++;
  }

  @override
  Future<void> scheduleZoned({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add(
      _ScheduledCall(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
        details: details,
        mode: androidScheduleMode,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }
}

class _ScheduledCall {
  _ScheduledCall({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.payload,
    required this.matchDateTimeComponents,
    required this.details,
    required this.mode,
  });

  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final String? payload;
  final DateTimeComponents? matchDateTimeComponents;
  final NotificationDetails details;
  final AndroidScheduleMode mode;
}

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  test('initializes notifications only once per lifecycle', () async {
    final adapter = _FakeNotificationsAdapter();
    final scheduler = AlarmScheduler(adapter, const AppLogger());
    final alarm = Alarm(
      label: 'Morning',
      scheduledTime: DateTime.now().add(const Duration(hours: 1)),
      followUps: const [
        FollowUpAlarm(
          delay: Duration(minutes: 10),
          message: 'Stretch',
        ),
      ],
    );

    await scheduler.scheduleAlarm(alarm);
    await scheduler.scheduleAlarm(alarm);

    expect(adapter.initializeCount, equals(1));
    expect(adapter.scheduled, hasLength(4));
    expect(adapter.scheduled.first.id, isNotNull);
    expect(adapter.scheduled.first.payload, equals(alarm.id));
  });

  test('cancels alarm and follow ups using consistent ids', () async {
    final adapter = _FakeNotificationsAdapter();
    final scheduler = AlarmScheduler(adapter, const AppLogger());
    final alarm = Alarm(
      label: 'Cancel me',
      scheduledTime: DateTime.now().add(const Duration(hours: 1)),
      followUps: const [
        FollowUpAlarm(
          delay: Duration(minutes: 15),
          message: 'Hydrate',
        ),
        FollowUpAlarm(
          delay: Duration(minutes: 30),
          message: 'Walk',
        ),
      ],
    );

    await scheduler.cancelAlarm(alarm);

    expect(adapter.cancelled, contains(alarm.id.hashCode));
    expect(adapter.cancelled.length, equals(1 + alarm.followUps.length));
  });
}
