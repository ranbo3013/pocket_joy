/// Random interval configuration.
class IntervalConfig {
  final int minMinutes;
  final int maxMinutes;

  const IntervalConfig({
    required this.minMinutes,
    required this.maxMinutes,
  });

  IntervalConfig copyWith({int? minMinutes, int? maxMinutes}) {
    return IntervalConfig(
      minMinutes: minMinutes ?? this.minMinutes,
      maxMinutes: maxMinutes ?? this.maxMinutes,
    );
  }
}
