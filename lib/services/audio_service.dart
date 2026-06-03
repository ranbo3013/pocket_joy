/// Stub audio service. Full implementation in Phase 11.
/// Reference: Visual Asset Spec §7
class AudioService {
  bool _soundEnabled = true;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    // TODO Phase 11: Initialize audioplayers
    _initialized = true;
  }

  void setEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  Future<void> playCoinDrop() async {
    if (!_soundEnabled || !_initialized) return;
    // TODO Phase 11: play sfx_coin_drop
  }

  Future<void> playReceive() async {
    if (!_soundEnabled || !_initialized) return;
    // TODO Phase 11: play sfx_receive
  }

  Future<void> playGoldBar() async {
    if (!_soundEnabled || !_initialized) return;
    // TODO Phase 11: play sfx_gold_bar
  }

  Future<void> playPrompt() async {
    if (!_soundEnabled || !_initialized) return;
    // TODO Phase 11: play sfx_prompt
  }

  void dispose() {
    // TODO Phase 11: dispose audioplayers
  }
}
