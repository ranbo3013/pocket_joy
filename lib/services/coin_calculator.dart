import '../models/salary_config.dart';

/// Core coin calculation logic.
/// Reference: PRD §6
class CoinCalculator {
  const CoinCalculator();

  /// Compute per-minute salary from config.
  double perMinuteSalary(SalaryConfig config) {
    return config.perMinuteSalary;
  }

  /// Calculate coins for a single drop based on actual elapsed interval.
  /// Returns at least 1 coin if the computed result rounds to 0.
  /// Reference: PRD §6.2
  int dropCoins(double perMinute, int actualIntervalMinutes) {
    final raw = perMinute * actualIntervalMinutes;
    final rounded = raw.round();
    return rounded > 0 ? rounded : 1;
  }
}
