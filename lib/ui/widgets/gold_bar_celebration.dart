import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../providers/animation_provider.dart';

/// Gold bar synthesis celebration — particle burst overlay.
///
/// When a gold bar is synthesized (1000 coins), 12 golden particles
/// explode outward from the bag area, then fade and shrink over ~1000ms.
/// Pure code animation — no Lottie dependency.
class GoldBarCelebration extends StatefulWidget {
  const GoldBarCelebration({super.key});

  @override
  State<GoldBarCelebration> createState() => _GoldBarCelebrationState();
}

class _GoldBarCelebrationState extends State<GoldBarCelebration>
    with TickerProviderStateMixin {
  final _random = Random();
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _generateParticles();
  }

  @override
  void dispose() {
    for (final p in _particles) {
      p.controller.dispose();
    }
    super.dispose();
  }

  void _generateParticles() {
    const count = 12;
    for (int i = 0; i < count; i++) {
      final angle = (2 * pi * i / count) + (_random.nextDouble() - 0.5) * 0.4;
      final speed = 60.0 + _random.nextDouble() * 80.0;
      final size = 4.0 + _random.nextDouble() * 6.0;
      final delay = _random.nextDouble() * 0.15; // 0–150ms stagger

      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );

      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
      );

      _particles.add(_Particle(
        controller: controller,
        animation: animation,
        angle: angle,
        speed: speed,
        size: size,
        delay: delay,
      ));
    }

    // Start all with stagger, then notify completion
    _startStaggered();
  }

  void _startStaggered() async {
    final futures = <Future<void>>[];
    for (final p in _particles) {
      futures.add(
        Future.delayed(Duration(milliseconds: (p.delay * 1000).round()), () {
          p.controller.forward();
          return p.controller;
        }),
      );
    }
    await Future.wait(futures);

    // Wait for the longest animation to finish
    await Future.delayed(const Duration(milliseconds: 1050));

    if (mounted) {
      context.read<AnimationProvider>().onGoldBarSynthesisComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: _particles.map((p) {
            return AnimatedBuilder(
              animation: p.animation,
              builder: (context, _) {
                final t = p.animation.value;
                if (t <= 0) return const SizedBox.shrink();

                final dx = cos(p.angle) * p.speed * t;
                final dy = sin(p.angle) * p.speed * t - 20 * t * t; // slight arc upward
                final scale = 1.0 - t;
                final opacity = 1.0 - t * t; // quadratic fade

                return Positioned(
                  left: MediaQuery.of(context).size.width / 2 + dx - p.size / 2,
                  top: MediaQuery.of(context).size.height * 0.45 +
                      dy -
                      p.size / 2,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale.clamp(0.0, 1.0),
                      child: _buildSparkle(p.size),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Draw a small golden diamond/sparkle shape.
  Widget _buildSparkle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.goldGlow,
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withAlpha(180),
            blurRadius: size * 2,
            spreadRadius: size * 0.5,
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final AnimationController controller;
  final CurvedAnimation animation;
  final double angle;
  final double speed;
  final double size;
  final double delay;

  _Particle({
    required this.controller,
    required this.animation,
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
  });
}
