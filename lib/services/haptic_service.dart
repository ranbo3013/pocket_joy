import 'package:flutter/services.dart';

/// Haptic feedback service for PocketJoy.
///
/// Wraps Flutter's built-in [HapticFeedback] API to provide
/// light/medium/heavy impact feedback synced with coin drops
/// and gold bar synthesis events.
class HapticService {
  bool _hapticEnabled = true;

  // ─── Settings ────────────────────────────────────────────

  void setEnabled(bool enabled) {
    _hapticEnabled = enabled;
  }

  // ─── Feedback ────────────────────────────────────────────

  /// Light tap — regular coin drop.
  void lightImpact() {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {
      // Haptic not available on this platform — silent fail
    }
  }

  /// Medium tap — gold bar synthesis.
  void mediumImpact() {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {
      // Silent fail
    }
  }

  /// Heavy tap — milestone celebration (e.g. every 5 gold bars).
  void heavyImpact() {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {
      // Silent fail
    }
  }

  // ─── Pattern Feedback ─────────────────────────────────────

  /// Two quick light taps (150ms apart) — work start reminder.
  void patternWorkStart() {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.lightImpact();
      });
    } catch (_) {}
  }

  /// Three quick light taps (120ms apart) — break reminder.
  void patternBreakReminder() {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 120), () {
          HapticFeedback.lightImpact();
        });
      });
    } catch (_) {}
  }

  /// One medium tap — end of workday.
  void patternEndOfWorkday() {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Five quick light taps (100ms apart) — repeated custom alarm.
  void patternRepeatedAlarm() {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.lightImpact();
          Future.delayed(const Duration(milliseconds: 100), () {
            HapticFeedback.lightImpact();
            Future.delayed(const Duration(milliseconds: 100), () {
              HapticFeedback.lightImpact();
            });
          });
        });
      });
    } catch (_) {}
  }
}
