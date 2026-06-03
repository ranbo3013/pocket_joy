import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/app_phase.dart';
import '../repositories/settings_repository.dart';
import '../repositories/stats_repository.dart';
import '../services/coin_calculator.dart';
import '../services/interval_manager.dart';
import '../services/work_timer.dart';
import '../services/date_observer.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/notification_service.dart';
import 'config_provider.dart';

/// Central game state orchestrator.
/// Manages: phase state machine, work timer, coin drops, stats persistence.
class GameProvider extends ChangeNotifier {
  final ConfigProvider _config;
  final StatsRepository _statsRepo;
  final CoinCalculator _calculator;
  final IntervalManager _intervalManager;
  final WorkTimer _workTimer;
  final DateObserver _dateObserver;
  final AudioService _audioService;
  final HapticService _hapticService;
  final NotificationService _notificationService;

  late SettingsRepository _settingsRepo;

  // ─── Phase ──────────────────────────────────────────────

  AppPhase _phase = AppPhase.unset;
  AppPhase get phase => _phase;

  // ─── Stats ──────────────────────────────────────────────

  int _todayCoins = 0;
  int _monthCoins = 0;
  int _todayWorkSeconds = 0;

  int get todayCoins => _todayCoins;
  int get monthCoins => _monthCoins;
  int get todayWorkSeconds => _todayWorkSeconds;
  int get todayGoldBars => _todayCoins ~/ goldBarThreshold;
  int get todayRemainingCoins => _todayCoins % goldBarThreshold;
  int get monthGoldBars => _monthCoins ~/ goldBarThreshold;
  int get monthRemainingCoins => _monthCoins % goldBarThreshold;

  // ─── Interval state (in-memory only) ───────────────────

  int? _nextIntervalMinutes;
  int _multiplierIndex = 0;
  int? _lastBoundaryValue;

  // ─── Timer tracking ────────────────────────────────────

  Timer? _dropTimer;
  Timer? _persistTimer;

  // ─── Flag: did we just trigger a gold bar synthesis? ──
  bool _goldBarJustSynthesized = false;
  bool get goldBarJustSynthesized => _goldBarJustSynthesized;

  // ─── Constructor ───────────────────────────────────────

  GameProvider(
    this._config, {
    StatsRepository? statsRepo,
    CoinCalculator? calculator,
    IntervalManager? intervalManager,
    WorkTimer? workTimer,
    DateObserver? dateObserver,
    AudioService? audioService,
    HapticService? hapticService,
    NotificationService? notificationService,
  })  : _statsRepo = statsRepo ?? StatsRepository(),
        _calculator = calculator ?? const CoinCalculator(),
        _intervalManager = intervalManager ?? IntervalManager(),
        _workTimer = workTimer ?? WorkTimer(),
        _dateObserver = dateObserver ?? DateObserver(),
        _audioService = audioService ?? AudioService(),
        _hapticService = hapticService ?? HapticService(),
        _notificationService = notificationService ?? NotificationService();

  // ─── Initialize (PRD §8.3) ─────────────────────────────

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _settingsRepo = SettingsRepository(prefs);

    // Init stats
    await _statsRepo.init();

    // Listen to work timer
    _workTimer.seconds.listen(_onWorkSecondTick);

    // Date observer callbacks
    _dateObserver.onDayChanged = _onDayChanged;
    _dateObserver.onMonthChanged = _onMonthChanged;
    _dateObserver.onTimeRollback = _onTimeRollback;

    // Init notification & audio services
    await _notificationService.init();
    await _audioService.init();

    if (!_config.isSalarySet) {
      _phase = AppPhase.unset;
      notifyListeners();
      return;
    }

    // Restore stats
    _todayCoins = _statsRepo.getTodayCoins();
    _monthCoins = _statsRepo.getMonthCoins();
    _todayWorkSeconds = _statsRepo.getTodayWorkSeconds();

    // Check cross-day / cross-month
    final today = _todayString();
    final lastDate = _settingsRepo.getLastActiveDate();

    if (lastDate != null && lastDate != today) {
      // Cross-day
      await _statsRepo.setYesterdayCoins(_todayCoins);
      _todayCoins = 0;
      _todayWorkSeconds = 0;
      await _settingsRepo.setLastActiveDate(today);

      // Check cross-month
      if (_isDifferentMonth(lastDate, today)) {
        await _statsRepo.setLastMonthCoins(_monthCoins);
        _monthCoins = 0;
      }
    }

    // Update last active date
    await _settingsRepo.setLastActiveDate(today);

    // Restore phase
    if (_settingsRepo.getIsOffWork()) {
      _phase = AppPhase.offWork;
    } else if (_settingsRepo.getIsPaused()) {
      _phase = AppPhase.paused;
    } else {
      _phase = AppPhase.running;
      _startRunning();
    }

    notifyListeners();
  }

  // ─── Phase transitions ─────────────────────────────────

  void start() {
    if (_phase == AppPhase.running) return;
    _resetDayIfCrossed();
    _phase = AppPhase.running;
    _settingsRepo.setIsOffWork(false);
    _settingsRepo.setIsPaused(false);
    _startRunning();
    notifyListeners();
  }

  void pause() {
    if (_phase != AppPhase.running) return;
    _phase = AppPhase.paused;
    _workTimer.pause();
    _dropTimer?.cancel();
    _persistTimer?.cancel();
    _settingsRepo.setIsPaused(true);
    _notificationService.schedulePauseReminder();
    _flushStats();
    notifyListeners();
  }

  void resume() {
    if (_phase != AppPhase.paused) return;
    _phase = AppPhase.running;
    _settingsRepo.setIsPaused(false);
    _notificationService.cancelPauseReminder();
    _startRunning(isResume: true);
    notifyListeners();
  }

  void clockOut() {
    if (_phase != AppPhase.running && _phase != AppPhase.paused) return;
    _workTimer.pause();
    _dropTimer?.cancel();
    _persistTimer?.cancel();
    _phase = AppPhase.offWork;
    _settingsRepo.setIsOffWork(true);
    _settingsRepo.setIsPaused(false);
    _notificationService.cancelPauseReminder();
    _flushStats();
    notifyListeners();
  }

  void restart() {
    // Off-duty user manually restarts
    _todayCoins = 0;
    _todayWorkSeconds = 0;
    _phase = AppPhase.running;
    _settingsRepo.setIsOffWork(false);
    _settingsRepo.setIsPaused(false);
    _statsRepo.setTodayCoins(0);
    _statsRepo.setTodayWorkSeconds(0);
    _startRunning();
    notifyListeners();
  }

  // ─── On app background/foreground ──────────────────────

  void onAppBackground() {
    if (_phase == AppPhase.running) {
      _workTimer.pause();
      _dropTimer?.cancel();
      _persistTimer?.cancel();
      _notificationService.schedulePauseReminder();
      _flushStats();
    }
  }

  void onAppForeground() {
    _dateObserver.onForeground();
    if (_phase == AppPhase.running) {
      _startRunning(isResume: true);
    }
  }

  // ─── Internal: start running ───────────────────────────

  void _startRunning({bool isResume = false}) {
    _workTimer.resume();

    // If resume from pause/background, generate new seed interval
    if (isResume) {
      final config = _config.intervalConfig;
      _nextIntervalMinutes = _intervalManager.generateSeed(
        config.minMinutes,
        config.maxMinutes,
      );
    } else {
      // Fresh start: schedule first drop
      final config = _config.intervalConfig;
      _nextIntervalMinutes ??= _intervalManager.generateSeed(
        config.minMinutes,
        config.maxMinutes,
      );
    }

    _scheduleNextDrop();
    _startPeriodicPersist();
  }

  // ─── Coin drop scheduling ──────────────────────────────

  void _scheduleNextDrop() {
    _dropTimer?.cancel();
    final interval = _nextIntervalMinutes;
    if (interval == null) return;

    _dropTimer = Timer(Duration(minutes: interval), _onDropIntervalElapsed);
  }

  void _onDropIntervalElapsed() {
    if (_phase != AppPhase.running) return;

    final salaryConfig = _config.salaryConfig;
    if (salaryConfig == null) return;

    final interval = _nextIntervalMinutes!;
    final perMinute = _calculator.perMinuteSalary(salaryConfig);
    final coins = _calculator.dropCoins(perMinute, interval);

    _triggerDrop(coins);
  }

  void _triggerDrop(int coins) {
    _goldBarJustSynthesized = false;

    final oldMonthCoins = _monthCoins;

    _todayCoins += coins;
    _monthCoins += coins;

    // Check gold bar synthesis
    final oldBars = oldMonthCoins ~/ goldBarThreshold;
    final newBars = _monthCoins ~/ goldBarThreshold;
    if (newBars > oldBars) {
      _goldBarJustSynthesized = true;
    }

    // Audio + Haptic
    if (_goldBarJustSynthesized) {
      _audioService.playGoldBar();
      _hapticService.mediumImpact();
      _notificationService.checkGoldBarMilestone(newBars);
    } else {
      _audioService.playCoinDrop();
      _hapticService.lightImpact();
    }

    // Check milestone notifications
    _notificationService.checkCoinMilestones(_todayCoins);

    notifyListeners();

    // Schedule next drop
    final config = _config.intervalConfig;
    final result = _intervalManager.nextInterval(
      _nextIntervalMinutes!,
      config.minMinutes,
      config.maxMinutes,
      _multiplierIndex,
      _lastBoundaryValue,
    );
    _nextIntervalMinutes = result.nextInterval;
    _multiplierIndex = result.multiplierIndex;
    _lastBoundaryValue = result.lastBoundary;

    _scheduleNextDrop();
  }

  // ─── Work timer tick ───────────────────────────────────

  void _onWorkSecondTick(int seconds) {
    if (_phase != AppPhase.running) return;
    _todayWorkSeconds = seconds;
    _dateObserver.check();

    // Check end-of-workday notification
    if (_todayWorkSeconds >= 8 * 3600) {
      _notificationService.scheduleEndOfWorkdayReminder();
    }

    notifyListeners();
  }

  // ─── Periodic persist ──────────────────────────────────

  void _startPeriodicPersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _flushStats();
    });
  }

  void _flushStats() {
    _statsRepo.setTodayCoins(_todayCoins);
    _statsRepo.setMonthCoins(_monthCoins);
    _statsRepo.setTodayWorkSeconds(_todayWorkSeconds);
  }

  // ─── Cross-day / month handlers ────────────────────────

  void _onDayChanged() {
    _statsRepo.setYesterdayCoins(_todayCoins);
    _todayCoins = 0;
    _todayWorkSeconds = 0;
    _workTimer.reset();
    if (_phase == AppPhase.running) {
      _workTimer.start();
      _startRunning(isResume: true);
    }
    notifyListeners();
  }

  void _onMonthChanged() {
    _statsRepo.setLastMonthCoins(_monthCoins);
    _monthCoins = 0;
    notifyListeners();
  }

  void _onTimeRollback() {
    if (_phase == AppPhase.running) {
      pause();
    }
    // Toast will be shown by UI layer observing phase + timeRollback flag
    notifyListeners();
  }

  void _resetDayIfCrossed() {
    final today = _todayString();
    final lastDate = _settingsRepo.getLastActiveDate();
    if (lastDate != null && lastDate != today) {
      _todayCoins = 0;
      _todayWorkSeconds = 0;
      if (_isDifferentMonth(lastDate, today)) {
        _monthCoins = 0;
      }
    }
    _settingsRepo.setLastActiveDate(today);
  }

  // ─── Helpers ───────────────────────────────────────────

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool _isDifferentMonth(String date1, String date2) {
    final p1 = date1.split('-');
    final p2 = date2.split('-');
    return p1[0] != p2[0] || p1[1] != p2[1];
  }

  @override
  void dispose() {
    _workTimer.dispose();
    _dropTimer?.cancel();
    _persistTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
