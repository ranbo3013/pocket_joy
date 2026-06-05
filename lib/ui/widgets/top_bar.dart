import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../config/routes.dart';
import '../../models/app_phase.dart';
import '../../providers/game_provider.dart';
import '../../utils/extensions.dart';

/// Top bar: work time + phase indicator + settings gear.
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('已工作', style: AppTextStyles.small),
                  const SizedBox(height: 2),
                  Text(
                    formatSeconds(game.todayWorkSeconds),
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 20,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _PhaseChip(phase: game.phase),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/settings.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pushNamed(AppRoutes.settings);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final AppPhase phase;
  const _PhaseChip({required this.phase});

  @override
  Widget build(BuildContext context) {
    final chipColor = switch (phase) {
      AppPhase.running => AppColors.goldPrimary,
      AppPhase.paused => AppColors.textSecondary,
      AppPhase.offWork || AppPhase.unset => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: chipColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(phase.label,
              style: AppTextStyles.small.copyWith(color: chipColor)),
        ],
      ),
    );
  }
}
