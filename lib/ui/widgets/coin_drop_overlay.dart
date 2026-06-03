import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/animation_provider.dart';
import 'coin_drop_painter.dart';

/// Full-screen overlay for coin drop animation.
/// Uses IgnorePointer to not block interactions.
class CoinDropOverlay extends StatefulWidget {
  const CoinDropOverlay({super.key});

  @override
  State<CoinDropOverlay> createState() => _CoinDropOverlayState();
}

class _CoinDropOverlayState extends State<CoinDropOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850), // 700-1000ms range
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        context.read<AnimationProvider>().onCoinDropComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimationProvider>(
      builder: (context, anim, _) {
        if (!anim.isCoinDropping) {
          return const SizedBox.shrink();
        }

        // Start animation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (anim.isCoinDropping && !_controller.isAnimating) {
            _startAnimation();
          }
        });

        final size = MediaQuery.of(context).size;

        return IgnorePointer(
          child: SizedBox.expand(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: CoinDropPainter(
                    progress: _controller.value,
                    screenSize: size,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
