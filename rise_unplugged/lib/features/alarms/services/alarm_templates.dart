import 'package:flutter/material.dart';

import '../models/alarm_mission.dart';
import '../models/follow_up_alarm.dart';
import '../models/ringtone.dart';
import 'alarm_mission_catalog.dart';

class AlarmTemplate {
  const AlarmTemplate({
    required this.name,
    required this.description,
    required this.recommendedLabel,
    required this.mission,
    this.recommendedTime,
    this.followUps = const <FollowUpAlarm>[],
    this.smartWindow,
    this.ringtone,
    this.tags = const <String>[],
  });

  final String name;
  final String description;
  final String recommendedLabel;
  final TimeOfDay? recommendedTime;
  final AlarmMission mission;
  final List<FollowUpAlarm> followUps;
  final Duration? smartWindow;
  final Ringtone? ringtone;
  final List<String> tags;
}

class AlarmTemplateCatalog {
  const AlarmTemplateCatalog._();

  static final List<AlarmTemplate> featured = [
    AlarmTemplate(
      name: 'Mindful Sunrise',
      description:
          'Begin with restorative breaths, then repeat your morning mantra before stepping into the day.',
      recommendedLabel: 'Mindful sunrise',
      recommendedTime: const TimeOfDay(hour: 6, minute: 30),
      mission: AlarmMissionCatalog.buildMission(
        type: AlarmMissionType.breathAndAffirm,
        difficulty: AlarmMissionDifficulty.focused,
      ),
      followUps: const [
        FollowUpAlarm(
          delay: Duration(minutes: 12),
          message: 'Time for light stretching and sunlight!',
          recommendation: 'Open the blinds and sip water.',
        ),
      ],
      smartWindow: const Duration(minutes: 25),
      ringtone: const Ringtone(
        assetPath: 'assets/ringtones/sunrise.mp3',
        name: 'Sunrise Drift',
      ),
      tags: const ['breath', 'mindset'],
    ),
    AlarmTemplate(
      name: 'Focus Launchpad',
      description:
          'Shake off the fog with a quick math burst and a hydration reminder to get you in motion.',
      recommendedLabel: 'Focus launchpad',
      recommendedTime: const TimeOfDay(hour: 7, minute: 0),
      mission: AlarmMissionCatalog.buildMission(
        type: AlarmMissionType.mathQuiz,
        difficulty: AlarmMissionDifficulty.intense,
      ),
      followUps: const [
        FollowUpAlarm(
          delay: Duration(minutes: 8),
          message: 'Pour a glass of water and review your top goal.',
          recommendation: 'Hydrate + peek at your task list.',
        ),
        FollowUpAlarm(
          delay: Duration(minutes: 18),
          message: 'Time-block your first deep work sprint.',
          recommendation: 'Open planner or focus playlist.',
        ),
      ],
      smartWindow: const Duration(minutes: 20),
      ringtone: const Ringtone(
        assetPath: 'assets/ringtones/forest.mp3',
        name: 'Forest Wake',
      ),
      tags: const ['focus', 'productivity'],
    ),
    AlarmTemplate(
      name: 'Movement Mission',
      description:
          'Get out of bed fast with a step challenge and accountability photo to keep momentum high.',
      recommendedLabel: 'Movement mission',
      recommendedTime: const TimeOfDay(hour: 5, minute: 55),
      mission: AlarmMissionCatalog.buildMission(
        type: AlarmMissionType.stepCounter,
        difficulty: AlarmMissionDifficulty.focused,
      ),
      followUps: const [
        FollowUpAlarm(
          delay: Duration(minutes: 5),
          message: 'Snap a sunrise or gym check-in pic.',
          recommendation: 'Share with your accountability buddy.',
        ),
        FollowUpAlarm(
          delay: Duration(minutes: 15),
          message: 'Prep a protein-rich breakfast.',
          recommendation: 'Keep your streak alive.',
        ),
      ],
      smartWindow: const Duration(minutes: 30),
      ringtone: const Ringtone(
        assetPath: 'assets/ringtones/tide.mp3',
        name: 'Ocean Tide',
      ),
      tags: const ['movement', 'accountability'],
    ),
  ];
}
