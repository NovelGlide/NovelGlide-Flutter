abstract class ReaderTtsRepository {
  // Stream play tts event
  Stream<String> get onPlayTts;

  // Stream stop tts event
  Stream<void> get onStopTts;

  // Stream tts end event
  Stream<void> get onEndTts;

  void ttsPlay();

  void ttsNext();

  void ttsStop();
}
