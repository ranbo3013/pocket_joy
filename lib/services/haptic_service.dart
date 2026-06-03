import 'package:flutter/services.dart';

/// Stub haptic feedback service. Full implementation in Phase 11.
class HapticService {
  bool _hapticEnabled = true;

  void setEnabled(bool enabled) {
    _hapticEnabled = enabled;
  }

  void lightImpact() {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {
      // Silent fail
    }
  }

  void mediumImpact() {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {
      // Silent fail
    }
  }
}
