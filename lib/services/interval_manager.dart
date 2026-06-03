import 'dart:math';

/// Random interval manager with ×3 / ×0.5 alternation.
/// Reference: PRD §7
class IntervalManager {
  final Random _random;

  /// Seed multipliers alternate: ×3, ×0.5, ×3, ×0.5, ...
  static const _multipliers = [3.0, 0.5];

  IntervalManager({Random? random}) : _random = random ?? Random();

  /// Generate the first seed interval in [min, max].
  int generateSeed(int min, int max) {
    return _randomInRange(min, max);
  }

  /// Compute next interval based on previous, with clamping and
  /// boundary hit detection.
  ///
  /// Returns a record: (nextInterval, newMultiplierIndex, newLastBoundary)
  ({int nextInterval, int multiplierIndex, int? lastBoundary}) nextInterval(
    int previous,
    int min,
    int max,
    int multiplierIndex,
    int? lastBoundary,
  ) {
    final multiplier = _multipliers[multiplierIndex % _multipliers.length];
    final candidate = (previous * multiplier).round();

    final clamped = candidate.clamp(min, max);

    // Check if we hit a boundary
    final hitBoundary = (clamped == min || clamped == max) ? clamped : null;

    // If same boundary hit twice consecutively, re-randomize seed
    if (hitBoundary != null && hitBoundary == lastBoundary) {
      final newSeed = _randomInRange(min, max);
      return (
        nextInterval: newSeed,
        multiplierIndex: 0, // Reset after re-seed (PRD §7.1)
        lastBoundary: null,
      );
    }

    return (
      nextInterval: clamped,
      multiplierIndex: (multiplierIndex + 1) % _multipliers.length,
      lastBoundary: hitBoundary,
    );
  }

  int _randomInRange(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }
}
