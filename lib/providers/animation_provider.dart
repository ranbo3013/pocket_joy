import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bag_state.dart';
import '../models/app_phase.dart';
import '../services/emotion_text_pool.dart';
import 'game_provider.dart';

/// Manages bag visual state, emotion text display, and animation queue.
class AnimationProvider extends ChangeNotifier {
  final GameProvider _game;
  final EmotionTextPool _emotionPool;

  // ─── Bag state ─────────────────────────────────────────

  BagState _bagState = BagState.idle;
  BagState get bagState => _bagState;

  // ─── Emotion text ──────────────────────────────────────

  String? _emotionText;
  bool _emotionTextVisible = false;

  String? get emotionText => _emotionText;
  bool get emotionTextVisible => _emotionTextVisible;

  // ─── Pending timers ────────────────────────────────────

  Timer? _hideTextTimer;
  Timer? _bagBreathingTimer;

  // ─── Coin drop animation ───────────────────────────────

  bool _isCoinDropping = false;
  bool get isCoinDropping => _isCoinDropping;

  int _currentDropCoins = 0;
  int get currentDropCoins => _currentDropCoins;

  // ─── Gold bar synthesis ────────────────────────────────

  bool _isGoldBarSynthesizing = false;
  bool get isGoldBarSynthesizing => _isGoldBarSynthesizing;

  // ─── Time rollback toast ───────────────────────────────

  bool _timeRollbackToastVisible = false;
  bool get showTimeRollbackToast => _timeRollbackToastVisible;

  AnimationProvider(
    this._game, {
    EmotionTextPool? emotionPool,
  }) : _emotionPool = emotionPool ?? EmotionTextPool() {
    _syncBagState();
  }

  /// Called by external listeners when GameProvider phase changes.
  void onPhaseChanged(AppPhase newPhase) {
    _syncBagState();
    notifyListeners();
  }

  /// Trigger a coin drop animation sequence.
  /// Called by GameProvider._triggerDrop.
  ///
  /// The bag stays in breathing/idle while the coin falls.
  /// The "receive" bounce happens when the coin actually lands
  /// (see onCoinDropComplete), so the visual impact is synced.
  void triggerCoinDrop(int coins) {
    _currentDropCoins = coins;
    _isCoinDropping = true;

    // Cancel any pending hide/breathe timers from previous drop
    _hideTextTimer?.cancel();
    _bagBreathingTimer?.cancel();

    // Pick emotion text
    final emotion = _emotionPool.pick(coins);
    if (emotion != null) {
      _emotionText = emotion.text;
      _emotionTextVisible = true;
    }

    notifyListeners();
  }

  /// Coin drop animation completed — coin just hit the bag.
  /// Trigger bag receive bounce + impact, then return to breathing.
  void onCoinDropComplete() {
    _isCoinDropping = false;
    // NOW the coin lands — trigger the bag bounce
    _bagState = BagState.receive;
    notifyListeners();

    // After bounce finishes (~700ms for forward+reverse), return to breathing
    _bagBreathingTimer = Timer(const Duration(milliseconds: 700), () {
      _bagState = BagState.breathing;
      notifyListeners();
    });

    // Auto-hide emotion text after 2s
    _hideTextTimer = Timer(const Duration(milliseconds: 2000), () {
      _emotionTextVisible = false;
      notifyListeners();
    });
  }

  /// Trigger gold bar synthesis celebration.
  void triggerGoldBarSynthesis() {
    _isGoldBarSynthesizing = true;
    notifyListeners();
  }

  void onGoldBarSynthesisComplete() {
    _isGoldBarSynthesizing = false;
    notifyListeners();
  }

  /// Interrupt all animations for user action (pause/background).
  void interruptAll() {
    _hideTextTimer?.cancel();
    _bagBreathingTimer?.cancel();
    _isCoinDropping = false;
    _isGoldBarSynthesizing = false;
    _emotionTextVisible = false;
    _syncBagState();
    notifyListeners();
  }

  /// Trigger celebrate animation (triple bounce).
  /// Auto-returns to breathing after ~1200ms.
  void triggerCelebrate() {
    _bagState = BagState.celebrate;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1200), () {
      _bagState = BagState.breathing;
      notifyListeners();
    });
  }

  /// Show time rollback toast once.
  void triggerTimeRollbackToast() {
    _timeRollbackToastVisible = true;
    notifyListeners();
  }

  void dismissTimeRollbackToast() {
    _timeRollbackToastVisible = false;
    notifyListeners();
  }

  void _syncBagState() {
    switch (_game.phase) {
      case AppPhase.unset:
      case AppPhase.offWork:
        _bagState = BagState.idle;
        break;
      case AppPhase.running:
        if (_bagState == BagState.celebrate) break; // don't interrupt celebration
        _bagState = _isCoinDropping ? BagState.receive : BagState.breathing;
        break;
      case AppPhase.paused:
        _bagState = BagState.paused;
        break;
    }
  }
}
