import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../config/design_tokens.dart';

/// CustomPainter for coin drop bezier trajectory.
/// Draws a golden coin flying from random position into bag mouth.
class CoinDropPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Size screenSize;

  CoinDropPainter({
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    // Start: random X (20%-80% screen), above bag (upper 20%)
    final startX = screenSize.width * (0.2 + (Random().nextDouble() * 0.6));
    final startY = screenSize.height * 0.20;

    // End: bag mouth center (middle of screen, slightly above center)
    final endX = screenSize.width * 0.5;
    final endY = screenSize.height * 0.52;

    // Control point: between start and end with random horizontal offset
    final controlX = ui.lerpDouble(startX, endX, 0.5)! +
        (Random().nextDouble() - 0.5) * 60;
    final controlY = ui.lerpDouble(startY, endY, 0.3)!;

    // Quadratic bezier position
    final t = progress;
    final oneMinusT = 1.0 - t;
    final x = oneMinusT * oneMinusT * startX +
        2 * oneMinusT * t * controlX +
        t * t * endX;
    final y = oneMinusT * oneMinusT * startY +
        2 * oneMinusT * t * controlY +
        t * t * endY;

    // Rotation: cumulative over flight
    final rotation = progress * 4 * pi; // 2 full rotations

    // Scale: 1.0 → 0.3
    final scale = ui.lerpDouble(1.0, 0.3, progress)!;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);
    canvas.scale(scale);

    // Draw coin (golden circle with inner detail)
    final coinPaint = Paint()
      ..color = AppColors.goldPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, 0), 14, coinPaint);

    // Inner ring
    final ringPaint = Paint()
      ..color = AppColors.goldGlow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(const Offset(0, 0), 10, ringPaint);

    // Center symbol
    final centerPaint = Paint()
      ..color = AppColors.bgPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, 0), 4, centerPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(CoinDropPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
