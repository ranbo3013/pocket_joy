import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/achievement.dart';
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

  // ─── V2.0: Streak / Goal / Achievements / Calendar ─────

  StreakRecord _streak = StreakRecord();
  DailyGoal _dailyGoal = DailyGoal();
  List<Achievement> _achievements = allAchievements;
  Map<String, CalendarDay> _calendarDays = {};

  StreakRecord get streak => _streak;
  DailyGoal get dailyGoal => _dailyGoal;
  List<Achievement> get achievements => _achievements;
  Map<String, CalendarDay> get calendarDays => _calendarDays;

  /// Set a daily coin goal target. Pass 0 to disable.
  void setDailyGoalTarget(int coins) {
    _dailyGoal = _dailyGoal.copyWith(
      targetCoins: coins,
      todayReached: false,
    );
    _statsRepo.setDailyGoal(_dailyGoal);
    notifyListeners();
  }

  // ─── Interval state (in-memory only) ───────────────────

  int? _nextIntervalMinutes;
  int _multiplierIndex = 0;
  int? _lastBoundaryValue;

  // ─── Timer tracking ────────────────────────────────────

  Timer? _dropTimer;
  Timer? _persistTimer;

  /// Timestamp when app last went to background (for catch-up on resume).
  DateTime? _backgroundAt;

  /// Debug: when true, drop interval uses seconds instead of minutes.
  /// Set to false for production.
  static const _debugFastDrop = false;
  static const _debugDropSeconds = 3;

  // ─── Flag: did we just trigger a gold bar synthesis? ──
  bool _goldBarJustSynthesized = false;
  bool get goldBarJustSynthesized => _goldBarJustSynthesized;

  // ─── Constructor ───────────────────────────────────────

  GameProvider(
    this._config, {
    required StatsRepository statsRepo,
    CoinCalculator? calculator,
    IntervalManager? intervalManager,
    WorkTimer? workTimer,
    DateObserver? dateObserver,
    AudioService? audioService,
    HapticService? hapticService,
    NotificationService? notificationService,
  })  : _statsRepo = statsRepo,
        _calculator = calculator ?? const CoinCalculator(),
        _intervalManager = intervalManager ?? IntervalManager(),
        _workTimer = workTimer ?? WorkTimer(),
        _dateObserver = dateObserver ?? DateObserver(),
        _audioService = audioService ?? AudioService(),
        _hapticService = hapticService ?? HapticService(),
        _notificationService = notificationService ?? NotificationService();

  // ─── Service getters ────────────────────────────────────

  AudioService get audioService => _audioService;
  HapticService get hapticService => _hapticService;
  NotificationService get notificationService => _notificationService;

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

    // Sync service settings from config
    _syncServiceSettings();

    // Listen for config changes to keep services in sync
    _config.addListener(_syncServiceSettings);

    if (!_config.isSalarySet) {
      _phase = AppPhase.unset;
      notifyListeners();
      return;
    }

    // Restore stats
    _todayCoins = _statsRepo.getTodayCoins();
    _monthCoins = _statsRepo.getMonthCoins();
    _todayWorkSeconds = _statsRepo.getTodayWorkSeconds();

    _streak = _statsRepo.getStreak();
    _dailyGoal = _statsRepo.getDailyGoal();
    _achievements = _statsRepo.getAchievements();
    _calendarDays = _statsRepo.getCalendar();

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
      _backgroundAt = DateTime.now();
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
      _catchUpBackgroundTime();
      _startRunning(isResume: true);
    }
  }

  /// Calculate work time and coins earned while the app was in the background,
  /// and credit them retroactively.
  void _catchUpBackgroundTime() {
    final bgAt = _backgroundAt;
    if (bgAt == null) return;
    _backgroundAt = null;

    final elapsed = DateTime.now().difference(bgAt);
    if (elapsed.inSeconds < 60) return; // skip if less than 1 minute

    final salaryConfig = _config.salaryConfig;
    if (salaryConfig == null) return;

    // Credit work time (cap at 8 hours total to be safe)
    final catchUpSeconds =
        (elapsed.inSeconds).clamp(0, 8 * 3600 - _todayWorkSeconds);
    if (catchUpSeconds > 0) {
      _todayWorkSeconds += catchUpSeconds;
    }

    // Calculate and credit coins
    final perMinute = _calculator.perMinuteSalary(salaryConfig);
    final catchUpMinutes = catchUpSeconds ~/ 60;
    if (catchUpMinutes > 0) {
      final coins = _calculator.dropCoins(perMinute, catchUpMinutes);
      _todayCoins += coins;
      _monthCoins += coins;

      // Check gold bar synthesis
      final oldBars = (_monthCoins - coins) ~/ goldBarThreshold;
      final newBars = _monthCoins ~/ goldBarThreshold;
      if (newBars > oldBars) {
        _goldBarJustSynthesized = true;
        _audioService.playGoldBar();
        _hapticService.mediumImpact();
        _notificationService.checkGoldBarMilestone(newBars);
      }
    }

    notifyListeners();
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

    _dropTimer = Timer(
      _debugFastDrop
          ? Duration(seconds: _debugDropSeconds)
          : Duration(minutes: interval),
      _onDropIntervalElapsed,
    );
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
    final wasZero = _todayCoins == 0;

    _todayCoins += coins;
    _monthCoins += coins;

    // Add streak bonus (first drop of the day gets the bonus)
    if (_streak.streakBonusPerDay > 0 && wasZero) {
      _todayCoins += _streak.streakBonusPerDay;
      _monthCoins += _streak.streakBonusPerDay;
    }

    // Check daily goal
    if (_dailyGoal.isEnabled && !_dailyGoal.todayReached && _todayCoins >= _dailyGoal.targetCoins) {
      _dailyGoal = _dailyGoal.copyWith(todayReached: true);
      _statsRepo.setDailyGoal(_dailyGoal);
    }

    // Check gold bar synthesis
    final oldBars = oldMonthCoins ~/ goldBarThreshold;
    final newBars = _monthCoins ~/ goldBarThreshold;
    if (newBars > oldBars) {
      _goldBarJustSynthesized = true;
    }

    // Check gold bar achievements
    if (_monthCoins ~/ goldBarThreshold >= 10) _unlockAchievement('gold_digger');
    if ((_monthCoins + _statsRepo.getLastMonthCoins()) ~/ goldBarThreshold >= 50) _unlockAchievement('vault');

    // Audio + Haptic
    // Always play coin drop sound first
    _audioService.playCoinDrop();
    _hapticService.lightImpact();

    if (_goldBarJustSynthesized) {
      // Gold bar sound follows after coin drop with a short delay
      Future.delayed(const Duration(milliseconds: 400), () {
        _audioService.playGoldBar();
        _hapticService.mediumImpact();
      });
      _notificationService.checkGoldBarMilestone(newBars);
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

    // Update streak: mark today as active
    final today = _todayString();
    if (_streak.lastActiveDate != today) {
      _updateStreak(today);
    }

    // Check end-of-workday notification
    if (_todayWorkSeconds >= 8 * 3600) {
      _notificationService.scheduleEndOfWorkdayReminder();
    }

    notifyListeners();
  }

  // ─── Streak management ─────────────────────────────────

  void _updateStreak(String today) {
    final lastDate = _streak.lastActiveDate;
    if (lastDate.isEmpty) {
      _streak = _streak.copyWith(currentStreak: 1);
    } else {
      final last = DateTime.tryParse(lastDate);
      final curr = DateTime.tryParse(today);
      if (last != null && curr != null) {
        final diff = curr.difference(last).inDays;
        if (diff == 1) {
          _streak = _streak.copyWith(currentStreak: _streak.currentStreak + 1);
        } else {
          // Reset unless only weekends were skipped
          bool onlyWeekendGap = true;
          for (var d = last.add(const Duration(days: 1));
               d.isBefore(curr);
               d = d.add(const Duration(days: 1))) {
            if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
              onlyWeekendGap = false;
              break;
            }
          }
          _streak = _streak.copyWith(
            currentStreak: onlyWeekendGap ? _streak.currentStreak + 1 : 1,
          );
        }
      }
    }
    if (_streak.currentStreak > _streak.longestStreak) {
      _streak = _streak.copyWith(longestStreak: _streak.currentStreak);
    }
    _streak = _streak.copyWith(
      lastActiveDate: today,
      streakBonusPerDay: StreakRecord.bonusForStreak(_streak.currentStreak),
    );
    _checkStreakAchievements();
    _statsRepo.setStreak(_streak);
  }

  // ─── Achievement checks ────────────────────────────────

  void _checkStreakAchievements() {
    final count = _streak.currentStreak;
    if (count >= 7) _unlockAchievement('week_streak');
    if (count >= 20) _unlockAchievement('full_attendance');
    if (count >= 50) _unlockAchievement('iron_man');
  }

  void _unlockAchievement(String id) {
    final idx = _achievements.indexWhere((a) => a.id == id);
    if (idx == -1 || _achievements[idx].isUnlocked) return;
    _achievements[idx] = _achievements[idx].unlock();
    _statsRepo.setAchievements(_achievements);
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

    final today = _todayString();
    _statsRepo.setCalendarDay(CalendarDay(
      date: today,
      coins: _todayCoins,
      workSeconds: _todayWorkSeconds,
      goldBars: _todayCoins ~/ goldBarThreshold,
    ));
  }

  // ─── Cross-day / month handlers ────────────────────────

  void _onDayChanged() {
    _statsRepo.setYesterdayCoins(_todayCoins);
    _todayCoins = 0;
    _todayWorkSeconds = 0;
    _dailyGoal = _dailyGoal.copyWith(todayReached: false);
    _statsRepo.setDailyGoal(_dailyGoal);
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

  // ─── Service settings sync ──────────────────────────────

  void _syncServiceSettings() {
    _audioService.setEnabled(_config.soundEnabled);
    _hapticService.setEnabled(_config.hapticEnabled);
    _notificationService.setEnabled(_config.notificationsEnabled);
  }

  @override
  void dispose() {
    _config.removeListener(_syncServiceSettings);
    _workTimer.dispose();
    _dropTimer?.cancel();
    _persistTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
