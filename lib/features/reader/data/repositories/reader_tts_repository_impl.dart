import 'dart:async';

import '../../domain/repositories/reader_core_repository.dart';
import '../../domain/repositories/reader_tts_repository.dart';

class ReaderTtsRepositoryImpl extends ReaderTtsRepository {
  ReaderTtsRepositoryImpl(this._coreRepository);

  final ReaderCoreRepository _coreRepository;

  @override
  Stream<void> get onEndTts => _coreRepository.onEndTts;

  @override
  Stream<String> get onPlayTts => _coreRepository.onPlayTts;

  @override
  Stream<void> get onStopTts => _coreRepository.onStopTts;

  @override
  void ttsPlay() {
    _coreRepository.ttsPlay();
  }

  @override
  void ttsNext() {
    _coreRepository.ttsNext();
  }

  @override
  void ttsStop() {
    _coreRepository.ttsStop();
  }
}
