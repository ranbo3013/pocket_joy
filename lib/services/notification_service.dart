import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Local notification service for PocketJoy.
///
/// Handles pause reminders, coin/gold-bar milestones, and
/// end-of-workday nudges. All notifications are local-only;
/// no network or remote push in V1.0.
///
/// Reference: PRD §13

// ─── Notification IDs ──────────────────────────────────────

/// Each notification type gets a fixed ID so scheduling
/// the same type again replaces the previous one.
const _pauseReminderId = 1001;
const _endOfWorkdayId = 1002;
const _coinMilestoneId = 1003;
const _goldBarMilestoneId = 1004;

// ─── Android Channel Constants ─────────────────────────────

const _pauseChannelId = 'pocketjoy_pause';
const _pauseChannelName = '暂停提醒';
const _pauseChannelDesc = '长时间暂停时提醒你继续积累快乐';

const _milestoneChannelId = 'pocketjoy_milestone';
const _milestoneChannelName = '里程碑';
const _milestoneChannelDesc = '金币和金条达成里程碑时通知';

const _workdayChannelId = 'pocketjoy_workday';
const _workdayChannelName = '下班提醒';
const _workdayChannelDesc = '完成一天工作后的温馨提醒';

// ─── Top-level callback for terminated app notification tap ─

/// Called by the OS when the user taps a notification while
/// the app is terminated. Must be a top-level function.
@pragma('vm:entry-point')
void notificationTapOnTerminatedApp(NotificationResponse response) {
  // V1.0: simply open the app — no deep linking needed.
  debugPrint(
      'PocketJoy: notification tapped from terminated — ${response.payload}');
}

// ─── Service ───────────────────────────────────────────────

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _notificationsEnabled = true;
  bool _initialized = false;
  bool _tzInitialized = false;

  bool get isInitialized => _initialized;

  // ─── Initialization ──────────────────────────────────────

  Future<void> init() async {
    // ── Android settings ────────────────────────────────
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // ── iOS settings ────────────────────────────────────
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channels (safe to call
    // multiple times — subsequent calls are no-ops).
    await _createChannels();

    _initialized = true;
  }

  /// Must be called after timezone database is initialized.
  /// Call from main.dart after tz.initializeTimeZones().
  void markTimezoneReady() {
    _tzInitialized = true;
  }

  /// Create Android notification channels.
  Future<void> _createChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _pauseChannelId,
        _pauseChannelName,
        description: _pauseChannelDesc,
        importance: Importance.defaultImportance,
        enableVibration: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _milestoneChannelId,
        _milestoneChannelName,
        description: _milestoneChannelDesc,
        importance: Importance.high,
        enableVibration: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _workdayChannelId,
        _workdayChannelName,
        description: _workdayChannelDesc,
        importance: Importance.defaultImportance,
      ),
    );
  }

  // ─── Settings ────────────────────────────────────────────

  void setEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    if (!enabled) {
      cancelAll();
    }
  }

  // ─── Permissions ─────────────────────────────────────────

  /// Request notification permissions.
  /// On Android 13+, requests POST_NOTIFICATIONS.
  /// On iOS, requests alert/badge/sound.
  Future<bool> requestPermission() async {
    if (!_initialized) return false;

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted =
          await androidPlugin.requestNotificationsPermission();
      if (granted == null || !granted) return false;
    }

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == null) return false;
      return granted;
    }

    return true;
  }

  // ─── Pause Reminder ──────────────────────────────────────

  /// Schedule a reminder 2 hours after being paused.
  /// Cancels any previous pause reminder first.
  Future<void> schedulePauseReminder() async {
    if (!_notificationsEnabled || !_initialized) return;
    if (!_tzInitialized) return; // timezone not ready → skip scheduling

    try {
      await _plugin.cancel(_pauseReminderId);

      final scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(hours: 2));

      await _plugin.zonedSchedule(
        _pauseReminderId,
        '口袋在等你',
        '你已经暂停 2 小时了，继续积累快乐吧 ☕️',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _pauseChannelId,
            _pauseChannelName,
            channelDescription: _pauseChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Scheduling may fail if permissions not granted
    }
  }

  /// Cancel any pending pause reminder.
  Future<void> cancelPauseReminder() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_pauseReminderId);
    } catch (_) {}
  }

  // ─── Coin Milestones ─────────────────────────────────────

  /// Fire coin milestone notification at 500 / 1000 / 2000.
  Future<void> checkCoinMilestones(int todayCoins) async {
    if (!_notificationsEnabled || !_initialized) return;

    int? milestone;
    if (todayCoins == 500) {
      milestone = 500;
    } else if (todayCoins == 1000) {
      milestone = 1000;
    } else if (todayCoins == 2000) {
      milestone = 2000;
    }

    if (milestone == null) return;

    try {
      await _plugin.show(
        _coinMilestoneId,
        '🎉 里程碑达成',
        '今天已累积 $milestone 枚金币！',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _milestoneChannelId,
            _milestoneChannelName,
            channelDescription: _milestoneChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (_) {}
  }

  // ─── Gold Bar Milestones ─────────────────────────────────

  /// Fire a celebration notification for gold bar milestones.
  /// Triggers on first gold bar and every 5 thereafter.
  Future<void> checkGoldBarMilestone(int monthGoldBars) async {
    if (!_notificationsEnabled || !_initialized) return;
    if (monthGoldBars <= 0) return;

    final isFirst = monthGoldBars == 1;
    final isFiveMultiple = monthGoldBars % 5 == 0;

    if (!isFirst && !isFiveMultiple) return;

    try {
      final message = isFirst
          ? '第一根金条！继续加油 🔥'
          : '本月已合成 $monthGoldBars 根金条，太厉害了！';

      await _plugin.show(
        _goldBarMilestoneId,
        '🏆 金条里程碑',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _milestoneChannelId,
            _milestoneChannelName,
            channelDescription: _milestoneChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (_) {}
  }

  // ─── End of Workday Reminder ─────────────────────────────

  /// Show a notification after 8 hours of accumulated work.
  Future<void> scheduleEndOfWorkdayReminder() async {
    if (!_notificationsEnabled || !_initialized) return;

    try {
      // Check if already shown today
      final pending = await _plugin.pendingNotificationRequests();
      if (pending.any((n) => n.id == _endOfWorkdayId)) return;

      await _plugin.show(
        _endOfWorkdayId,
        '🌙 辛苦了',
        '已经工作 8 小时，记得打卡下班哦',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _workdayChannelId,
            _workdayChannelName,
            channelDescription: _workdayChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
      );
    } catch (_) {}
  }

  // ─── Cancel All ──────────────────────────────────────────

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // ─── Internal ────────────────────────────────────────────

  /// Handle notification tap when app is in foreground/background.
  void _onNotificationTap(NotificationResponse response) {
    debugPrint(
        'PocketJoy: notification tapped — id=${response.id}, '
        'payload=${response.payload}');
    // V1.0: tapping any notification simply opens the app.
    // No deep-linking needed.
  }
}
