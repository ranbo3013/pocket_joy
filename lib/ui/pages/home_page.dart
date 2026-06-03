import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../models/app_phase.dart';
import '../../providers/animation_provider.dart';
import '../../providers/game_provider.dart';
import '../widgets/background_glow.dart';
import '../widgets/bag_widget.dart';
import '../widgets/coin_drop_overlay.dart';
import '../widgets/control_bar.dart';
import '../widgets/emotion_text_widget.dart';
import '../widgets/stats_bar.dart';
import '../widgets/top_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final game = context.read<GameProvider>();
    final anim = context.read<AnimationProvider>();

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        game.onAppBackground();
        anim.interruptAll();
        break;
      case AppLifecycleState.resumed:
        game.onAppForeground();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<GameProvider, AnimationProvider>(
        builder: (context, game, anim, _) {
          // Show time rollback toast
          if (anim.showTimeRollbackToast) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('检测到系统时间异常，金币掉落已暂停。请校正系统时间后继续。'),
                  duration: Duration(seconds: 5),
                ),
              );
              anim.dismissTimeRollbackToast();
            });
          }

          // Sync animation state with game phase
          anim.onPhaseChanged(game.phase);

          return Stack(
            children: [
              // Background
              const BackgroundGlow(),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    const TopBar(),
                    const SizedBox(height: AppSpacing.sm),

                    // Bag area
                    Expanded(
                      child: Center(
                        child: _buildBagArea(game, anim),
                      ),
                    ),

                    // Emotion text
                    const EmotionTextWidget(),
                    const SizedBox(height: AppSpacing.sm),

                    // Stats
                    const StatsBar(),
                    const SizedBox(height: AppSpacing.sm),

                    // Controls
                    const ControlBar(),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),

              // Coin drop overlay
              const CoinDropOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBagArea(GameProvider game, AnimationProvider anim) {
    // During gold bar synthesis, show celebration
    // TODO Phase 12: Add gold bar celebration overlay

    final isPaused = game.phase == AppPhase.paused;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPaused)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '口袋休息中',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        if (game.phase == AppPhase.offWork)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '今天辛苦了 🌙',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        const BagWidget(),
      ],
    );
  }
}
