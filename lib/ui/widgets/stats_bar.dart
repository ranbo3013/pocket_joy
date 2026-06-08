import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../providers/game_provider.dart';
import 'streak_fire.dart';

/// Bottom stats bar: today coins, month gold bars, work time.
class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        // Pick gold bar image: highlight when a bar was just synthesized
        final goldBarAsset = game.goldBarJustSynthesized
            ? 'assets/images/gold_bar_highlight.png'
            : 'assets/images/gold_bar.png';

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StreakFire(streak: game.streak.currentStreak),
              _CoinStatItem(
                value: '${game.todayCoins}',
                label: '今日金币',
                valueColor: AppColors.goldPrimary,
              ),
              _GoldBarStatItem(
                assetPath: goldBarAsset,
                value: '${game.monthGoldBars}',
                label: '本月金条',
                valueColor: AppColors.success,
              ),
              _StatItem(
                icon: Icons.timer_outlined,
                value: _formatWorkTime(game.todayWorkSeconds),
                label: '今日工时',
                valueColor: AppColors.accentTeal,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatWorkTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color valueColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return _buildLayout(
      icon: Icon(icon, color: AppColors.textMuted, size: 18),
      value: value,
      label: label,
      valueColor: valueColor,
    );
  }
}

class _CoinStatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _CoinStatItem({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return _buildLayout(
      icon: Image.asset(
        'assets/images/coin_gold.png',
        width: 22,
        height: 22,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.monetization_on_outlined, color: AppColors.textMuted, size: 18),
      ),
      value: value,
      label: label,
      valueColor: valueColor,
    );
  }
}

class _GoldBarStatItem extends StatelessWidget {
  final String assetPath;
  final String value;
  final String label;
  final Color valueColor;

  const _GoldBarStatItem({
    required this.assetPath,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return _buildLayout(
      icon: Image.asset(
        assetPath,
        width: 28,
        height: 28,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.diamond_outlined, color: AppColors.textMuted, size: 18),
      ),
      value: value,
      label: label,
      valueColor: valueColor,
    );
  }
}

/// Shared layout for all stat items.
Widget _buildLayout({
  required Widget icon,
  required String value,
  required String label,
  required Color valueColor,
  String? subLabel,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      icon,
      const SizedBox(height: AppSpacing.xs),
      Text(
        value,
        style: AppTextStyles.display.copyWith(
          fontSize: 24,
          color: valueColor,
        ),
      ),
      if (subLabel != null) Text(subLabel, style: AppTextStyles.small),
      Text(label, style: AppTextStyles.small),
    ],
  );
}
