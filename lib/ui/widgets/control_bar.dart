import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../models/app_phase.dart';
import '../../providers/config_provider.dart';
import '../../providers/game_provider.dart';

/// Bottom control bar: pause/resume, clock out / restart, mute, haptic.
class ControlBar extends StatelessWidget {
  const ControlBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, ConfigProvider>(
      builder: (context, game, config, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary action row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (game.phase == AppPhase.running) ...[
                    _ControlButton(
                      assetPath: 'assets/icons/pause.svg',
                      label: '暂停',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        game.pause();
                      },
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _ControlButton(
                      assetPath: 'assets/icons/off_work.svg',
                      label: '打卡下班',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        game.clockOut();
                      },
                    ),
                  ] else if (game.phase == AppPhase.paused) ...[
                    _ControlButton(
                      assetPath: 'assets/icons/play.svg',
                      label: '继续',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        game.resume();
                      },
                    ),
                  ] else if (game.phase == AppPhase.offWork) ...[
                    _ControlButton(
                      assetPath: 'assets/icons/play.svg',
                      label: '重新开始',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        game.restart();
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Sound / Haptic toggles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ToggleButton(
                    assetPath: config.soundEnabled
                        ? 'assets/icons/sound_on.svg'
                        : 'assets/icons/sound_off.svg',
                    label: '音效',
                    active: config.soundEnabled,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      config.toggleSound();
                    },
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _ToggleButton(
                    assetPath: config.hapticEnabled
                        ? 'assets/icons/haptic_on.svg'
                        : 'assets/icons/haptic_off.svg',
                    label: '震动',
                    active: config.hapticEnabled,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      config.toggleHaptic();
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

class _ControlButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgSecondary,
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              assetPath,
              width: 28,
              height: 28,
              colorFilter: const ColorFilter.mode(
                AppColors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.small),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.assetPath,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.goldPrimary : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: active ? 1.0 : 0.4,
        child: Column(
          children: [
            SvgPicture.asset(
              assetPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.small),
          ],
        ),
      ),
    );
  }
}
