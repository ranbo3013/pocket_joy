/// Runtime game statistics.
class GameStats {
  final int todayCoins;
  final int monthCoins;
  final int todayWorkSeconds;

  const GameStats({
    this.todayCoins = 0,
    this.monthCoins = 0,
    this.todayWorkSeconds = 0,
  });

  int get todayGoldBars => todayCoins ~/ 1000;
  int get todayRemainingCoins => todayCoins % 1000;
  int get monthGoldBars => monthCoins ~/ 1000;
  int get monthRemainingCoins => monthCoins % 1000;

  GameStats copyWith({
    int? todayCoins,
    int? monthCoins,
    int? todayWorkSeconds,
  }) {
    return GameStats(
      todayCoins: todayCoins ?? this.todayCoins,
      monthCoins: monthCoins ?? this.monthCoins,
      todayWorkSeconds: todayWorkSeconds ?? this.todayWorkSeconds,
    );
  }
}
