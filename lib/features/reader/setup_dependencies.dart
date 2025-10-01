import 'package:webview_flutter/webview_flutter.dart';

import '../../core/file_system/domain/repositories/file_system_repository.dart';
import '../../core/path_provider/domain/repositories/app_path_provider.dart';
import '../../core/web_server/domain/repositories/web_server_repository.dart';
import '../../main.dart';
import '../bookmark/domain/use_cases/bookmark_get_data_use_case.dart';
import '../bookmark/domain/use_cases/bookmark_update_data_use_case.dart';
import '../books/domain/repositories/book_repository.dart';
import '../books/domain/use_cases/book_get_use_case.dart';
import '../preference/domain/repositories/preference_repository.dart';
import '../preference/domain/use_cases/preference_get_use_cases.dart';
import '../preference/domain/use_cases/preference_observe_change_use_case.dart';
import '../preference/domain/use_cases/preference_reset_use_case.dart';
import '../preference/domain/use_cases/preference_save_use_case.dart';
import '../tts_service/domain/use_cases/tts_observe_state_changed_use_case.dart';
import '../tts_service/domain/use_cases/tts_pause_use_case.dart';
import '../tts_service/domain/use_cases/tts_reload_preference_use_case.dart';
import '../tts_service/domain/use_cases/tts_resume_use_case.dart';
import '../tts_service/domain/use_cases/tts_speak_use_case.dart';
import '../tts_service/domain/use_cases/tts_stop_use_case.dart';
import 'data/data_sources/impl/reader_webview_data_source_impl.dart';
import 'data/repositories/reader_core_html_repository_impl.dart';
import 'data/repositories/reader_core_webview_repository_impl.dart';
import 'data/repositories/reader_location_cache_repository_impl.dart';
import 'data/repositories/reader_search_repository_impl.dart';
import 'data/repositories/reader_server_repository_impl.dart';
import 'data/repositories/reader_tts_repository_impl.dart';
import 'domain/entities/reader_core_type.dart';
import 'domain/repositories/reader_core_repository.dart';
import 'domain/repositories/reader_location_cache_repository.dart';
import 'domain/repositories/reader_search_repository.dart';
import 'domain/repositories/reader_server_repository.dart';
import 'domain/repositories/reader_tts_repository.dart';
import 'domain/use_cases/appearance_use_cases/reader_set_font_color_use_case.dart';
import 'domain/use_cases/appearance_use_cases/reader_set_font_size_use_case.dart';
import 'domain/use_cases/appearance_use_cases/reader_set_line_height_use_case.dart';
import 'domain/use_cases/appearance_use_cases/reader_set_smooth_scroll_use_case.dart';
import 'domain/use_cases/location_cache_use_cases/reader_clear_location_cache_use_case.dart';
import 'domain/use_cases/location_cache_use_cases/reader_delete_location_cache_use_case.dart';
import 'domain/use_cases/reader_goto_use_case.dart';
import 'domain/use_cases/reader_next_page_use_case.dart';
import 'domain/use_cases/reader_observe_set_state_use_case.dart';
import 'domain/use_cases/reader_previous_page_use_case.dart';
import 'domain/use_cases/search_use_cases/reader_observe_search_list_use_case.dart';
import 'domain/use_cases/search_use_cases/reader_search_in_current_chapter_use_case.dart';
import 'domain/use_cases/search_use_cases/reader_search_in_whole_book_use_case.dart';
import 'domain/use_cases/tts_use_cases/reader_next_tts_use_case.dart';
import 'domain/use_cases/tts_use_cases/reader_observe_tts_end_use_case.dart';
import 'domain/use_cases/tts_use_cases/reader_observe_tts_play_use_case.dart';
import 'domain/use_cases/tts_use_cases/reader_observe_tts_stop_use_case.dart';
import 'domain/use_cases/tts_use_cases/reader_play_tts_use_case.dart';
import 'domain/use_cases/tts_use_cases/reader_stop_tts_use_case.dart';
import 'presentation/reader_page/cubit/reader_cubit.dart';
import 'presentation/reader_page/cubit/reader_tts_cubit.dart';
import 'presentation/search_page/cubit/reader_search_cubit.dart';

void setupReaderDependencies() {
  // Reader Location Cache Repository
  sl.registerLazySingleton<ReaderLocationCacheRepository>(
    () => ReaderLocationCacheRepositoryImpl(
      sl<AppPathProvider>(),
      sl<FileSystemRepository>(),
    ),
  );

  // Reader Server Repository
  sl.registerLazySingleton<ReaderServerRepository>(
    () => ReaderServerRepositoryImpl(
      sl<WebServerRepository>(),
      sl<BookRepository>(),
    ),
  );

  // Register Reader use cases
  sl.registerFactory<ReaderClearLocationCacheUseCase>(
    () => ReaderClearLocationCacheUseCase(
      sl<ReaderLocationCacheRepository>(),
    ),
  );
  sl.registerFactory<ReaderDeleteLocationCacheUseCase>(
    () => ReaderDeleteLocationCacheUseCase(
      sl<ReaderLocationCacheRepository>(),
    ),
  );

  // Register Reader preference use cases.
  sl.registerFactory<ReaderGetPreferenceUseCase>(
    () => ReaderGetPreferenceUseCase(
      sl<ReaderPreferenceRepository>(),
    ),
  );
  sl.registerFactory<ReaderObservePreferenceChangeUseCase>(
    () => ReaderObservePreferenceChangeUseCase(
      sl<ReaderPreferenceRepository>(),
    ),
  );
  sl.registerFactory<ReaderResetPreferenceUseCase>(
    () => ReaderResetPreferenceUseCase(
      sl<ReaderPreferenceRepository>(),
    ),
  );
  sl.registerFactory<ReaderSavePreferenceUseCase>(
    () => ReaderSavePreferenceUseCase(
      sl<ReaderPreferenceRepository>(),
    ),
  );

  // Register the factory of ReaderCubit
  sl.registerFactory<ReaderCubit>(
    () {
      return ReaderCubit(
        // Necessary use cases
        sl<ReaderGetPreferenceUseCase>(),
        // The factory of the dependencies initialization.
        (ReaderCoreType coreType) {
          // Initialize the WebView controller.
          final WebViewController? controller = switch (coreType) {
            ReaderCoreType.webView => WebViewController(),
            _ => null,
          };

          // Initialize the core repository.
          final ReaderCoreRepository coreRepository = switch (coreType) {
            ReaderCoreType.webView => ReaderCoreWebViewRepositoryImpl(
                controller!,
                ReaderWebViewDataSourceImpl(controller),
                sl<ReaderServerRepository>(),
                sl<ReaderLocationCacheRepository>(),
              ),
            ReaderCoreType.html => ReaderCoreHtmlRepositoryImpl(
                sl<BookRepository>(),
              ),
          };

          return ReaderCubitDependencies(
            controller,
            coreRepository,
            // Reader use cases
            ReaderObserveSetStateUseCase(coreRepository),
            ReaderNextPageUseCase(coreRepository),
            ReaderPreviousPageUseCase(coreRepository),
            ReaderSetFontColorUseCase(coreRepository),
            ReaderSetFontSizeUseCase(coreRepository),
            ReaderSetLineHeightUseCase(coreRepository),
            ReaderSetSmoothScrollUseCase(coreRepository),
            // Book use cases
            sl<BookGetUseCase>(),
            // Bookmark use cases
            sl<BookmarkGetDataUseCase>(),
            sl<BookmarkUpdateDataUseCase>(),
            // Reader preference use cases.
            sl<ReaderSavePreferenceUseCase>(),
            sl<ReaderObservePreferenceChangeUseCase>(),
            sl<ReaderResetPreferenceUseCase>(),
          );
        },
        // Setup the TTS cubit.
        ReaderTtsCubit(
          // The factory of the dependencies initialization.
          (ReaderCoreRepository coreRepository) {
            final ReaderTtsRepository ttsRepository =
                ReaderTtsRepositoryImpl(coreRepository);

            return ReaderTtsCubitDependencies(
              ReaderNextTtsUseCase(ttsRepository),
              ReaderPlayTtsUseCase(ttsRepository),
              ReaderStopTtsUseCase(ttsRepository),
              ReaderObserveTtsEndUseCase(ttsRepository),
              ReaderObserveTtsPlayUseCase(ttsRepository),
              ReaderObserveTtsStopUseCase(ttsRepository),
              sl<TtsReloadPreferenceUseCase>(),
              sl<TtsObserveStateChangedUseCase>(),
              sl<TtsSpeakUseCase>(),
              sl<TtsStopUseCase>(),
              sl<TtsPauseUseCase>(),
              sl<TtsResumeUseCase>(),
            );
          },
        ),
        ReaderSearchCubit(
          (ReaderCoreRepository coreRepository) {
            final ReaderSearchRepository searchRepository =
                ReaderSearchRepositoryImpl(coreRepository);

            return ReaderSearchCubitDependencies(
              ReaderSearchInCurrentChapterUseCase(searchRepository),
              ReaderSearchInWholeBookUseCase(searchRepository),
              ReaderObserveSearchListUseCase(searchRepository),
              ReaderGotoUseCase(coreRepository),
            );
          },
        ),
      );
    },
  );
}
