class Ringtone {
  const Ringtone({
    required this.assetPath,
    required this.name,
    this.loop = true,
  });

  const Ringtone.defaultTone()
      : assetPath = 'assets/ringtones/sunrise.mp3',
        name = 'Sunrise Drift',
        loop = true;

  final String assetPath;
  final String name;
  final bool loop;

  Ringtone copyWith({
    String? assetPath,
    String? name,
    bool? loop,
  }) {
    return Ringtone(
      assetPath: assetPath ?? this.assetPath,
      name: name ?? this.name,
      loop: loop ?? this.loop,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetPath': assetPath,
      'name': name,
      'loop': loop,
    };
  }

  factory Ringtone.fromJson(Map<String, dynamic> json) {
    return Ringtone(
      assetPath: json['assetPath'] as String,
      name: json['name'] as String,
      loop: json['loop'] as bool? ?? true,
    );
  }
}
