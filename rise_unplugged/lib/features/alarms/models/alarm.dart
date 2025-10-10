import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'alarm_mission.dart';
import 'follow_up_alarm.dart';
import 'ringtone.dart';

enum AlarmStatus { scheduled, dismissed, ringing, skipped }

typedef AlarmId = String;

class Alarm {
  Alarm({
    AlarmId? id,
    required this.label,
    required this.scheduledTime,
    this.followUps = const [],
    this.ringtone = const Ringtone.defaultTone(),
    this.smartWakeWindow,
    this.status = AlarmStatus.scheduled,
    this.enabled = true,
    DateTime? createdAt,
    this.mission,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final AlarmId id;
  final String label;
  final DateTime scheduledTime;
  final List<FollowUpAlarm> followUps;
  final Ringtone ringtone;
  final Duration? smartWakeWindow;
  final AlarmStatus status;
  final bool enabled;
  final DateTime createdAt;
  final AlarmMission? mission;

  Alarm copyWith({
    AlarmId? id,
    String? label,
    DateTime? scheduledTime,
    List<FollowUpAlarm>? followUps,
    Ringtone? ringtone,
    Duration? smartWakeWindow,
    AlarmStatus? status,
    bool? enabled,
    DateTime? createdAt,
    AlarmMission? mission,
    bool clearMission = false,
  }) {
    return Alarm(
      id: id ?? this.id,
      label: label ?? this.label,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      followUps: followUps ?? this.followUps,
      ringtone: ringtone ?? this.ringtone,
      smartWakeWindow: smartWakeWindow ?? this.smartWakeWindow,
      status: status ?? this.status,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      mission: clearMission ? null : mission ?? this.mission,
    );
  }

  TimeOfDay get timeOfDay => TimeOfDay.fromDateTime(scheduledTime);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'scheduledTime': scheduledTime.toIso8601String(),
      'followUps': followUps.map((e) => e.toJson()).toList(),
      'ringtone': ringtone.toJson(),
      'smartWakeWindow': smartWakeWindow?.inMinutes,
      'status': status.name,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'mission': mission?.toJson(),
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String?,
      label: json['label'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      followUps: (json['followUps'] as List<dynamic>? ?? [])
          .map((e) => FollowUpAlarm.fromJson(e as Map<String, dynamic>))
          .toList(),
      ringtone: Ringtone.fromJson(json['ringtone'] as Map<String, dynamic>),
      smartWakeWindow: (json['smartWakeWindow'] as int?)?.let(
        (minutes) => Duration(minutes: minutes),
      ),
      status: AlarmStatus.values.firstWhere(
        (element) => element.name == json['status'],
        orElse: () => AlarmStatus.scheduled,
      ),
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      mission: (json['mission'] as Map<String, dynamic>?)?.let(
        AlarmMission.fromJson,
      ),
    );
  }
}

extension<T> on T? {
  R? let<R>(R Function(T value) transform) {
    final self = this;
    if (self == null) return null;
    return transform(self);
  }
}
