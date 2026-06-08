import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/salary_config.dart';
import '../models/interval_config.dart';
import '../repositories/salary_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/stats_repository.dart';

/// Manages salary and settings configuration.
/// Independent provider — no dependencies on other providers.
class ConfigProvider extends ChangeNotifier {
  final SalaryRepository _salaryRepo;
  late final SettingsRepository _settingsRepo;
  final StatsRepository _statsRepo;

  // ─── State ──────────────────────────────────────────────

  double? _salaryAfterTax;
  late int _workdays;
  late int _intervalMin;
  late int _intervalMax;
  late bool _soundEnabled;
  late bool _hapticEnabled;
  late bool _notificationsEnabled;

  ConfigProvider({
    required StatsRepository statsRepo,
    SalaryRepository? salaryRepo,
  })  : _salaryRepo = salaryRepo ?? SalaryRepository(),
        _statsRepo = statsRepo;

  // ─── Getters ────────────────────────────────────────────

  bool get isSalarySet => _salaryAfterTax != null;

  double? get salaryAfterTax => _salaryAfterTax;

  int get workdays => _workdays;
  int get intervalMin => _intervalMin;
  int get intervalMax => _intervalMax;
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  bool get notificationsEnabled => _notificationsEnabled;

  SalaryConfig? get salaryConfig {
    if (_salaryAfterTax == null) return null;
    return SalaryConfig(
      afterTax: _salaryAfterTax!,
      workdays: _workdays,
    );
  }

  IntervalConfig get intervalConfig => IntervalConfig(
        minMinutes: _intervalMin,
        maxMinutes: _intervalMax,
      );

  // ─── Load (call once at startup) ───────────────────────

  Future<void> load() async {
    // Init stats repo
    await _statsRepo.init();

    // Init settings
    final prefs = await SharedPreferences.getInstance();
    _settingsRepo = SettingsRepository(prefs);

    // Load salary
    _salaryAfterTax = await _salaryRepo.getSalary();

    // Load settings
    _workdays = _settingsRepo.getWorkdays();
    _intervalMin = _settingsRepo.getIntervalMin();
    _intervalMax = _settingsRepo.getIntervalMax();
    _soundEnabled = _settingsRepo.getSoundEnabled();
    _hapticEnabled = _settingsRepo.getHapticEnabled();
    _notificationsEnabled = _settingsRepo.getNotificationsEnabled();

    notifyListeners();
  }

  // ─── Salary ──────────────────────────────────────────

  Future<bool> saveSalary(double afterTax, int workdays) async {
    final success = await _salaryRepo.setSalary(afterTax);
    if (!success) return false;

    _salaryAfterTax = afterTax;
    await _settingsRepo.setWorkdays(workdays);
    _workdays = workdays;
    notifyListeners();
    return true;
  }

  Future<bool> updateSalary(double newSalary) async {
    final success = await _salaryRepo.setSalary(newSalary);
    if (!success) return false;
    _salaryAfterTax = newSalary;
    notifyListeners();
    return true;
  }

  // ─── Settings ────────────────────────────────────────

  Future<void> updateWorkdays(int days) async {
    await _settingsRepo.setWorkdays(days);
    _workdays = days;
    notifyListeners();
  }

  Future<void> updateIntervalRange(int min, int max) async {
    await _settingsRepo.setIntervalMin(min);
    await _settingsRepo.setIntervalMax(max);
    _intervalMin = min;
    _intervalMax = max;
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _settingsRepo.setSoundEnabled(_soundEnabled);
    notifyListeners();
  }

  Future<void> toggleHaptic() async {
    _hapticEnabled = !_hapticEnabled;
    await _settingsRepo.setHapticEnabled(_hapticEnabled);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    await _settingsRepo.setNotificationsEnabled(_notificationsEnabled);
    notifyListeners();
  }

  // ─── Clear All ───────────────────────────────────────

  Future<void> clearAllData() async {
    await _salaryRepo.clear();
    await _settingsRepo.clearAll();
    await _statsRepo.clearAll();

    _salaryAfterTax = null;
    _workdays = _settingsRepo.getWorkdays(); // re-reads default
    _intervalMin = defaultIntervalMin;
    _intervalMax = defaultIntervalMax;
    _soundEnabled = true;
    _hapticEnabled = true;
    _notificationsEnabled = true;

    notifyListeners();
  }

  // ─── Static Validation ───────────────────────────────

  static String? validateSalary(double? value) {
    if (value == null || value <= 0) return '请输入有效金额';
    if (value > maxSalary) return '金额不能超过 $maxSalary';
    return null; // valid
  }

  static String? validateWorkdays(int value) {
    if (value < minWorkdays) return '至少 1 天';
    if (value > maxWorkdays) return '不能超过 $maxWorkdays 天';
    return null; // valid
  }

  static String? validateInterval(int min, int max) {
    if (min < minIntervalMinutes) return '最小间隔至少 1 分钟';
    if (max > maxIntervalMinutes) return '最大间隔不能超过 1440 分钟';
    if (min >= max) return '最小间隔必须小于最大间隔';
    return null; // valid
  }
}
