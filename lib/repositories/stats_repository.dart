import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

/// Repository for game statistics stored in Hive and SharedPreferences.
class StatsRepository {
  static const _boxName = 'stats';
  static const _keyTodayCoins = 'today_coins';
  static const _keyMonthCoins = 'month_coins';
  static const _keyTodayWorkSeconds = 'today_work_seconds';
  static const _keyYesterdayCoins = 'yesterday_coins';
  static const _keyLastMonthCoins = 'last_month_coins';

  late Box<int> _box;
  final SharedPreferences _prefs;

  StatsRepository(this._prefs);

  /// Convenience factory that obtains SharedPreferences and returns a ready
  /// StatsRepository. Callers that used the old parameterless constructor can
  /// switch to `await StatsRepository.create()`.
  static Future<StatsRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StatsRepository(prefs);
  }

  Future<void> init() async {
    _box = await Hive.openBox<int>(_boxName);
  }

  // ─── Today Coins ──────────────────────────────────────

  int getTodayCoins() => _safeRead(_keyTodayCoins);

  Future<void> setTodayCoins(int value) => _safeWrite(_keyTodayCoins, value);

  // ─── Month Coins ──────────────────────────────────────

  int getMonthCoins() => _safeRead(_keyMonthCoins);

  Future<void> setMonthCoins(int value) => _safeWrite(_keyMonthCoins, value);

  // ─── Today Work Seconds ───────────────────────────────

  int getTodayWorkSeconds() => _safeRead(_keyTodayWorkSeconds);

  Future<void> setTodayWorkSeconds(int value) =>
      _safeWrite(_keyTodayWorkSeconds, value);

  // ─── Yesterday Coins (reserved for V1.1) ──────────────

  int getYesterdayCoins() => _safeRead(_keyYesterdayCoins);

  Future<void> setYesterdayCoins(int value) =>
      _safeWrite(_keyYesterdayCoins, value);

  // ─── Last Month Coins (reserved for V1.1) ─────────────

  int getLastMonthCoins() => _safeRead(_keyLastMonthCoins);

  Future<void> setLastMonthCoins(int value) =>
      _safeWrite(_keyLastMonthCoins, value);

  // ─── Clear ────────────────────────────────────────────

  Future<void> clearAll() async {
    await _box.clear();
  }

  // ─── Streak ───────────────────────────────────────────

  static const _keyStreak = 'streak_record';

  StreakRecord getStreak() {
    try {
      final json = _prefs.getString(_keyStreak);
      if (json == null) return StreakRecord();
      return StreakRecord.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return StreakRecord();
    }
  }

  Future<void> setStreak(StreakRecord record) async {
    await _prefs.setString(_keyStreak, jsonEncode(record.toJson()));
  }

  // ─── Daily Goal ───────────────────────────────────────

  static const _keyDailyGoal = 'daily_goal';

  DailyGoal getDailyGoal() {
    try {
      final json = _prefs.getString(_keyDailyGoal);
      if (json == null) return DailyGoal();
      return DailyGoal.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return DailyGoal();
    }
  }

  Future<void> setDailyGoal(DailyGoal goal) async {
    await _prefs.setString(_keyDailyGoal, jsonEncode(goal.toJson()));
  }

  // ─── Achievements ─────────────────────────────────────

  static const _keyAchievements = 'achievements';

  List<Achievement> getAchievements() {
    try {
      final json = _prefs.getString(_keyAchievements);
      if (json == null) return allAchievements;
      final list = jsonDecode(json) as List<dynamic>;
      final saved =
          list.map((e) => Achievement.fromJson(e as Map<String, dynamic>)).toList();
      final map = {for (var a in saved) a.id: a};
      return allAchievements.map((def) => map[def.id] ?? def).toList();
    } catch (_) {
      return allAchievements;
    }
  }

  Future<void> setAchievements(List<Achievement> achievements) async {
    final list = achievements.map((a) => a.toJson()).toList();
    await _prefs.setString(_keyAchievements, jsonEncode(list));
  }

  // ─── Calendar ─────────────────────────────────────────

  static const _keyCalendar = 'calendar_days';

  Map<String, CalendarDay> getCalendar() {
    try {
      final json = _prefs.getString(_keyCalendar);
      if (json == null) return {};
      final list = jsonDecode(json) as List<dynamic>;
      final map = <String, CalendarDay>{};
      for (final e in list) {
        final day = CalendarDay.fromJson(e as Map<String, dynamic>);
        map[day.date] = day;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> setCalendarDay(CalendarDay day) async {
    final map = getCalendar();
    map[day.date] = day;
    final list = map.values.map((d) => d.toJson()).toList();
    await _prefs.setString(_keyCalendar, jsonEncode(list));
  }

  // ─── Internal helpers ─────────────────────────────────

  int _safeRead(String key) {
    try {
      return _box.get(key) ?? 0;
    } catch (_) {
      return 0; // Silent fallback (PRD §11)
    }
  }

  Future<void> _safeWrite(String key, int value) async {
    try {
      await _box.put(key, value);
    } catch (_) {
      // Retry once on write failure (PRD §11)
      try {
        await _box.put(key, value);
      } catch (_) {
        // Best effort
      }
    }
  }
}
