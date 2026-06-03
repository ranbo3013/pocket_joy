import 'package:hive_flutter/hive_flutter.dart';

/// Repository for game statistics stored in Hive.
class StatsRepository {
  static const _boxName = 'stats';
  static const _keyTodayCoins = 'today_coins';
  static const _keyMonthCoins = 'month_coins';
  static const _keyTodayWorkSeconds = 'today_work_seconds';
  static const _keyYesterdayCoins = 'yesterday_coins';
  static const _keyLastMonthCoins = 'last_month_coins';

  late Box<int> _box;

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
