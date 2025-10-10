import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/utils/feature_flags.dart';

class BackgroundTaskService {
  BackgroundTaskService(this._prefs);

  static const _gentleWakeKey = 'gentle_wake';

  final SharedPreferences _prefs;

  Future<void> configureGentleWake(bool enabled) async {
    await _prefs.setBool(_gentleWakeKey, enabled);
  }

  bool isGentleWakeEnabled() => _prefs.getBool(_gentleWakeKey) ?? true;

  Future<void> scheduleDailyMaintenance() async {
    // This would be wired with android_alarm_manager or workmanager in production.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

final backgroundTaskServiceProvider =
    FutureProvider<BackgroundTaskService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final service = BackgroundTaskService(prefs);
  if (ref.read(featureFlagsProvider).enableAiInsights) {
    await service.scheduleDailyMaintenance();
  }
  return service;
});
