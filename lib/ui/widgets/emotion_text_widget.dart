import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../providers/animation_provider.dart';

/// Emotion text overlay: fades in, stays 2s, fades out.
/// Reference: PRD §5.3.1
class EmotionTextWidget extends StatefulWidget {
  const EmotionTextWidget({super.key});

  @override
  State<EmotionTextWidget> createState() => _EmotionTextWidgetState();
}

class _EmotionTextWidgetState extends State<EmotionTextWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600), // 300 + 2000 + 300
    );
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 300),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 2000),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 300),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimationProvider>(
      builder: (context, anim, _) {
        if (anim.emotionTextVisible && anim.emotionText != null) {
          // Restart animation when new text appears
          _controller.forward(from: 0);
        }

        if (!anim.emotionTextVisible && anim.emotionText == null) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 40,
          child: Center(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                  child: Text(
                    anim.emotionText ?? '',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.goldPrimary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
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
