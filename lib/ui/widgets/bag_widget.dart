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
        break;
      case BagState.paused:
        _breathController.stop();
        _bounceController.stop();
        break;
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale ?? 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_breathController, _bounceController]),
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
        if (widget.state == BagState.receive && _bounceController.isAnimating) {
          // Spring-like: compress at forward peak, normal at rest
          if (_bounceController.status == AnimationStatus.forward) {
            bounceScaleY = 1.0 - 0.06 * _bounceController.value;
          } else {
            bounceScaleY = 1.0 - 0.06 * (1.0 - _bounceController.value);
          }
        }

        return Transform.scale(
          scale: scale * breathScale,
          child: Opacity(
            opacity: opacity,
            child: Transform(
              transform: Matrix4.identity()..scale(1.0, bounceScaleY),
              alignment: Alignment.center,
              child: _buildBagGraphic(),
            ),
          ),
        );
      },
    );
  }

  /// Code-drawn bag placeholder.
  /// Replaced by Rive/PNG asset in Phase 9.
  Widget _buildBagGraphic() {
    return Container(
      width: 200,
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.goldPrimary.withOpacity(0.4), width: 2),
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
          // Bag opening (folded top)
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          // Bag body hint
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: AppColors.goldPrimary.withOpacity(0.3),
          ),
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
