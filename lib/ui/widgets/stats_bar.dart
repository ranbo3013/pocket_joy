import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../providers/game_provider.dart';

/// Bottom stats bar: today coins, month gold bars, work time.
class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.monetization_on_outlined,
                value: '${game.todayCoins}',
                label: '今日金币',
                valueColor: AppColors.goldPrimary,
              ),
              _StatItem(
                icon: Icons.diamond_outlined,
                value: '${game.monthGoldBars}',
                label: '本月金条',
                valueColor: AppColors.success,
                subLabel: game.monthRemainingCoins > 0
                    ? '+${game.monthRemainingCoins} 金币'
                    : null,
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
  final String? subLabel;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.valueColor,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.display.copyWith(
            fontSize: 24,
            color: valueColor,
          ),
        ),
        if (subLabel != null)
          Text(subLabel!, style: AppTextStyles.small),
        Text(label, style: AppTextStyles.small),
      ],
    );
  }
}
