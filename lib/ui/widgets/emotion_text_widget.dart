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

  // Track the last text to avoid restarting animation on every rebuild
  String? _lastText;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    // Fade in over 300ms, then hold at full opacity.
    // The AnimationProvider controls when to hide the widget entirely.
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 300),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 4700),
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
        final hasText = anim.emotionTextVisible && anim.emotionText != null;

        if (!hasText) {
          _lastText = null;
          _controller.value = 0;
          return const SizedBox.shrink();
        }

        // Only restart animation when the text content actually changes
        if (anim.emotionText != _lastText) {
          _lastText = anim.emotionText;
          _controller.forward(from: 0);
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
