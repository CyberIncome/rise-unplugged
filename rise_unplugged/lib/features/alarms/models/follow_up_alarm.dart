class FollowUpAlarm {
  const FollowUpAlarm({
    required this.delay,
    this.message = 'Still snoozing?',
    this.recommendation,
  });

  final Duration delay;
  final String message;
  final String? recommendation;

  FollowUpAlarm copyWith({
    Duration? delay,
    String? message,
    String? recommendation,
  }) {
    return FollowUpAlarm(
      delay: delay ?? this.delay,
      message: message ?? this.message,
      recommendation: recommendation ?? this.recommendation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'delay': delay.inMinutes,
      'message': message,
      'recommendation': recommendation,
    };
  }

  factory FollowUpAlarm.fromJson(Map<String, dynamic> json) {
    return FollowUpAlarm(
      delay: Duration(minutes: json['delay'] as int? ?? 0),
      message: json['message'] as String? ?? 'Still snoozing?',
      recommendation: json['recommendation'] as String?,
    );
  }
}
