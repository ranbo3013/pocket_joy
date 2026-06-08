import 'package:flutter/material.dart';
import '../../config/design_tokens.dart';

class StreakFire extends StatelessWidget {
  final int streak;
  const StreakFire({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak < 3) return const SizedBox.shrink();
    final isGold = streak >= 10;
    final color = isGold ? AppColors.goldPrimary : Colors.orange;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🔥', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 2),
        Text(
          '$streak',
          style: AppTextStyles.small.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
