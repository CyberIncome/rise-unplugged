import 'package:flutter/foundation.dart';

enum AlarmMissionType {
  breathwork,
  mathQuiz,
  focusTap,
  affirmation,
  barcodeScan,
  photoProof,
  stepCounter,
  memoryGrid,
  breathAndAffirm,
}

enum AlarmMissionDifficulty { gentle, focused, intense }

@immutable
class AlarmMission {
  const AlarmMission({
    required this.type,
    required this.difficulty,
    required this.name,
    required this.description,
    this.target = 1,
    this.cues = const <String>[],
  });

  final AlarmMissionType type;
  final AlarmMissionDifficulty difficulty;
  final String name;
  final String description;
  final int target;
  final List<String> cues;

  String get id => '${type.name}:${difficulty.name}:$target';

  AlarmMission copyWith({
    AlarmMissionType? type,
    AlarmMissionDifficulty? difficulty,
    String? name,
    String? description,
    int? target,
    List<String>? cues,
  }) {
    return AlarmMission(
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      name: name ?? this.name,
      description: description ?? this.description,
      target: target ?? this.target,
      cues: cues ?? this.cues,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'difficulty': difficulty.name,
      'name': name,
      'description': description,
      'target': target,
      'cues': cues,
    };
  }

  factory AlarmMission.fromJson(Map<String, dynamic> json) {
    return AlarmMission(
      type: AlarmMissionType.values.firstWhere(
        (element) => element.name == json['type'],
        orElse: () => AlarmMissionType.breathwork,
      ),
      difficulty: AlarmMissionDifficulty.values.firstWhere(
        (element) => element.name == json['difficulty'],
        orElse: () => AlarmMissionDifficulty.focused,
      ),
      name: json['name'] as String? ?? 'Mindful breathing',
      description: json['description'] as String? ??
          'Complete a few deep breaths to prove you are awake and grounded.',
      target: json['target'] as int? ?? 3,
      cues: (json['cues'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
    );
  }

  @override
  int get hashCode =>
      Object.hash(type, difficulty, name, description, target, Object.hashAll(cues));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlarmMission &&
        other.type == type &&
        other.difficulty == difficulty &&
        other.name == name &&
        other.description == description &&
        other.target == target &&
        listEquals(other.cues, cues);
  }
}

extension AlarmMissionDifficultyLabel on AlarmMissionDifficulty {
  String get label {
    switch (this) {
      case AlarmMissionDifficulty.gentle:
        return 'Gentle';
      case AlarmMissionDifficulty.focused:
        return 'Focused';
      case AlarmMissionDifficulty.intense:
        return 'Intense';
    }
  }
}
