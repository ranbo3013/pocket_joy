import 'package:audioplayers/audioplayers.dart';
import '../config/constants.dart';

/// Manages sound effect playback for PocketJoy.
///
/// Uses [audioplayers] to play short MP3 sound effects.
/// Supports independent volume control and graceful degradation
/// when audio files are not yet available.
///
/// Reference: Visual Asset Spec §7
class AudioService {
  bool _soundEnabled = true;
  bool _initialized = false;

  // Dedicated players for frequently-used sounds to avoid
  // interrupting one sound with another.
  AudioPlayer? _coinPlayer;
  AudioPlayer? _goldBarPlayer;
  AudioPlayer? _receivePlayer;
  AudioPlayer? _promptPlayer;

  // Asset paths — match the MP3 files in assets/audio/.
  static const _coinSource = 'audio/coin-drop.mp3';
  static const _goldBarSource = 'audio/gold_bar.mp3';
  static const _receiveSource = 'audio/receive.mp3';
  static const _promptSource = 'audio/prompt.mp3';

  bool get isInitialized => _initialized;

  // ─── Initialization ──────────────────────────────────────

  Future<void> init() async {
    _coinPlayer = AudioPlayer();
    _goldBarPlayer = AudioPlayer();
    _receivePlayer = AudioPlayer();
    _promptPlayer = AudioPlayer();

    // Set default volume to 35% of system (PRD §7.2).
    // Gold bar gets a slight boost for celebratory feel.
    await _coinPlayer!.setVolume(defaultVolumeCoefficient);
    await _goldBarPlayer!.setVolume(defaultVolumeCoefficient + 0.15);
    await _receivePlayer!.setVolume(defaultVolumeCoefficient);
    await _promptPlayer!.setVolume(defaultVolumeCoefficient);

    // Preload sources so first play is instant.
    try {
      await Future.wait([
        _coinPlayer!.setSource(AssetSource(_coinSource)),
        _goldBarPlayer!.setSource(AssetSource(_goldBarSource)),
        _receivePlayer!.setSource(AssetSource(_receiveSource)),
        _promptPlayer!.setSource(AssetSource(_promptSource)),
      ]);
    } catch (_) {
      // Sound files missing or corrupted — app continues silently.
    }

    _initialized = true;
  }

  // ─── Settings ────────────────────────────────────────────

  void setEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  // ─── Playback ────────────────────────────────────────────

  /// Play coin drop sound (short, bright "ding").
  Future<void> playCoinDrop() async {
    if (!_soundEnabled || !_initialized) return;
    try {
      await _coinPlayer?.stop();
      await _coinPlayer?.resume();
    } catch (_) {
      // Silent fail — audio is non-critical
    }
  }

  /// Play gold bar synthesis sound (richer, celebratory "ching").
  Future<void> playGoldBar() async {
    if (!_soundEnabled || !_initialized) return;
    try {
      await _goldBarPlayer?.stop();
      await _goldBarPlayer?.resume();
    } catch (_) {
      // Silent fail
    }
  }

  /// Play receive / bag-catch sound.
  Future<void> playReceive() async {
    if (!_soundEnabled || !_initialized) return;
    try {
      await _receivePlayer?.stop();
      await _receivePlayer?.resume();
    } catch (_) {
      // Silent fail
    }
  }

  /// Play soft prompt / reminder sound.
  Future<void> playPrompt() async {
    if (!_soundEnabled || !_initialized) return;
    try {
      await _promptPlayer?.stop();
      await _promptPlayer?.resume();
    } catch (_) {
      // Silent fail
    }
  }

  // ─── Lifecycle ───────────────────────────────────────────

  void dispose() {
    _coinPlayer?.dispose();
    _goldBarPlayer?.dispose();
    _receivePlayer?.dispose();
    _promptPlayer?.dispose();
  }
}
