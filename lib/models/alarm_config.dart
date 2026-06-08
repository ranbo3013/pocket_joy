import 'package:flutter/material.dart';

/// A user-defined custom alarm for specific times of day.
///
/// Each alarm can repeat multiple times with a configurable interval.
class CustomAlarm {
  final String id;
  final String title;
  final int hour; // 0-23
  final int minute; // 0-59
  final int repeatCount; // 1-5, default 1
  final int intervalMinutes; // 1-30, default 5
  final bool enabled;
  final List<bool> workDays; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]

  const CustomAlarm({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.repeatCount = 1,
    this.intervalMinutes = 5,
    this.enabled = true,
    this.workDays = const [true, true, true, true, true, false, false],
  });

  /// Create a [CustomAlarm] from a [TimeOfDay].
  factory CustomAlarm.fromTimeOfDay({
    required String id,
    required String title,
    required TimeOfDay time,
    int repeatCount = 1,
    int intervalMinutes = 5,
    bool enabled = true,
    List<bool>? workDays,
  }) {
    return CustomAlarm(
      id: id,
      title: title,
      hour: time.hour,
      minute: time.minute,
      repeatCount: repeatCount,
      intervalMinutes: intervalMinutes,
      enabled: enabled,
      workDays: workDays ?? const [true, true, true, true, true, false, false],
    );
  }

  /// The alarm time as a [TimeOfDay].
  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  /// Whether this alarm is active on the given weekday.
  ///
  /// [weekday] follows Dart's convention: 1=Monday..7=Sunday.
  bool isActiveOnDay(int weekday) {
    assert(weekday >= 1 && weekday <= 7, 'weekday must be 1-7');
    return workDays[weekday - 1];
  }

  CustomAlarm copyWith({
    String? id,
    String? title,
    int? hour,
    int? minute,
    int? repeatCount,
    int? intervalMinutes,
    bool? enabled,
    List<bool>? workDays,
  }) {
    return CustomAlarm(
      id: id ?? this.id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatCount: repeatCount ?? this.repeatCount,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      enabled: enabled ?? this.enabled,
      workDays: workDays ?? this.workDays,
    );
  }

  /// Serialize to a JSON-compatible map for SharedPreferences persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hour': hour,
      'minute': minute,
      'repeatCount': repeatCount,
      'intervalMinutes': intervalMinutes,
      'enabled': enabled,
      'workDays': workDays,
    };
  }

  /// Deserialize from a JSON-compatible map.
  factory CustomAlarm.fromJson(Map<String, dynamic> json) {
    return CustomAlarm(
      id: json['id'] as String,
      title: json['title'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      repeatCount: json['repeatCount'] as int? ?? 1,
      intervalMinutes: json['intervalMinutes'] as int? ?? 5,
      enabled: json['enabled'] as bool? ?? true,
      workDays: (json['workDays'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          const [true, true, true, true, true, false, false],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomAlarm &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          hour == other.hour &&
          minute == other.minute &&
          repeatCount == other.repeatCount &&
          intervalMinutes == other.intervalMinutes &&
          enabled == other.enabled &&
          _listEquals(workDays, other.workDays);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        hour,
        minute,
        repeatCount,
        intervalMinutes,
        enabled,
        Object.hashAll(workDays),
      );
}

/// Configuration for work hours, break settings, and custom alarms.
class AlarmConfig {
  final int workStartHour;
  final int workStartMinute;
  final int workEndHour;
  final int workEndMinute;
  final List<bool> workDays; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final int breakIntervalMinutes; // 0 = disabled
  final int breakDurationMinutes;
  final bool breakRewardEnabled;
  final bool morningRewardEnabled;
  final List<CustomAlarm> customAlarms;

  const AlarmConfig({
    this.workStartHour = 9,
    this.workStartMinute = 0,
    this.workEndHour = 18,
    this.workEndMinute = 0,
    this.workDays = const [true, true, true, true, true, false, false],
    this.breakIntervalMinutes = 60,
    this.breakDurationMinutes = 5,
    this.breakRewardEnabled = true,
    this.morningRewardEnabled = true,
    this.customAlarms = const [],
  });

  /// Work start time as a [TimeOfDay].
  TimeOfDay get workStartTime =>
      TimeOfDay(hour: workStartHour, minute: workStartMinute);

  /// Work end time as a [TimeOfDay].
  TimeOfDay get workEndTime =>
      TimeOfDay(hour: workEndHour, minute: workEndMinute);

  /// Whether today is a configured workday.
  bool isWorkdayToday() {
    final today = DateTime.now().weekday; // 1=Mon..7=Sun
    return workDays[today - 1];
  }

  /// Whether a given weekday (1=Mon..7=Sun) is a workday.
  bool isWorkday(int weekday) {
    assert(weekday >= 1 && weekday <= 7, 'weekday must be 1-7');
    return workDays[weekday - 1];
  }

  AlarmConfig copyWith({
    int? workStartHour,
    int? workStartMinute,
    int? workEndHour,
    int? workEndMinute,
    List<bool>? workDays,
    int? breakIntervalMinutes,
    int? breakDurationMinutes,
    bool? breakRewardEnabled,
    bool? morningRewardEnabled,
    List<CustomAlarm>? customAlarms,
  }) {
    return AlarmConfig(
      workStartHour: workStartHour ?? this.workStartHour,
      workStartMinute: workStartMinute ?? this.workStartMinute,
      workEndHour: workEndHour ?? this.workEndHour,
      workEndMinute: workEndMinute ?? this.workEndMinute,
      workDays: workDays ?? this.workDays,
      breakIntervalMinutes: breakIntervalMinutes ?? this.breakIntervalMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      breakRewardEnabled: breakRewardEnabled ?? this.breakRewardEnabled,
      morningRewardEnabled: morningRewardEnabled ?? this.morningRewardEnabled,
      customAlarms: customAlarms ?? this.customAlarms,
    );
  }

  /// Serialize to a JSON-compatible map for SharedPreferences persistence.
  Map<String, dynamic> toJson() {
    return {
      'workStartHour': workStartHour,
      'workStartMinute': workStartMinute,
      'workEndHour': workEndHour,
      'workEndMinute': workEndMinute,
      'workDays': workDays,
      'breakIntervalMinutes': breakIntervalMinutes,
      'breakDurationMinutes': breakDurationMinutes,
      'breakRewardEnabled': breakRewardEnabled,
      'morningRewardEnabled': morningRewardEnabled,
      'customAlarms': customAlarms.map((a) => a.toJson()).toList(),
    };
  }

  /// Deserialize from a JSON-compatible map.
  factory AlarmConfig.fromJson(Map<String, dynamic> json) {
    return AlarmConfig(
      workStartHour: json['workStartHour'] as int? ?? 9,
      workStartMinute: json['workStartMinute'] as int? ?? 0,
      workEndHour: json['workEndHour'] as int? ?? 18,
      workEndMinute: json['workEndMinute'] as int? ?? 0,
      workDays: (json['workDays'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          const [true, true, true, true, true, false, false],
      breakIntervalMinutes: json['breakIntervalMinutes'] as int? ?? 60,
      breakDurationMinutes: json['breakDurationMinutes'] as int? ?? 5,
      breakRewardEnabled: json['breakRewardEnabled'] as bool? ?? true,
      morningRewardEnabled: json['morningRewardEnabled'] as bool? ?? true,
      customAlarms: (json['customAlarms'] as List<dynamic>?)
              ?.map((e) => CustomAlarm.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmConfig &&
          runtimeType == other.runtimeType &&
          workStartHour == other.workStartHour &&
          workStartMinute == other.workStartMinute &&
          workEndHour == other.workEndHour &&
          workEndMinute == other.workEndMinute &&
          breakIntervalMinutes == other.breakIntervalMinutes &&
          breakDurationMinutes == other.breakDurationMinutes &&
          breakRewardEnabled == other.breakRewardEnabled &&
          morningRewardEnabled == other.morningRewardEnabled &&
          _listEquals(workDays, other.workDays) &&
          _listEquals(customAlarms, other.customAlarms);

  @override
  int get hashCode => Object.hash(
        workStartHour,
        workStartMinute,
        workEndHour,
        workEndMinute,
        breakIntervalMinutes,
        breakDurationMinutes,
        breakRewardEnabled,
        morningRewardEnabled,
        Object.hashAll(workDays),
        Object.hashAll(customAlarms),
      );
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
