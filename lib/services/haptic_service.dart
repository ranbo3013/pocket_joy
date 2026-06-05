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
}
