import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                      icon: Icons.pause_rounded,
                      label: '暂停',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        game.pause();
                      },
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _ControlButton(
                      icon: Icons.logout_rounded,
                      label: '打卡下班',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        game.clockOut();
                      },
                    ),
                  ] else if (game.phase == AppPhase.paused) ...[
                    _ControlButton(
                      icon: Icons.play_arrow_rounded,
                      label: '继续',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        game.resume();
                      },
                    ),
                  ] else if (game.phase == AppPhase.offWork) ...[
                    _ControlButton(
                      icon: Icons.refresh_rounded,
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
                    icon: config.soundEnabled
                        ? Icons.volume_up_outlined
                        : Icons.volume_off_outlined,
                    label: '音效',
                    active: config.soundEnabled,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      config.toggleSound();
                    },
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _ToggleButton(
                    icon: config.hapticEnabled
                        ? Icons.vibration_outlined
                        : Icons.vibration_outlined,
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
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
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
            Icon(icon, color: AppColors.textPrimary, size: 28),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.small),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: active ? 1.0 : 0.4,
        child: Column(
          children: [
            Icon(icon,
                color: active ? AppColors.goldPrimary : AppColors.textMuted,
                size: 24),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.small),
          ],
        ),
      ),
    );
  }
}
