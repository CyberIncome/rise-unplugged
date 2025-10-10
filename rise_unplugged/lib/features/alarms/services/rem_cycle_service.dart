import 'package:collection/collection.dart';

import '../models/alarm.dart';

class RemCycleService {
  const RemCycleService({this.cycleLength = const Duration(minutes: 90)});

  final Duration cycleLength;

  List<DateTime> recommendedWakeTimes({
    required DateTime targetWake,
    int cycles = 4,
  }) {
    return List.generate(
            cycles, (index) => targetWake.subtract(cycleLength * (index + 1)))
        .sorted((a, b) => a.compareTo(b));
  }

  Duration? bestSmartWindow(DateTime bedtime, DateTime targetWake,
      {int minimumCycles = 3}) {
    final difference = targetWake.difference(bedtime);
    final cycles = difference.inMinutes ~/ cycleLength.inMinutes;
    if (cycles < minimumCycles) {
      return null;
    }
    final remainderMinutes = difference.inMinutes % cycleLength.inMinutes;
    return Duration(minutes: remainderMinutes.clamp(10, 45));
  }

  Alarm applySmartWindow(Alarm alarm, DateTime bedtime) {
    final window = bestSmartWindow(bedtime, alarm.scheduledTime);
    if (window == null) {
      return alarm;
    }
    return alarm.copyWith(smartWakeWindow: window);
  }
}
