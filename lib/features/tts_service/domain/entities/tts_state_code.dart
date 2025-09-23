enum TtsStateCode {
  initial,
  ready,
  playing,
  paused,
  continued,
  completed,
  canceled;

  bool get isInitial => this == TtsStateCode.initial;

  bool get isReady => this == TtsStateCode.ready;

  bool get isIdle =>
      this == TtsStateCode.ready ||
      this == TtsStateCode.completed ||
      this == TtsStateCode.canceled;
}
