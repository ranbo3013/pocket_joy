/// An achievement that can be earned by the user.
class Achievement {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool isHidden;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.isHidden = false,
    this.unlockedAt,
  });

  /// Whether this achievement has been unlocked.
  bool get isUnlocked => unlockedAt != null;

  /// Serialize to a JSON-compatible map for SharedPreferences persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'isHidden': isHidden,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  /// Deserialize from a JSON-compatible map.
  factory Achievement.fromJson(Map<String, dynamic> json) {
    final unlockedAtStr = json['unlockedAt'] as String?;
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      isHidden: json['isHidden'] as bool? ?? false,
      unlockedAt:
          unlockedAtStr != null ? DateTime.tryParse(unlockedAtStr) : null,
    );
  }

  /// Returns a copy of this achievement with [unlockedAt] set to now.
  Achievement unlock() {
    return Achievement(
      id: id,
      name: name,
      icon: icon,
      description: description,
      isHidden: isHidden,
      unlockedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          icon == other.icon &&
          description == other.description &&
          isHidden == other.isHidden &&
          unlockedAt == other.unlockedAt;

  @override
  int get hashCode => Object.hash(id, name, icon, description, isHidden, unlockedAt);
}

/// All achievements available in the app.
final List<Achievement> allAchievements = [
  const Achievement(
    id: 'early_bird',
    name: '早起鸟',
    icon: '🌅',
    description: '8:00前开工累计5次',
  ),
  const Achievement(
    id: 'week_streak',
    name: '一周全勤',
    icon: '🔥',
    description: '连续7天不间断',
  ),
  const Achievement(
    id: 'full_attendance',
    name: '满勤王',
    icon: '👑',
    description: '连续20个工作日',
    isHidden: true,
  ),
  const Achievement(
    id: 'gold_digger',
    name: '淘金者',
    icon: '⛏️',
    description: '月累计10根金条',
  ),
  const Achievement(
    id: 'vault',
    name: '金库',
    icon: '💎',
    description: '累计50根金条',
    isHidden: true,
  ),
  const Achievement(
    id: 'night_owl',
    name: '夜猫子',
    icon: '🦉',
    description: '22:00后还在工作累计3次',
  ),
  const Achievement(
    id: 'flash',
    name: '闪电侠',
    icon: '🏃',
    description: '休息结束30秒内回来',
    isHidden: true,
  ),
  const Achievement(
    id: 'iron_man',
    name: '铁人',
    icon: '💪',
    description: '连续50天',
    isHidden: true,
  ),
];

/// Tracks the user's current and longest streak.
class StreakRecord {
  final int currentStreak;
  final int longestStreak;
  final String lastActiveDate; // yyyy-MM-dd
  final int streakBonusPerDay;

  const StreakRecord({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate = '',
    this.streakBonusPerDay = 0,
  });

  /// Returns the bonus coins per day for the given [streak] length.
  ///
  /// - streak >= 20: 20 bonus coins/day
  /// - streak >= 10: 10 bonus coins/day
  /// - streak >= 5: 5 bonus coins/day
  /// - otherwise: 0
  static int bonusForStreak(int streak) {
    if (streak >= 20) return 20;
    if (streak >= 10) return 10;
    if (streak >= 5) return 5;
    return 0;
  }

  /// Serialize to a JSON-compatible map for SharedPreferences persistence.
  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate,
      'streakBonusPerDay': streakBonusPerDay,
    };
  }

  /// Deserialize from a JSON-compatible map.
  factory StreakRecord.fromJson(Map<String, dynamic> json) {
    return StreakRecord(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] as String? ?? '',
      streakBonusPerDay: json['streakBonusPerDay'] as int? ?? 0,
    );
  }

  StreakRecord copyWith({
    int? currentStreak,
    int? longestStreak,
    String? lastActiveDate,
    int? streakBonusPerDay,
  }) {
    return StreakRecord(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      streakBonusPerDay: streakBonusPerDay ?? this.streakBonusPerDay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakRecord &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          lastActiveDate == other.lastActiveDate &&
          streakBonusPerDay == other.streakBonusPerDay;

  @override
  int get hashCode =>
      Object.hash(currentStreak, longestStreak, lastActiveDate, streakBonusPerDay);
}

/// A daily coin-collection goal.
class DailyGoal {
  final int targetCoins; // 0 = disabled
  final bool todayReached;

  const DailyGoal({
    this.targetCoins = 0,
    this.todayReached = false,
  });

  /// Whether the daily goal is enabled (targetCoins > 0).
  bool get isEnabled => targetCoins > 0;

  /// Serialize to a JSON-compatible map for SharedPreferences persistence.
  Map<String, dynamic> toJson() {
    return {
      'targetCoins': targetCoins,
      'todayReached': todayReached,
    };
  }

  /// Deserialize from a JSON-compatible map.
  factory DailyGoal.fromJson(Map<String, dynamic> json) {
    return DailyGoal(
      targetCoins: json['targetCoins'] as int? ?? 0,
      todayReached: json['todayReached'] as bool? ?? false,
    );
  }

  DailyGoal copyWith({
    int? targetCoins,
    bool? todayReached,
  }) {
    return DailyGoal(
      targetCoins: targetCoins ?? this.targetCoins,
      todayReached: todayReached ?? this.todayReached,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyGoal &&
          runtimeType == other.runtimeType &&
          targetCoins == other.targetCoins &&
          todayReached == other.todayReached;

  @override
  int get hashCode => Object.hash(targetCoins, todayReached);
}

/// A single day's activity record for the calendar heatmap.
class CalendarDay {
  final String date; // yyyy-MM-dd
  final int coins;
  final int workSeconds;
  final int goldBars;

  const CalendarDay({
    required this.date,
    this.coins = 0,
    this.workSeconds = 0,
    this.goldBars = 0,
  });

  /// Serialize to a JSON-compatible map for SharedPreferences persistence.
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'coins': coins,
      'workSeconds': workSeconds,
      'goldBars': goldBars,
    };
  }

  /// Deserialize from a JSON-compatible map.
  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: json['date'] as String,
      coins: json['coins'] as int? ?? 0,
      workSeconds: json['workSeconds'] as int? ?? 0,
      goldBars: json['goldBars'] as int? ?? 0,
    );
  }

  CalendarDay copyWith({
    String? date,
    int? coins,
    int? workSeconds,
    int? goldBars,
  }) {
    return CalendarDay(
      date: date ?? this.date,
      coins: coins ?? this.coins,
      workSeconds: workSeconds ?? this.workSeconds,
      goldBars: goldBars ?? this.goldBars,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarDay &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          coins == other.coins &&
          workSeconds == other.workSeconds &&
          goldBars == other.goldBars;

  @override
  int get hashCode => Object.hash(date, coins, workSeconds, goldBars);
}
