/// Bag animation states.
/// Reference: Visual Asset Spec §8.1
enum BagState {
  /// Static / very subtle breathing (salary not set)
  idle,

  /// Slow breathing loop (4-6s cycle) — normal running state
  breathing,

  /// Bag catches coin: sink → bounce → mouth twitch → back to breathing
  receive,

  /// Dimmed, minimal animation — paused state
  paused,

  /// Triple-bounce celebration — daily goal reached or gold bar milestone
  celebrate,
}
