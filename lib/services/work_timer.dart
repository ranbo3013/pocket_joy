import 'dart:async';

/// Foreground work-seconds accumulator.
/// Emits elapsed seconds as a stream, respecting pause/resume.
class WorkTimer {
  final _controller = StreamController<int>.broadcast();
  final _stopwatch = Stopwatch();
  Timer? _tickTimer;

  bool _isRunning = false;

  /// Stream of accumulated work seconds.
  Stream<int> get seconds => _controller.stream;

  /// Current accumulated seconds.
  int get elapsed => _stopwatch.elapsed.inSeconds + _baseSeconds;

  int _baseSeconds = 0;
  bool get isRunning => _isRunning;

  /// Start/resume timer, ticking every second.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _stopwatch.start();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _controller.add(elapsed);
    });
  }

  /// Pause without resetting accumulated time.
  void pause() {
    if (!_isRunning) return;
    _isRunning = false;
    _stopwatch.stop();
    _baseSeconds += _stopwatch.elapsed.inSeconds;
    _stopwatch.reset();
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// Resume from paused state.
  void resume() {
    start();
  }

  /// Stop and reset all time to 0.
  void reset() {
    _isRunning = false;
    _stopwatch.stop();
    _stopwatch.reset();
    _baseSeconds = 0;
    _tickTimer?.cancel();
    _tickTimer = null;
    _controller.add(0);
  }

  /// Dispose the timer resources.
  void dispose() {
    _stopwatch.stop();
    _tickTimer?.cancel();
    _controller.close();
  }
}
