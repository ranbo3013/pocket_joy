import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../config/design_tokens.dart';

/// Animated background with two slowly rotating blurred light orbs.
/// Pure code implementation — no asset dependency.
class BackgroundGlow extends StatefulWidget {
  const BackgroundGlow({super.key});

  @override
  State<BackgroundGlow> createState() => _BackgroundGlowState();
}

class _BackgroundGlowState extends State<BackgroundGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Orb 1 cycle
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t1 = _controller.value;
        final t2 = (_controller.value * 20 / 15) % 1.0;

        return Stack(
          children: [
            // Orb 1: Warm gold
            Positioned(
              left: size.width * 0.1 + sin(t1 * 2 * pi) * size.width * 0.15,
              top: size.height * 0.15 + cos(t1 * 2 * pi) * size.height * 0.10,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      AppColors.goldGlow.withOpacity(AppColors.glowOpacityGold),
                ),
              ),
            ),
            // Orb 2: Teal
            Positioned(
              left: size.width * 0.35 + cos(t2 * 2 * pi) * size.width * 0.12,
              top: size.height * 0.25 + sin(t2 * 2 * pi) * size.height * 0.08,
              child: Container(
                width: size.width * 0.4,
                height: size.width * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentTeal
                      .withOpacity(AppColors.glowOpacityTeal),
                ),
              ),
            ),
            // Blur overlay
            ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }
}
