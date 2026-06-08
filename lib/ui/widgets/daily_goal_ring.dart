import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/design_tokens.dart';
import '../../models/achievement.dart';

class DailyGoalRing extends StatelessWidget {
  final DailyGoal goal;
  final int currentCoins;

  const DailyGoalRing({
    super.key,
    required this.goal,
    required this.currentCoins,
  });

  @override
  Widget build(BuildContext context) {
    if (!goal.isEnabled) return const SizedBox.shrink();

    final progress = (currentCoins / goal.targetCoins).clamp(0.0, 1.0);
    final reached = goal.todayReached;
    final color = reached ? AppColors.success : AppColors.goldPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(48, 48),
                painter: _RingPainter(progress: progress, color: color),
              ),
              Text(reached ? '🎉' : '🎯', style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$currentCoins/${goal.targetCoins}',
          style: AppTextStyles.small.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      progress != old.progress || color != old.color;
}
