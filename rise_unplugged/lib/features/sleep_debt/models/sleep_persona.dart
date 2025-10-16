import 'package:flutter/material.dart';

enum SleepChronotype {
  sunriseSeeker,
  steadyRiser,
  nightNavigator,
}

enum WakeChallenge {
  quickStarter,
  snoozeProne,
  heavySleeper,
}

enum MorningFocus {
  calmReset,
  energisedStart,
  productivityBoost,
}

class SleepPersona {
  const SleepPersona({
    required this.chronotype,
    required this.challenge,
    required this.morningFocus,
    this.lastUpdated,
  });

  final SleepChronotype chronotype;
  final WakeChallenge challenge;
  final MorningFocus morningFocus;
  final DateTime? lastUpdated;

  SleepPersona copyWith({
    SleepChronotype? chronotype,
    WakeChallenge? challenge,
    MorningFocus? morningFocus,
    DateTime? lastUpdated,
  }) {
    return SleepPersona(
      chronotype: chronotype ?? this.chronotype,
      challenge: challenge ?? this.challenge,
      morningFocus: morningFocus ?? this.morningFocus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chronotype': chronotype.name,
      'challenge': challenge.name,
      'morningFocus': morningFocus.name,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory SleepPersona.fromJson(Map<String, dynamic> json) {
    return SleepPersona(
      chronotype: SleepChronotype.values.firstWhere(
        (value) => value.name == json['chronotype'],
        orElse: () => SleepChronotype.steadyRiser,
      ),
      challenge: WakeChallenge.values.firstWhere(
        (value) => value.name == json['challenge'],
        orElse: () => WakeChallenge.snoozeProne,
      ),
      morningFocus: MorningFocus.values.firstWhere(
        (value) => value.name == json['morningFocus'],
        orElse: () => MorningFocus.calmReset,
      ),
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.tryParse(json['lastUpdated'] as String),
    );
  }
}

extension SleepChronotypeDescription on SleepChronotype {
  String get label {
    switch (this) {
      case SleepChronotype.sunriseSeeker:
        return 'Sunrise seeker';
      case SleepChronotype.steadyRiser:
        return 'Steady riser';
      case SleepChronotype.nightNavigator:
        return 'Night navigator';
    }
  }

  String get summary {
    switch (this) {
      case SleepChronotype.sunriseSeeker:
        return 'Naturally alert early and most energised before noon.';
      case SleepChronotype.steadyRiser:
        return 'Hits a groove mid-morning with balanced energy across the day.';
      case SleepChronotype.nightNavigator:
        return 'Finds focus later in the day and prefers a gradual morning ramp.';
    }
  }

  TimeOfDay get idealLightsOut {
    switch (this) {
      case SleepChronotype.sunriseSeeker:
        return const TimeOfDay(hour: 21, minute: 45);
      case SleepChronotype.steadyRiser:
        return const TimeOfDay(hour: 22, minute: 30);
      case SleepChronotype.nightNavigator:
        return const TimeOfDay(hour: 23, minute: 15);
    }
  }
}

extension WakeChallengeDescription on WakeChallenge {
  String get label {
    switch (this) {
      case WakeChallenge.quickStarter:
        return 'I wake easily but drift';
      case WakeChallenge.snoozeProne:
        return 'I always snooze';
      case WakeChallenge.heavySleeper:
        return 'I sleep through alarms';
    }
  }

  String get insight {
    switch (this) {
      case WakeChallenge.quickStarter:
        return 'Try anchoring a fast journaling cue to stay upright after wake.';
      case WakeChallenge.snoozeProne:
        return 'Line up a mission combo that forces movement within 60 seconds.';
      case WakeChallenge.heavySleeper:
        return 'Lean on louder alarms and multi-step missions to break inertia.';
    }
  }
}

extension MorningFocusDescription on MorningFocus {
  String get label {
    switch (this) {
      case MorningFocus.calmReset:
        return 'Calm reset';
      case MorningFocus.energisedStart:
        return 'Energised start';
      case MorningFocus.productivityBoost:
        return 'Productivity boost';
    }
  }

  String get ritualSuggestion {
    switch (this) {
      case MorningFocus.calmReset:
        return 'Queue a breath-led unplug session with warm ambient soundscapes.';
      case MorningFocus.energisedStart:
        return 'Blend movement pulses or cold splash reminders into the unplug timer.';
      case MorningFocus.productivityBoost:
        return 'Review your Rise Brief checklist right after dismissal to channel focus.';
    }
  }
}
