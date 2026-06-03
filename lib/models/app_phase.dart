/// Application phase state machine.
/// Reference: PRD §5.1
enum AppPhase {
  /// Salary not yet set
  unset,

  /// Normal operation — timer running, coin drops active
  running,

  /// User manually paused
  paused,

  /// User clocked out for the day
  offWork,
}

extension AppPhaseDisplay on AppPhase {
  String get label {
    switch (this) {
      case AppPhase.unset:
        return '未设置';
      case AppPhase.running:
        return '运行中';
      case AppPhase.paused:
        return '暂停中';
      case AppPhase.offWork:
        return '已下班';
    }
  }
}
