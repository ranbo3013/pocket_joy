import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_config.dart';

/// Repository for persisting alarm configuration to SharedPreferences as JSON.
class AlarmRepository {
  static const _keyAlarmConfig = 'alarm_config';

  final SharedPreferences _prefs;

  AlarmRepository(this._prefs);

  /// Load alarm config from SharedPreferences.
  /// Returns a default [AlarmConfig] when nothing is stored or on error.
  AlarmConfig load() {
    try {
      final json = _prefs.getString(_keyAlarmConfig);
      if (json == null) return const AlarmConfig();
      return AlarmConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return const AlarmConfig();
    }
  }

  /// Persist alarm config to SharedPreferences as JSON.
  /// Returns false on error.
  Future<bool> save(AlarmConfig config) async {
    try {
      return _prefs.setString(_keyAlarmConfig, jsonEncode(config.toJson()));
    } catch (_) {
      return false;
    }
  }

  /// Remove stored alarm config.
  Future<void> clear() async {
    await _prefs.remove(_keyAlarmConfig);
  }
}
