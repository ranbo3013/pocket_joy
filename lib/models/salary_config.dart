/// Salary configuration.
class SalaryConfig {
  final double afterTax;
  final int workdays;
  final int dailyHours;

  const SalaryConfig({
    required this.afterTax,
    required this.workdays,
    this.dailyHours = 8,
  });

  /// Per-minute salary in local currency units.
  double get perMinuteSalary =>
      afterTax / workdays / dailyHours / 60;

  SalaryConfig copyWith({
    double? afterTax,
    int? workdays,
    int? dailyHours,
  }) {
    return SalaryConfig(
      afterTax: afterTax ?? this.afterTax,
      workdays: workdays ?? this.workdays,
      dailyHours: dailyHours ?? this.dailyHours,
    );
  }
}
