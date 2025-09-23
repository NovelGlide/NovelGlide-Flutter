import 'dart:async';

import '../../domain/repositories/reader_tts_repository.dart';
import '../../domain/repositories/reader_webview_repository.dart';

class ReaderTtsRepositoryImpl extends ReaderTtsRepository {
  ReaderTtsRepositoryImpl(this._webViewRepository);

  final ReaderWebViewRepository _webViewRepository;

  @override
  Stream<void> get onEndTts => _webViewRepository.onEndTts;

  @override
  Stream<String> get onPlayTts => _webViewRepository.onPlayTts;

  @override
  Stream<void> get onStopTts => _webViewRepository.onStopTts;

  @override
  void ttsPlay() {
    _webViewRepository.ttsPlay();
  }

  @override
  void ttsNext() {
    _webViewRepository.ttsNext();
  }

  @override
  void ttsStop() {
    _webViewRepository.ttsStop();
  }
}
