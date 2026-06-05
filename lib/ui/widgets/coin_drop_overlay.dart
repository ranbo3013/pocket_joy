import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../providers/animation_provider.dart';

/// Full-screen overlay for coin drop animation.
///
/// Drops 2–5 coin PNGs with staggered timing, each following
/// a bezier trajectory into the bag mouth while spinning/flipping.
/// Emits sparkle bursts on impact.
class CoinDropOverlay extends StatefulWidget {
  const CoinDropOverlay({super.key});

  @override
  State<CoinDropOverlay> createState() => _CoinDropOverlayState();
}

class _CoinDropOverlayState extends State<CoinDropOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final _random = Random();
  final List<_CoinData> _coins = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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

  void _startAnimation(int coinValue) {
    _coins.clear();
    // Visual coin count = coinValue % 5 + 1 → 1–5 coins
    final count = (coinValue % 5 + 1).clamp(1, 5);

    for (int i = 0; i < count; i++) {
      final sparkleAngles = List.generate(
        5,
        (_) => _random.nextDouble() * 2 * pi,
      );

      _coins.add(_CoinData(
        startX: 0.30 + _random.nextDouble() * 0.4, // 0.30–0.70
        startY: 0.02 + _random.nextDouble() * 0.10, // 0.02–0.12
        delay: i * 0.07 + _random.nextDouble() * 0.04, // staggered 0–0.35
        spinSpeed: 2.5 + _random.nextDouble() * 2.5, // 2.5–5 full spins
        flipAmount: 0.2 + _random.nextDouble() * 0.3, // wobble intensity
        sparkleAngles: sparkleAngles,
      ));
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (anim.isCoinDropping && !_controller.isAnimating) {
            _startAnimation(anim.currentDropCoins);
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

                return Stack(
                  children: [
                    for (final coin in _coins)
                      ..._buildCoin(coin, t, endX, endY, size),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Build a single coin with its trajectory, spin, and sparkles.
  List<Widget> _buildCoin(
    _CoinData coin,
    double t,
    double endX,
    double endY,
    Size size,
  ) {
    // Map parent progress to this coin's individual progress
    final localT =
        ((t - coin.delay) / (1.0 - coin.delay)).clamp(0.0, 1.0);

    if (localT <= 0 || localT >= 1.0) return [];

    final widgets = <Widget>[];

    // Bezier trajectory
    final oneMinusT = 1.0 - localT;
    final x = oneMinusT * oneMinusT * coin.startX +
        2 * oneMinusT * localT * ((coin.startX + endX) / 2) +
        localT * localT * endX;
    final y = oneMinusT * oneMinusT * coin.startY +
        2 * oneMinusT * localT * (endY * 0.5) +
        localT * localT * endY;

    // Scale down as coin enters bag
    final scale = 1.0 - localT * 0.4;

    // Spin + flip
    final spinAngle = localT * coin.spinSpeed * 2 * pi;
    final flipAngle = sin(localT * pi) * coin.flipAmount;

    // Coin image
    const coinSize = 48.0;
    widgets.add(
      Positioned(
        left: x * size.width - coinSize / 2,
        top: y * size.height - coinSize / 2,
        child: Transform.scale(
          scale: scale,
          child: Transform(
            transform: Matrix4.identity()
              ..rotateZ(spinAngle)
              ..rotateX(flipAngle),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/coin_gold.png',
              width: coinSize,
              height: coinSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );

    // Impact sparkles near the end
    final sparkleProgress = ((localT - 0.85) / 0.15).clamp(0.0, 1.0);
    if (sparkleProgress > 0) {
      final sparkleOpacity = 1.0 - sparkleProgress;
      for (int i = 0; i < coin.sparkleAngles.length; i++) {
        final angle = coin.sparkleAngles[i];
        final distance = sparkleProgress * 50;
        final dx = cos(angle) * distance;
        final dy = sin(angle) * distance;
        final dotSize = (1.0 - sparkleProgress) * 7 + 2;

        widgets.add(
          Positioned(
            left: size.width * endX + dx - dotSize / 2,
            top: size.height * endY + dy - dotSize / 2,
            child: Opacity(
              opacity: sparkleOpacity.clamp(0.0, 1.0),
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: AppColors.goldGlow,
                  borderRadius: BorderRadius.circular(dotSize * 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldPrimary.withAlpha(180),
                      blurRadius: dotSize * 2,
                      spreadRadius: dotSize * 0.3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

/// Per-coin randomized parameters.
class _CoinData {
  final double startX;
  final double startY;
  final double delay;
  final double spinSpeed;
  final double flipAmount;
  final List<double> sparkleAngles;

  _CoinData({
    required this.startX,
    required this.startY,
    required this.delay,
    required this.spinSpeed,
    required this.flipAmount,
    required this.sparkleAngles,
  });
}
