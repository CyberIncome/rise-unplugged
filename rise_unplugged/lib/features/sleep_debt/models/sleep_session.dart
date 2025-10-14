class SleepSession {
  const SleepSession({
    required this.start,
    required this.end,
    this.source = SleepSessionSource.manual,
  });

  final DateTime start;
  final DateTime end;
  final SleepSessionSource source;

  Duration get duration => end.difference(start);

  SleepSession copyWith({
    DateTime? start,
    DateTime? end,
    SleepSessionSource? source,
  }) {
    return SleepSession(
      start: start ?? this.start,
      end: end ?? this.end,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'source': source.name,
    };
  }

  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      source: SleepSessionSource.values.firstWhere(
        (element) => element.name == json['source'],
        orElse: () => SleepSessionSource.manual,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepSession &&
        other.start == start &&
        other.end == end &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(start, end, source);
}

enum SleepSessionSource { manual, appleHealth, googleFit }
