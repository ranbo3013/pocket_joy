import 'package:flutter/material.dart';
import '../../config/design_tokens.dart';
import '../../models/bag_state.dart';

/// Main bag visual widget.
/// Phase 0-9 strategy: uses code-drawn placeholder.
/// Rive integration added in Phase 9 with try/catch fallback.
class BagWidget extends StatefulWidget {
  final BagState state;
  final double? scale;

  const BagWidget({super.key, this.state = BagState.idle, this.scale});

  @override
  State<BagWidget> createState() => _BagWidgetState();
}

class _BagWidgetState extends State<BagWidget>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _bounceController;
  late AnimationController _impactController;
  late Animation<double> _impactAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000), // 5s cycle
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _impactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _impactAnimation = CurvedAnimation(
      parent: _impactController,
      curve: Curves.easeOutCubic,
    );

    _applyState(widget.state);
  }

  @override
  void didUpdateWidget(BagWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _applyState(widget.state);
    }
  }

  void _applyState(BagState state) {
    switch (state) {
      case BagState.idle:
        _breathController.repeat(reverse: true);
        _bounceController.stop();
        _bounceController.value = 0;
        break;
      case BagState.breathing:
        // TODO Phase 9: Transition from idle/receive to full breathing
        _breathController.repeat(reverse: true);
        _bounceController.stop();
        _bounceController.value = 0;
        break;
      case BagState.receive:
        // Play bounce: scale 1.0 → 0.94 → 1.0
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
        // Play impact ring: expand and fade
        _impactController.forward(from: 0);
        break;
      case BagState.paused:
        _breathController.stop();
        _bounceController.stop();
        break;
      case BagState.celebrate:
        // Triple bounce: forward → reverse → forward → reverse
        _bounceController.forward().then((_) {
          _bounceController.reverse().then((_) {
            _bounceController.forward().then((_) {
              _bounceController.reverse();
            });
          });
        });
        break;
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _bounceController.dispose();
    _impactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale ?? 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathController,
        _bounceController,
        _impactController,
      ]),
      builder: (context, child) {
        // Combine breath + bounce effects
        double breathScale = 1.0;
        double opacity = 1.0;

        if (widget.state == BagState.idle || widget.state == BagState.breathing) {
          breathScale = 1.0 + _breathController.value * 0.03; // subtle 3% pulse
          opacity = 0.85 + _breathController.value * 0.15;
        }

        if (widget.state == BagState.paused) {
          opacity = 0.6;
        }

        // Bounce: compress vertically
        double bounceScaleY = 1.0;
        if ((widget.state == BagState.receive || widget.state == BagState.celebrate) && _bounceController.isAnimating) {
          // Spring-like: compress at forward peak, normal at rest
          if (_bounceController.status == AnimationStatus.forward) {
            bounceScaleY = 1.0 - 0.06 * _bounceController.value;
          } else {
            bounceScaleY = 1.0 - 0.06 * (1.0 - _bounceController.value);
          }
        }

        // Impact ring: expand and fade
        final impactProgress = _impactAnimation.value;
        final showImpact = widget.state == BagState.receive && impactProgress > 0;

        return Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          children: [
            // Impact ring behind the bag (clipped to bag bounds)
            if (showImpact)
              _buildImpactRing(impactProgress),

            // Main bag graphic
            Transform.scale(
              scale: scale * breathScale,
              child: Opacity(
                opacity: opacity,
                child: Transform(
                  transform: Matrix4.identity()..scale(1.0, bounceScaleY),
                  alignment: Alignment.center,
                  child: _buildBagGraphic(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Expanding golden ring that fades out on coin impact.
  Widget _buildImpactRing(double progress) {
    final ringSize = 60 + progress * 120; // expand from 60 to 180
    final ringOpacity = (1.0 - progress).clamp(0.0, 1.0);
    final ringWidth = (1.0 - progress) * 4; // thins as it expands

    return Positioned(
      top: 80, // near bag mouth
      child: Opacity(
        opacity: ringOpacity,
        child: Container(
          width: ringSize,
          height: ringSize * 0.4,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(ringSize * 0.2),
            border: Border.all(
              color: AppColors.goldGlow,
              width: ringWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldPrimary.withAlpha(80),
                blurRadius: ringSize * 0.3,
                spreadRadius: ringSize * 0.05,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Load the bag PNG asset for the current state.
  /// Each visual state uses a dedicated image — no more
  /// ColorFilter hacks for paused/receive.
  Widget _buildBagGraphic() {
    final assetPath = switch (widget.state) {
      BagState.receive => 'assets/images/bag_receive.png',
      BagState.paused => 'assets/images/bag_paused.png',
      BagState.celebrate || BagState.idle || BagState.breathing =>
        'assets/images/bag_idle.png',
    };

    return Container(
      width: 240,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackGraphic(),
      ),
    );
  }

  /// Fallback when asset image fails to load.
  Widget _buildFallbackGraphic() {
    return Container(
      width: 200,
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: AppColors.goldPrimary.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldGlow.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          Icon(Icons.shopping_bag_outlined,
              size: 80, color: AppColors.goldPrimary.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(
            'PocketJoy',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.goldPrimary.withOpacity(0.4),
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
