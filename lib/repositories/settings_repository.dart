import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

/// Repository for non-sensitive settings stored in SharedPreferences.
class SettingsRepository {
  static const _keyWorkdays = 'current_month_workdays';
  static const _keyIntervalMin = 'interval_min';
  static const _keyIntervalMax = 'interval_max';
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyHapticEnabled = 'haptic_enabled';
  static const _keyIsPaused = 'is_paused';
  static const _keyIsOffWork = 'is_off_work';
  static const _keyLastActiveDate = 'last_active_date';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  // ─── Workdays ─────────────────────────────────────────

  int getWorkdays() {
    try {
      return _prefs.getInt(_keyWorkdays) ?? _defaultWorkdaysThisMonth();
    } catch (_) {
      return _defaultWorkdaysThisMonth();
    }
  }

  Future<bool> setWorkdays(int days) async {
    return _prefs.setInt(_keyWorkdays, days);
  }

  // ─── Interval ─────────────────────────────────────────

  int getIntervalMin() {
    try {
      return _prefs.getInt(_keyIntervalMin) ?? defaultIntervalMin;
    } catch (_) {
      return defaultIntervalMin;
    }
  }

  int getIntervalMax() {
    try {
      return _prefs.getInt(_keyIntervalMax) ?? defaultIntervalMax;
    } catch (_) {
      return defaultIntervalMax;
    }
  }

  Future<bool> setIntervalMin(int min) async {
    return _prefs.setInt(_keyIntervalMin, min);
  }

  Future<bool> setIntervalMax(int max) async {
    return _prefs.setInt(_keyIntervalMax, max);
  }

  // ─── Sound / Haptic ───────────────────────────────────

  bool getSoundEnabled() {
    try {
      return _prefs.getBool(_keySoundEnabled) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> setSoundEnabled(bool value) async {
    return _prefs.setBool(_keySoundEnabled, value);
  }

  bool getHapticEnabled() {
    try {
      return _prefs.getBool(_keyHapticEnabled) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> setHapticEnabled(bool value) async {
    return _prefs.setBool(_keyHapticEnabled, value);
  }

  // ─── Phase flags ──────────────────────────────────────

  bool getIsPaused() {
    try {
      return _prefs.getBool(_keyIsPaused) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setIsPaused(bool value) async {
    return _prefs.setBool(_keyIsPaused, value);
  }

  bool getIsOffWork() {
    try {
      return _prefs.getBool(_keyIsOffWork) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setIsOffWork(bool value) async {
    return _prefs.setBool(_keyIsOffWork, value);
  }

  // ─── Date tracking ────────────────────────────────────

  String? getLastActiveDate() {
    try {
      return _prefs.getString(_keyLastActiveDate);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setLastActiveDate(String date) async {
    return _prefs.setString(_keyLastActiveDate, date);
  }

  // ─── Clear all ────────────────────────────────────────

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

/// Calculate default workdays: Mon-Fri count in current month.
int _defaultWorkdaysThisMonth() {
  final now = DateTime.now();
  final firstDay = DateTime(now.year, now.month, 1);
  final lastDay = DateTime(now.year, now.month + 1, 0);
  int count = 0;
  for (var d = firstDay; d.isBefore(lastDay) || d == lastDay; d = d.add(const Duration(days: 1))) {
    if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
      count++;
    }
  }
  return count;
}
