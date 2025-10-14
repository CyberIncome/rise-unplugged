import 'package:shared_preferences/shared_preferences.dart';

import '../models/unplug_timer.dart';

class UnplugTimerRepository {
  UnplugTimerRepository(this._prefs);

  static const _durationKey = 'unplug_timer_duration';
  static const _verificationKey = 'unplug_timer_verification';
  static const _distractionKey = 'unplug_timer_distractions';
  static const _animationKey = 'unplug_timer_animation';

  final SharedPreferences _prefs;

  Future<UnplugTimerConfig> load() async {
    final minutes = _prefs.getInt(_durationKey) ?? 10;
    final requireVerification = _prefs.getBool(_verificationKey) ?? true;
    final blockDistractions = _prefs.getBool(_distractionKey) ?? false;
    final calmingAnimation =
        _prefs.getString(_animationKey) ?? 'assets/animations/sunrise.json';

    return UnplugTimerConfig(
      duration: Duration(minutes: minutes),
      requireVerification: requireVerification,
      blockDistractions: blockDistractions,
      calmingAnimation: calmingAnimation,
    );
  }

  Future<void> save(UnplugTimerConfig config) async {
    await _prefs.setInt(_durationKey, config.duration.inMinutes);
    await _prefs.setBool(_verificationKey, config.requireVerification);
    await _prefs.setBool(_distractionKey, config.blockDistractions);
    await _prefs.setString(_animationKey, config.calmingAnimation);
  }
}
