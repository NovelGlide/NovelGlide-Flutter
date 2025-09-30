import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../tts_service/domain/entities/tts_state_code.dart';
import '../../../../tts_service/domain/use_cases/tts_observe_state_changed_use_case.dart';
import '../../../../tts_service/domain/use_cases/tts_pause_use_case.dart';
import '../../../../tts_service/domain/use_cases/tts_reload_preference_use_case.dart';
import '../../../../tts_service/domain/use_cases/tts_resume_use_case.dart';
import '../../../../tts_service/domain/use_cases/tts_speak_use_case.dart';
import '../../../../tts_service/domain/use_cases/tts_stop_use_case.dart';
import '../../../domain/repositories/reader_core_repository.dart';
import '../../../domain/use_cases/tts_use_cases/reader_next_tts_use_case.dart';
import '../../../domain/use_cases/tts_use_cases/reader_observe_tts_end_use_case.dart';
import '../../../domain/use_cases/tts_use_cases/reader_observe_tts_play_use_case.dart';
import '../../../domain/use_cases/tts_use_cases/reader_observe_tts_stop_use_case.dart';
import '../../../domain/use_cases/tts_use_cases/reader_play_tts_use_case.dart';
import '../../../domain/use_cases/tts_use_cases/reader_stop_tts_use_case.dart';
import 'reader_tts_state.dart';

class ReaderTtsCubitDependencies {
  ReaderTtsCubitDependencies(
    this._readerNextTtsUseCase,
    this._readerPlayTtsUseCase,
    this._readerStopTtsUseCase,
    this._readerObserveTtsEndUseCase,
    this._readerObserveTtsPlayUseCase,
    this._readerObserveTtsStopUseCase,
    this._ttsReloadPreferenceUseCase,
    this._ttsObserveStateChangedUseCase,
    this._ttsSpeakUseCase,
    this._ttsStopUseCase,
    this._ttsPauseUseCase,
    this._ttsResumeUseCase,
  );

  /// Communication use cases
  final ReaderNextTtsUseCase _readerNextTtsUseCase;
  final ReaderPlayTtsUseCase _readerPlayTtsUseCase;
  final ReaderStopTtsUseCase _readerStopTtsUseCase;
  final ReaderObserveTtsEndUseCase _readerObserveTtsEndUseCase;
  final ReaderObserveTtsPlayUseCase _readerObserveTtsPlayUseCase;
  final ReaderObserveTtsStopUseCase _readerObserveTtsStopUseCase;

  /// TTS use cases
  final TtsReloadPreferenceUseCase _ttsReloadPreferenceUseCase;
  final TtsObserveStateChangedUseCase _ttsObserveStateChangedUseCase;
  final TtsSpeakUseCase _ttsSpeakUseCase;
  final TtsStopUseCase _ttsStopUseCase;
  final TtsPauseUseCase _ttsPauseUseCase;
  final TtsResumeUseCase _ttsResumeUseCase;
}

class ReaderTtsCubit extends Cubit<ReaderTtsState> {
  ReaderTtsCubit(
    this._dependenciesFactory,
  ) : super(const ReaderTtsState());

  final ReaderTtsCubitDependencies Function(ReaderCoreRepository coreRepository)
      _dependenciesFactory;
  late final ReaderTtsCubitDependencies _dependencies;

  /// Stream subscription
  final Set<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>{};

  bool _isSpeakingEnd = false;

  Future<void> init(ReaderCoreRepository coreRepository) async {
    // Setup the dependencies first.
    _dependencies = _dependenciesFactory(coreRepository);

    // Register Listeners
    _subscriptions.addAll(<StreamSubscription<dynamic>>[
      _dependencies._readerObserveTtsEndUseCase().listen(_ttsEnd),
      _dependencies._readerObserveTtsPlayUseCase().listen(_ttsPlay),
      _dependencies._readerObserveTtsStopUseCase().listen(_ttsStop),
      _dependencies._ttsObserveStateChangedUseCase().listen(_onTtsStateChanged),
    ]);

    // Reload TTS
    await _dependencies._ttsReloadPreferenceUseCase();
  }

  void _onTtsStateChanged(TtsStateCode code) {
    switch (code) {
      case TtsStateCode.completed:
        if (_isSpeakingEnd) {
          emit(ReaderTtsState(ttsState: code));
        } else {
          // The current sentence has been said. Go to next sentence.
          _dependencies._readerNextTtsUseCase();
        }
        break;

      default:
        emit(ReaderTtsState(ttsState: code));
    }
  }

  void sendPlaySignal() {
    _isSpeakingEnd = false;
    _dependencies._readerPlayTtsUseCase();
  }

  void resumeSpeaking() {
    _dependencies._ttsResumeUseCase();
  }

  void pauseSpeaking() {
    _dependencies._ttsPauseUseCase();
  }

  void stopSpeaking() {
    _dependencies._ttsStopUseCase();
    _dependencies._readerStopTtsUseCase();
  }

  /// Request to play TTS
  void _ttsPlay(String text) {
    _dependencies._ttsSpeakUseCase(text);
  }

  /// Stop TTS
  void _ttsStop(void _) {
    _dependencies._ttsStopUseCase();
  }

  /// Terminate TTS
  void _ttsEnd(void _) {
    _isSpeakingEnd = true;
    _dependencies._ttsStopUseCase();
  }

  @override
  Future<void> close() async {
    for (StreamSubscription<dynamic> subscription in _subscriptions) {
      await subscription.cancel();
    }

    await _dependencies._ttsStopUseCase();

    super.close();
  }
}
