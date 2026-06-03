/// Stub notification service. Full implementation in Phase 11.
/// Reference: PRD §13
class NotificationService {
  bool _notificationsEnabled = true;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    // TODO Phase 11: Initialize flutter_local_notifications
    _initialized = true;
  }

  void setEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  Future<void> requestPermission() async {
    // TODO Phase 11
  }

  Future<void> schedulePauseReminder() async {
    if (!_notificationsEnabled) return;
    // TODO Phase 11: schedule 2h pause reminder
  }

  Future<void> cancelPauseReminder() async {
    // TODO Phase 11
  }

  Future<void> checkCoinMilestones(int todayCoins) async {
    if (!_notificationsEnabled) return;
    // TODO Phase 11: 500 / 1000 / 2000 milestones
  }

  Future<void> scheduleEndOfWorkdayReminder() async {
    if (!_notificationsEnabled) return;
    // TODO Phase 11: after 8 hours
  }

  Future<void> checkGoldBarMilestone(int monthGoldBars) async {
    if (!_notificationsEnabled) return;
    // TODO Phase 11: every 5 gold bars
  }

  Future<void> cancelAll() async {
    // TODO Phase 11
  }
}
