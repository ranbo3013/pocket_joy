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
import '../widgets/gold_bar_celebration.dart';
import '../widgets/stats_bar.dart';
import '../widgets/top_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // Track previous values to detect changes across rebuilds.
  // -1 sentinel means "not yet initialised" — prevents false
  // triggers on first build when stats are restored from disk.
  int _prevTodayCoins = -1;
  AppPhase _prevPhase = AppPhase.unset;

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
          // ── Bridge: GameProvider → AnimationProvider ────────

          // Detect new coin drop
          if (_prevTodayCoins >= 0 &&
              game.todayCoins != _prevTodayCoins &&
              game.phase == AppPhase.running) {
            final delta = game.todayCoins - _prevTodayCoins;
            if (delta > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) anim.triggerCoinDrop(delta);
              });
            }
          }
          _prevTodayCoins = game.todayCoins;

          // Detect gold bar synthesis
          if (game.goldBarJustSynthesized && !anim.isGoldBarSynthesizing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) anim.triggerGoldBarSynthesis();
            });
          }

          // Sync bag state ONLY when phase actually changes
          if (game.phase != _prevPhase) {
            _prevPhase = game.phase;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) anim.onPhaseChanged(game.phase);
            });
          }

          // Show time rollback toast
          if (anim.showTimeRollbackToast) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('检测到系统时间异常，金币掉落已暂停。请校正系统时间后继续。'),
                  duration: Duration(seconds: 5),
                ),
              );
              anim.dismissTimeRollbackToast();
            });
          }

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

              // Gold bar celebration particles
              if (anim.isGoldBarSynthesizing)
                const GoldBarCelebration(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBagArea(GameProvider game, AnimationProvider anim) {
    final isPaused = game.phase == AppPhase.paused;
    final isOffWork = game.phase == AppPhase.offWork;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Bag — determines the layout size
        BagWidget(state: anim.bagState),
        // Floating text below the bag, doesn't affect bag position
        if (isPaused || isOffWork)
          Positioned(
            top: 290, // just below the bag graphic
            child: Text(
              isPaused ? '口袋休息中' : '今天辛苦了 🌙',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }
}
