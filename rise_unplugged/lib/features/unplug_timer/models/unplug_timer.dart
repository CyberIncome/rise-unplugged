class UnplugTimerConfig {
  const UnplugTimerConfig({
    required this.duration,
    this.requireVerification = true,
    this.calmingAnimation = 'assets/animations/sunrise.json',
    this.blockDistractions = false,
  });

  final Duration duration;
  final bool requireVerification;
  final String calmingAnimation;
  final bool blockDistractions;

  UnplugTimerConfig copyWith({
    Duration? duration,
    bool? requireVerification,
    String? calmingAnimation,
    bool? blockDistractions,
  }) {
    return UnplugTimerConfig(
      duration: duration ?? this.duration,
      requireVerification: requireVerification ?? this.requireVerification,
      calmingAnimation: calmingAnimation ?? this.calmingAnimation,
      blockDistractions: blockDistractions ?? this.blockDistractions,
    );
  }
}
