import 'dart:collection';

/// Animation conflict resolution queue.
/// Enforces PRD §16 rules: max 2 pending, gold bar priority,
/// user action preemption.
enum AnimationEventType { coinDrop, goldBarSynthesis }

class AnimationEvent {
  final AnimationEventType type;
  final int coinAmount;
  final int goldBarCount;

  const AnimationEvent({
    required this.type,
    this.coinAmount = 0,
    this.goldBarCount = 0,
  });
}

class AnimationQueue {
  static const maxQueueSize = 2;
  final Queue<AnimationEvent> _queue = Queue();
  bool _isPlaying = false;
  bool _userActionPending = false;

  bool get isPlaying => _isPlaying;
  bool get isEmpty => _queue.isEmpty;
  int get length => _queue.length;

  /// Enqueue an animation event. Returns true if enqueued, false if discarded.
  bool enqueue(AnimationEvent event) {
    if (_userActionPending) {
      _queue.clear();
      return false;
    }

    if (_queue.length >= maxQueueSize) {
      _queue.removeFirst(); // discard oldest (PRD §16)
    }
    _queue.add(event);
    return true;
  }

  /// Dequeue next event, prioritizing gold bar synthesis.
  AnimationEvent? dequeue() {
    if (_queue.isEmpty) return null;

    // Check if gold bar exists in queue — prioritize it
    final goldBarIdx = _queue.toList().indexWhere(
          (e) => e.type == AnimationEventType.goldBarSynthesis,
        );

    if (goldBarIdx > 0) {
      // Remove earlier events (coin drops) to prioritize gold bar
      for (int i = 0; i < goldBarIdx; i++) {
        _queue.removeFirst();
      }
    }

    return _queue.isNotEmpty ? _queue.removeFirst() : null;
  }

  /// Interrupt all animations for user action.
  void interruptForUserAction() {
    _userActionPending = true;
    _queue.clear();
    _isPlaying = false;
  }

  /// Reset user action flag (called after interruption handled).
  void resetUserAction() {
    _userActionPending = false;
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
  }

  void clear() {
    _queue.clear();
    _isPlaying = false;
  }
}
