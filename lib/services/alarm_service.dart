// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alarm_config.dart';
import '../repositories/alarm_repository.dart';
import 'haptic_service.dart';
import 'notification_service.dart';

/// Manages all alarm scheduling and triggering for PocketJoy.
///
/// Owns [AlarmConfig] lifecycle, periodic timer checks for work start/end
/// and custom alarms, break interval timers, and overtime detection.
class AlarmService {
  final AlarmRepository _repo;
  final NotificationService _notifications;
  final HapticService _haptics;

  AlarmConfig _config = const AlarmConfig();
  Timer? _breakTimer;
  Timer? _alarmCheckTimer;
  Timer? _overtimeTimer;
  DateTime _workStartTime = DateTime.now();
  DateTime? _breakStartTime;
  int _continuousWorkMinutes = 0;
  int _currentRepeat = 0;

  // ── Deduplication: prevent re-triggering within the same minute ──
  DateTime? _lastWorkStartTrigger;
  DateTime? _lastWorkEndTrigger;
  final Map<int, DateTime> _lastCustomAlarmTriggers = {};

  // ── Callbacks ──────────────────────────────────────────────

  /// Called when the work‑start alarm fires.
  VoidCallback? onWorkStartTriggered;

  /// Called when the break‑reminder alarm fires.
  VoidCallback? onBreakTriggered;

  /// Called when the end‑of‑workday alarm fires.
  VoidCallback? onEndOfWorkdayTriggered;

  /// Called on every hourly overtime tick after the threshold is exceeded.
  VoidCallback? onOvertimeTriggered;

  /// Called when a custom alarm fires (including repeats).
  void Function(CustomAlarm)? onCustomAlarmTriggered;

  // ── Constructor ────────────────────────────────────────────

  AlarmService({
    required AlarmRepository repo,
    required NotificationService notifications,
    required HapticService haptics,
  })  : _repo = repo,
        _notifications = notifications,
        _haptics = haptics;

  /// The time work started today (set via [onWorkStarted]).
  DateTime get workStartTime => _workStartTime;

  /// The time the current break started, or `null` if not on break.
  DateTime? get breakStartTime => _breakStartTime;

  /// The current alarm configuration.
  AlarmConfig get config => _config;

  // ── Lifecycle ──────────────────────────────────────────────

  /// Load config from the repository and reschedule all alarms.
  void load() {
    _config = _repo.load();
    _rescheduleAll();
  }

  /// Persist a new [config] and reschedule all alarms.
  Future<void> save(AlarmConfig config) async {
    _config = config;
    await _repo.save(config);
    _rescheduleAll();
  }

  /// Record the work‑start time and schedule the first break check.
  void onWorkStarted() {
    _workStartTime = DateTime.now();
    _continuousWorkMinutes = 0;
    _scheduleBreakCheck();
  }

  /// Increment the continuous‑work counter and evaluate overtime.
  ///
  /// Should be called once per minute (e.g. from a game‑loop tick).
  void onWorkMinuteTick() {
    _continuousWorkMinutes++;
    _checkOvertime();
  }

  /// Record the break‑start time and cancel the pending break timer.
  void onBreakStarted() {
    _breakStartTime = DateTime.now();
    _breakTimer?.cancel();
    _breakTimer = null;
  }

  /// Reset continuous‑work minutes and reschedule the next break check.
  void onBreakEnded() {
    _continuousWorkMinutes = 0;
    _breakStartTime = null;
    _overtimeTimer?.cancel();
    _overtimeTimer = null;
    _scheduleBreakCheck();
  }

  /// Cancel all running timers when the workday ends.
  void onWorkEnded() {
    _cancelAllTimers();
  }

  /// Cancel all timers — call when the service is no longer needed.
  void dispose() {
    _cancelAllTimers();
  }

  void _cancelAllTimers() {
    _breakTimer?.cancel();
    _breakTimer = null;
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = null;
    _overtimeTimer?.cancel();
    _overtimeTimer = null;
  }

  // ── Scheduling ─────────────────────────────────────────────

  /// Cancel all pending notifications and timers, then rebuild everything.
  void _rescheduleAll() {
    _notifications.cancelAllAlarms();
    _cancelAllTimers();
    _resetTriggerTracking();
    _scheduleWorkAlarms();
    _startPeriodicAlarmCheck();
  }

  void _resetTriggerTracking() {
    _lastWorkStartTrigger = null;
    _lastWorkEndTrigger = null;
    _lastCustomAlarmTriggers.clear();
  }

  /// Schedule work‑start, work‑end, and enabled custom alarms for today.
  void _scheduleWorkAlarms() {
    final now = DateTime.now();

    if (_config.isWorkdayToday()) {
      // ── Work start ──────────────────────────────────────
      final workStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        _config.workStartHour,
        _config.workStartMinute,
      );
      if (workStartTime.isAfter(now)) {
        _notifications.scheduleAlarm(
          id: 2001,
          title: '上班时间到',
          body: '该开始工作啦！',
          scheduledDate: workStartTime,
        );
      }

      // ── Work end ────────────────────────────────────────
      final workEndTime = DateTime(
        now.year,
        now.month,
        now.day,
        _config.workEndHour,
        _config.workEndMinute,
      );
      if (workEndTime.isAfter(now)) {
        _notifications.scheduleAlarm(
          id: 2003,
          title: '下班时间到',
          body: '今天辛苦了，记得打卡下班哦！',
          scheduledDate: workEndTime,
        );
      }
    }

    // ── Custom alarms ────────────────────────────────────────
    for (int i = 0; i < _config.customAlarms.length; i++) {
      final alarm = _config.customAlarms[i];
      if (!alarm.enabled) continue;
      if (!alarm.isActiveOnDay(now.weekday)) continue;

      final alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.hour,
        alarm.minute,
      );
      if (alarmTime.isAfter(now)) {
        _notifications.scheduleAlarm(
          id: 3000 + i,
          title: alarm.title,
          body: '自定义闹钟提醒',
          scheduledDate: alarmTime,
        );
      }
    }
  }

  /// Start a periodic 30‑second timer that evaluates time‑based alarms.
  ///
  /// This is the fallback that fires even when the system‑scheduled
  /// notification is missed (e.g. device was in Doze mode).
  void _startPeriodicAlarmCheck() {
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkTimeBasedAlarms(),
    );
  }

  /// Compare the current hour/minute against every configured alarm.
  ///
  /// Uses a simple minute‑granularity dedup so the same alarm
  /// cannot fire more than once per wall‑clock minute.
  void _checkTimeBasedAlarms() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    if (_config.isWorkdayToday()) {
      // ── Work start ──────────────────────────────────────
      if (currentHour == _config.workStartHour &&
          currentMinute == _config.workStartMinute) {
        if (_shouldTrigger(_lastWorkStartTrigger, now)) {
          _lastWorkStartTrigger = now;
          _triggerWorkStart();
        }
      }

      // ── Work end ────────────────────────────────────────
      if (currentHour == _config.workEndHour &&
          currentMinute == _config.workEndMinute) {
        if (_shouldTrigger(_lastWorkEndTrigger, now)) {
          _lastWorkEndTrigger = now;
          _triggerEndOfWorkday();
        }
      }
    }

    // ── Custom alarms ────────────────────────────────────────
    for (int i = 0; i < _config.customAlarms.length; i++) {
      final alarm = _config.customAlarms[i];
      if (!alarm.enabled) continue;
      if (!alarm.isActiveOnDay(now.weekday)) continue;

      if (currentHour == alarm.hour && currentMinute == alarm.minute) {
        final lastTrigger = _lastCustomAlarmTriggers[i];
        if (_shouldTrigger(lastTrigger, now)) {
          _lastCustomAlarmTriggers[i] = now;
          _triggerCustomAlarm(alarm, i);
        }
      }
    }
  }

  /// Returns `true` when the alarm has *not* been triggered in the
  /// same wall‑clock minute as [now].
  bool _shouldTrigger(DateTime? lastTrigger, DateTime now) {
    if (lastTrigger == null) return true;
    return lastTrigger.year != now.year ||
        lastTrigger.month != now.month ||
        lastTrigger.day != now.day ||
        lastTrigger.hour != now.hour ||
        lastTrigger.minute != now.minute;
  }

  /// Schedule a one‑shot [Timer] for the configured break interval.
  void _scheduleBreakCheck() {
    _breakTimer?.cancel();
    if (_config.breakIntervalMinutes <= 0) return;

    _breakTimer = Timer(
      Duration(minutes: _config.breakIntervalMinutes),
      _triggerBreak,
    );
  }

  /// Start hourly overtime reminders when continuous work exceeds
  /// [breakIntervalMinutes] + 60.
  void _checkOvertime() {
    final threshold = _config.breakIntervalMinutes + 60;
    if (_continuousWorkMinutes >= threshold && _overtimeTimer == null) {
      _overtimeTimer = Timer.periodic(
        const Duration(hours: 1),
        (_) => onOvertimeTriggered?.call(),
      );
    }
  }

  // ── Triggers ───────────────────────────────────────────────

  void _triggerWorkStart() {
    _haptics.patternWorkStart();
    _notifications.showAlarmNow(
      id: 2001,
      title: '上班时间到',
      body: '该开始工作啦！',
    );
    onWorkStartTriggered?.call();
  }

  void _triggerBreak() {
    _haptics.patternBreakReminder();
    _notifications.showAlarmNow(
      id: 2002,
      title: '休息时间',
      body: '已经连续工作一段时间了，休息一下吧！',
    );
    _currentRepeat = 0;
    onBreakTriggered?.call();
  }

  void _triggerEndOfWorkday() {
    _haptics.patternEndOfWorkday();
    _notifications.showAlarmNow(
      id: 2003,
      title: '下班时间到',
      body: '今天辛苦了，记得打卡下班哦！',
    );
    onEndOfWorkdayTriggered?.call();
  }

  void _triggerCustomAlarm(CustomAlarm alarm, int index) {
    _currentRepeat = 0;
    _haptics.patternBreakReminder();
    _notifications.showAlarmNow(
      id: 3000 + index,
      title: alarm.title,
      body: '自定义闹钟提醒',
    );
    onCustomAlarmTriggered?.call(alarm);
    _scheduleCustomAlarmRepeat(alarm, index);
  }

  /// Schedule the next repeat for a custom alarm if there are
  /// remaining repetitions.
  void _scheduleCustomAlarmRepeat(CustomAlarm alarm, int index) {
    if (_currentRepeat < alarm.repeatCount - 1) {
      _currentRepeat++;
      Timer(
        Duration(minutes: alarm.intervalMinutes),
        () => _triggerCustomAlarm(alarm, index),
      );
    }
  }
}
