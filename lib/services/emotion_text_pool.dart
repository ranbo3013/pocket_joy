import 'dart:math';

/// Emotion tier based on coin amount.
enum EmotionTier { small, medium, large }

/// A single emotion text entry.
class EmotionText {
  final String text;
  final EmotionTier tier;

  const EmotionText({required this.text, required this.tier});
}

/// Tiered emotion message pool with anti-repeat logic.
/// Reference: PRD §5.3.1
class EmotionTextPool {
  final Random _random;

  String? _lastText;

  static const _tierThreshold = 30; // small: 1-30
  static const _tierThresholdMedium = 100; // medium: 31-100, large: 100+

  static const _smallPool = [
    '叮！一颗快乐入账 ✨',
    '这秒没白过',
    '叮当！口袋又重了一点点',
    '又攒到一小口甜',
  ];

  static const _mediumPool = [
    '摸鱼也是生产力 🐟',
    '把上班时间折成糖纸 🍬',
    '别急，快乐要一粒一粒攒',
    '今日进度条又往前跳了一格',
  ];

  static const _largePool = [
    '老板不知道，但口袋知道',
    '金灿灿的，像周五下午四点 🌇',
    '这间隔，值了',
    '哗啦——口袋发出满足的声响',
  ];

  EmotionTextPool({Random? random}) : _random = random ?? Random();

  /// Pick an emotion text based on coin amount.
  /// Never returns the same text twice in a row.
  /// If tier pool exhausted (single item already used), cross-tier fallback.
  EmotionText? pick(int coinAmount) {
    final tier = coinAmount <= _tierThreshold
        ? EmotionTier.small
        : coinAmount <= _tierThresholdMedium
            ? EmotionTier.medium
            : EmotionTier.large;

    final pool = _poolForTier(tier);
    String text;

    // Try same-tier, excluding last
    final candidates = pool.where((t) => t != _lastText).toList();

    if (candidates.isNotEmpty) {
      text = candidates[_random.nextInt(candidates.length)];
    } else {
      // Same-tier exhausted, try cross-tier
      final nextTier = _nextTier(tier);
      final nextPool = _poolForTier(nextTier);
      final nextCandidates = nextPool.where((t) => t != _lastText).toList();
      if (nextCandidates.isNotEmpty) {
        text = nextCandidates[_random.nextInt(nextCandidates.length)];
      } else {
        // Everything exhausted, just pick anything
        text = pool[_random.nextInt(pool.length)];
      }
    }

    _lastText = text;
    return EmotionText(text: text, tier: tier);
  }

  List<String> _poolForTier(EmotionTier tier) {
    switch (tier) {
      case EmotionTier.small:
        return _smallPool;
      case EmotionTier.medium:
        return _mediumPool;
      case EmotionTier.large:
        return _largePool;
    }
  }

  EmotionTier _nextTier(EmotionTier current) {
    switch (current) {
      case EmotionTier.small:
        return EmotionTier.medium;
      case EmotionTier.medium:
        return EmotionTier.large;
      case EmotionTier.large:
        return EmotionTier.small;
    }
  }
}
