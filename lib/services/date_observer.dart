import '../config/constants.dart';

/// Detects cross-day, cross-month, and system time rollback.
/// Wraps WidgetsBindingObserver for app lifecycle + periodic polling.
class DateObserver {
  String _lastKnownDate;
  DateTime _lastKnownTime;

  DateObserver()
      : _lastKnownDate = _today(),
        _lastKnownTime = DateTime.now();

  /// Callback when day changes (while app is foreground).
  void Function()? onDayChanged;

  /// Callback when month changes.
  void Function()? onMonthChanged;

  /// Callback when system time rolls back more than threshold.
  void Function()? onTimeRollback;

  /// Previous date string for comparison.
  String get lastKnownDate => _lastKnownDate;

  /// Call on each app tick to detect timestamp anomalies.
  /// Checks for cross-day at midnight and time rollback.
  void check() {
    final now = DateTime.now();

    // Detect time rollback (> threshold seconds backwards)
    final diff = now.difference(_lastKnownTime);
    if (diff.inSeconds < -timeRollbackThresholdSeconds) {
      onTimeRollback?.call();
    }
    _lastKnownTime = now;

    // Detect date change
    final today = _today();
    if (today != _lastKnownDate) {
      final wasMonth = _monthFromDate(_lastKnownDate);
      final newMonth = _monthFromDate(today);

      _lastKnownDate = today;
      onDayChanged?.call();

      if (wasMonth != newMonth) {
        onMonthChanged?.call();
      }
    }
  }

  /// Called when app comes to foreground. Resyncs date state.
  void onForeground() {
    final today = _today();
    if (today != _lastKnownDate) {
      final wasMonth = _monthFromDate(_lastKnownDate);
      final newMonth = _monthFromDate(today);

      _lastKnownDate = today;
      onDayChanged?.call();

      if (wasMonth != newMonth) {
        onMonthChanged?.call();
      }
    }
    _lastKnownTime = DateTime.now();
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static int _monthFromDate(String date) {
    final parts = date.split('-');
    return int.parse(parts[1]);
  }
}
