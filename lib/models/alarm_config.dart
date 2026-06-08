/// Alarm configuration for scheduled coin drop notifications.
class AlarmConfig {
  final bool enabled;
  final int hour;
  final int minute;
  final bool workdaysOnly;

  const AlarmConfig({
    this.enabled = false,
    this.hour = 9,
    this.minute = 0,
    this.workdaysOnly = true,
  });

  factory AlarmConfig.fromJson(Map<String, dynamic> json) {
    return AlarmConfig(
      enabled: json['enabled'] as bool? ?? false,
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
      workdaysOnly: json['workdaysOnly'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'workdaysOnly': workdaysOnly,
      };

  AlarmConfig copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool? workdaysOnly,
  }) {
    return AlarmConfig(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      workdaysOnly: workdaysOnly ?? this.workdaysOnly,
    );
  }
}
