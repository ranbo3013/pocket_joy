import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../providers/animation_provider.dart';

/// Full-screen overlay for coin drop animation.
///
/// The coin:
/// - Falls along a bezier trajectory from a random top position
///   down to the bag mouth.
/// - Spins (Z-axis) and flips (X-axis) as it tumbles through the air.
/// - Shrinks near the end to simulate entering the bag.
/// - Emits a small sparkle burst on impact.
class CoinDropOverlay extends StatefulWidget {
  const CoinDropOverlay({super.key});

  @override
  State<CoinDropOverlay> createState() => _CoinDropOverlayState();
}

class _CoinDropOverlayState extends State<CoinDropOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Randomized per-drop start position
  double _startX = 0.5;
  double _startY = 0.2;

  // Pre-computed random sparkle angles for the impact burst
  final List<double> _sparkleAngles = [];
  static const int _sparkleCount = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.read<AnimationProvider>().onCoinDropComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    // Randomize start position and sparkle angles on each drop
    _startX = 0.35 + Random().nextDouble() * 0.3; // 0.35–0.65
    _startY = 0.05 + Random().nextDouble() * 0.1; // 0.05–0.15
    _sparkleAngles.clear();
    for (int i = 0; i < _sparkleCount; i++) {
      _sparkleAngles.add(Random().nextDouble() * 2 * pi);
    }
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimationProvider>(
      builder: (context, anim, _) {
        if (!anim.isCoinDropping) {
          return const SizedBox.shrink();
        }

        // Start animation on next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (anim.isCoinDropping && !_controller.isAnimating) {
            _startAnimation();
          }
        });

        final size = MediaQuery.of(context).size;

        return IgnorePointer(
          child: SizedBox.expand(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final t = _animation.value;
                if (t <= 0 || t >= 1.0) return const SizedBox.shrink();

                // Target: bag mouth center
                const endX = 0.5;
                const endY = 0.40;

                // Bezier curve: start → mid control point → bag mouth
                final oneMinusT = 1.0 - t;
                final x = oneMinusT * oneMinusT * _startX +
                    2 * oneMinusT * t * ((_startX + endX) / 2) +
                    t * t * endX;
                final y = oneMinusT * oneMinusT * _startY +
                    2 * oneMinusT * t * (endY * 0.5) +
                    t * t * endY;

                // Scale down as coin enters bag
                final scale = 1.0 - t * 0.5;

                // Tumble: Z-axis spin (2 full rotations) + X-axis wobble
                final spinAngle = t * 4 * pi; // 720° spin
                final flipAngle = sin(t * pi) * 0.3; // gentle wobble

                // Impact sparkles: only show near the end (t > 0.85)
                final sparkleProgress =
                    ((t - 0.85) / 0.15).clamp(0.0, 1.0);
                final sparkleOpacity = (1.0 - sparkleProgress);

                return Stack(
                  children: [
                    // Impact sparkles at bag mouth
                    if (sparkleProgress > 0)
                      ..._buildSparkles(
                        size.width * endX,
                        size.height * endY,
                        sparkleProgress,
                        sparkleOpacity,
                      ),
                    // Falling coin
                    Positioned(
                      left: x * size.width - 48,
                      top: y * size.height - 48,
                      child: Transform.scale(
                        scale: scale,
                        child: Transform(
                          transform: Matrix4.identity()
                            ..rotateZ(spinAngle)
                            ..rotateX(flipAngle),
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: Lottie.asset(
                              'assets/images/coins_drop.lottie',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _fallbackCoin(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Small golden sparkles that burst outward from the bag mouth on impact.
  List<Widget> _buildSparkles(
    double centerX,
    double centerY,
    double progress,
    double opacity,
  ) {
    return List.generate(_sparkleCount, (i) {
      final angle = _sparkleAngles[i];
      final distance = progress * 60; // burst radius 60px
      final dx = cos(angle) * distance;
      final dy = sin(angle) * distance;
      final sparkleSize = (1.0 - progress) * 8 + 2;

      return Positioned(
        left: centerX + dx - sparkleSize / 2,
        top: centerY + dy - sparkleSize / 2,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: sparkleSize,
            height: sparkleSize,
            decoration: BoxDecoration(
              color: AppColors.goldGlow,
              borderRadius: BorderRadius.circular(sparkleSize * 0.3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldPrimary.withAlpha(180),
                  blurRadius: sparkleSize * 2,
                  spreadRadius: sparkleSize * 0.3,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Fallback golden circle if Lottie file missing.
  Widget _fallbackCoin() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFD4A843),
      ),
    );
  }
}
