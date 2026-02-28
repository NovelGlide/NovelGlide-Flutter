import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../core/app_font_loader/domain/use_cases/app_font_loader_load_font.dart';
import '../../../../../core/css_parser/domain/entities/css_font_file.dart';
import '../../../../book_storage/data/repositories/local_book_storage.dart';
import '../../../../book_storage/domain/entities/book_metadata.dart';
import '../../../../book_storage/domain/entities/reading_state.dart';
import '../../../../book_storage/domain/entities/bookmark_entry.dart';
import '../../../../bookmark/domain/repositories/bookmark_repository.dart';

import '../../../../books/domain/entities/book.dart';
import '../../../../books/domain/entities/book_html_content.dart';
import '../../../../books/domain/use_cases/book_get_use_case.dart';
import '../../../../preference/domain/entities/reader_preference_data.dart';
import '../../../../preference/domain/use_cases/preference_get_use_cases.dart';
import '../../../../preference/domain/use_cases/preference_observe_change_use_case.dart';
import '../../../../preference/domain/use_cases/preference_reset_use_case.dart';
import '../../../../preference/domain/use_cases/preference_save_use_case.dart';
import '../../../domain/entities/reader_core_type.dart';
import '../../../domain/entities/reader_navigation_state_code.dart';
import '../../../domain/entities/reader_page_num_type.dart';
import '../../../domain/entities/reader_set_state_data.dart';
import '../../../domain/repositories/reader_core_repository.dart';
import '../../../domain/use_cases/appearance_use_cases/reader_set_font_color_use_case.dart';
import '../../../domain/use_cases/appearance_use_cases/reader_set_font_size_use_case.dart';
import '../../../domain/use_cases/appearance_use_cases/reader_set_line_height_use_case.dart';
import '../../../domain/use_cases/appearance_use_cases/reader_set_smooth_scroll_use_case.dart';
import '../../../domain/use_cases/reader_goto_use_case.dart';
import '../../../domain/use_cases/reader_next_page_use_case.dart';
import '../../../domain/use_cases/reader_observe_set_state_use_case.dart';
import '../../../domain/use_cases/reader_previous_page_use_case.dart';
import '../../search_page/cubit/reader_search_cubit.dart';
import 'reader_tts_cubit.dart';

part '../../../domain/entities/reader_loading_state_code.dart';
part 'reader_gesture_handler.dart';
part 'reader_state.dart';

class ReaderCubitDependencies {
  ReaderCubitDependencies(
    // App Core use cases
    this._loadFontUseCase,
    // Controllers and reader core.
    this._webViewController,
    this._coreRepository,
    this._observeSetStateUseCase,
    this._nextPageUseCase,
    this._previousPageUseCase,
    this._gotoUseCase,
    this._setFontColorUseCase,
    this._setFontSizeUseCase,
    this._setLineHeightUseCase,
    this._setSmoothScrollUseCase,
    // Book use cases
    this._bookGetUseCase,
    // Book storage for reading state
    this._localBookStorage,
    // Bookmark repository for manual bookmarks
    this._bookmarkRepository,
    // Reader preference use cases
    this._savePreferenceUseCase,
    this._observePreferenceChangeUseCase,
    this._resetPreferenceUseCase,
    // Cubits
    this._readerSearchCubit,
  );

  /// App Core use cases
  final AppFontLoaderLoadCssFontUseCase _loadFontUseCase;

  /// Controllers and reader core.
  final WebViewController? _webViewController;
  final ReaderCoreRepository _coreRepository;

  /// Reader use cases
  final ReaderObserveSetStateUseCase _observeSetStateUseCase;
  final ReaderNextPageUseCase _nextPageUseCase;
  final ReaderPreviousPageUseCase _previousPageUseCase;
  final ReaderGotoUseCase _gotoUseCase;
  final ReaderSetFontColorUseCase _setFontColorUseCase;
  final ReaderSetFontSizeUseCase _setFontSizeUseCase;
  final ReaderSetLineHeightUseCase _setLineHeightUseCase;
  final ReaderSetSmoothScrollUseCase _setSmoothScrollUseCase;

  /// Book use cases
  final BookGetUseCase _bookGetUseCase;

  /// Book storage for reading state and bookmark repository
  final LocalBookStorage _localBookStorage;
  final BookmarkRepository _bookmarkRepository;

  /// Reader preference use cases
  final ReaderSavePreferenceUseCase _savePreferenceUseCase;
  final ReaderObservePreferenceChangeUseCase _observePreferenceChangeUseCase;
  final ReaderResetPreferenceUseCase _resetPreferenceUseCase;

  /// Cubits
  final ReaderSearchCubit _readerSearchCubit;
}

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit(
    this._getPreferenceUseCase,
    this._dependenciesFactory,
    this.ttsCubit,
  ) : super(const ReaderState());

  Book? bookData;
  late ThemeData currentTheme;

  final ReaderCubitDependencies Function(ReaderCoreType) _dependenciesFactory;
  late final ReaderCubitDependencies _dependencies;

  late final ReaderGestureHandler gestureHandler = ReaderGestureHandler(
    onSwipeLeft: previousPage,
    onSwipeRight: nextPage,
  );

  WebViewController? get webViewController => _dependencies._webViewController;

  final ReaderGetPreferenceUseCase _getPreferenceUseCase;
  final ReaderTtsCubit ttsCubit;

  /// Cubits
  ReaderSearchCubit get searchCubit => _dependencies._readerSearchCubit;

  /// Stream Subscriptions
  final Set<StreamSubscription<dynamic>> _subscriptionSet =
      <StreamSubscription<dynamic>>{};

  /// Initialize from widgets.
  Future<void> init({
    required String bookIdentifier,
    required ThemeData currentTheme,
    String? pageIdentifier,
    String? cfi,
    Book? bookData,
  }) async {
    // Initialize members
    this.currentTheme = currentTheme;
    this.bookData = bookData;

    // Load preference first. To determine the core type.
    emit(state.copyWith(
      bookName: bookData?.title,
      code: ReaderLoadingStateCode.preferenceLoading,
    ));

    final ReaderPreferenceData readerSettingsData =
        await _getPreferenceUseCase();

    // Load the dependencies of the cubit
    _dependencies = _dependenciesFactory(readerSettingsData.coreType);

    // Initialize TTS cubit
    ttsCubit.init(_dependencies._coreRepository);

    // Load the book data.
    emit(state.copyWith(
      coreType: readerSettingsData.coreType,
      code: ReaderLoadingStateCode.bookLoading,
    ));

    // Register Listeners
    _subscriptionSet.addAll(<StreamSubscription<dynamic>>[
      _dependencies._observeSetStateUseCase().listen(_receiveSetState),
      _dependencies
          ._observePreferenceChangeUseCase()
          .listen(_refreshPreference),
    ]);

    // Start loading the data of book and reading state.
    String? resumePositionCfi;
    await Future.wait<void>(<Future<void>>[
      _dependencies
          ._bookGetUseCase(bookIdentifier)
          .then((Book value) => this.bookData = value),
      _dependencies._localBookStorage
          .readMetadata(bookIdentifier)
          .then((BookMetadata? metadata) {
        if (metadata != null) {
          resumePositionCfi = metadata.readingState.cfiPosition;
        }
      }),
    ]);

    if (!isClosed) {
      // Emit state.
      emit(state.copyWith(
        code: ReaderLoadingStateCode.rendering,
        bookName: this.bookData?.title,
        readerPreference: readerSettingsData,
      ));
    }

    await _dependencies._coreRepository.init(
      bookIdentifier: bookIdentifier,
      pageIdentifier: pageIdentifier,
      cfi: cfi ?? resumePositionCfi,
    );

    if (!isClosed) {
      // Loading completed.
      emit(state.copyWith(
        code: ReaderLoadingStateCode.loaded,
      ));
    }

    // Send theme data after the page is loaded.
    sendThemeData();

    // Set smooth scroll.
    _dependencies
        ._setSmoothScrollUseCase(state.readerPreference.isSmoothScroll);
  }

  void setNavState(ReaderNavigationStateCode code) {
    emit(state.copyWith(navigationStateCode: code));
  }

  void sendThemeData([ThemeData? newTheme]) {
    currentTheme = newTheme ?? currentTheme;
    if (state.code.isLoaded) {
      _dependencies._setFontColorUseCase(currentTheme.colorScheme.onSurface);
      _dependencies._setFontSizeUseCase(state.readerPreference.fontSize);
      _dependencies._setLineHeightUseCase(state.readerPreference.lineHeight);
    }
  }

  /// *************************************************************************
  /// Settings
  /// *************************************************************************

  set fontSize(double value) {
    emit(state.copyWith(
      readerPreference: state.readerPreference.copyWith(
        fontSize: value,
      ),
    ));
  }

  set lineHeight(double value) {
    emit(state.copyWith(
      readerPreference: state.readerPreference.copyWith(
        lineHeight: value,
      ),
    ));
  }

  set isAutoSaving(bool value) {
    emit(state.copyWith(
      readerPreference: state.readerPreference.copyWith(
        isAutoSaving: value,
      ),
    ));
    if (value) {
      saveBookmark();
    }
  }

  set isSmoothScroll(bool value) {
    emit(state.copyWith(
      readerPreference: state.readerPreference.copyWith(
        isSmoothScroll: value,
      ),
    ));
    _dependencies._setSmoothScrollUseCase(value);
  }

  set pageNumType(ReaderPageNumType value) {
    emit(state.copyWith(
      readerPreference: state.readerPreference.copyWith(
        pageNumType: value,
      ),
    ));
  }

  set coreType(ReaderCoreType value) {
    emit(state.copyWith(
      readerPreference: state.readerPreference.copyWith(
        coreType: value,
      ),
    ));
  }

  void savePreference() =>
      _dependencies._savePreferenceUseCase(state.readerPreference);

  Future<void> resetPreference() async {
    await _dependencies._resetPreferenceUseCase();
  }

  Future<void> _refreshPreference(ReaderPreferenceData data) async {
    emit(state.copyWith(
      readerPreference: data,
    ));
    sendThemeData();
  }

  /// *************************************************************************
  /// Bookmarks
  /// *************************************************************************

  /// Create a manual bookmark at the current reading position.
  Future<void> saveBookmark() async {
    if (bookData == null) return;

    try {
      // Use the new BookmarkRepository to add a bookmark
      await _dependencies._bookmarkRepository.addBookmark(
        bookData!.identifier,
        BookmarkEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cfiPosition: state.startCfi ?? '',
          timestamp: DateTime.now(),
          label: state.breadcrumb.isNotEmpty ? state.breadcrumb : null,
        ),
      );
    } catch (e) {
      // Log the error but don't crash
      print('Error saving bookmark: $e');
    }
  }

  /// Delete a bookmark (deprecated - use BookmarkRepository directly).
  void removeBookmark() {
    // This method is kept for backward compatibility
    // but the new flow should use BookmarkRepository.deleteBookmarks() directly
  }

  /// Save the current reading position to BookMetadata.
  /// Called when the reader closes to persist the current position.
  Future<void> _saveReadingPosition() async {
    if (bookData == null) return;

    try {
      final BookMetadata? currentMetadata = await _dependencies
          ._localBookStorage
          .readMetadata(bookData!.identifier);

      if (currentMetadata == null) return;

      // Update the reading state with current position
      final ReadingState updatedState = ReadingState(
        cfiPosition: state.startCfi ?? '',
        progress: 0.0,
        lastReadTime: DateTime.now(),
        totalSeconds: currentMetadata.readingState.totalSeconds,
      );

      final BookMetadata updatedMetadata = currentMetadata.copyWith(
        readingState: updatedState,
      );

      // Write back to storage
      await _dependencies._localBookStorage.writeMetadata(
        bookData!.identifier,
        updatedMetadata,
      );
    } catch (e) {
      // Log the error but don't crash during close
      print('Error saving reading position: $e');
    }
  }

  /// *************************************************************************
  /// Page Navigation
  /// *************************************************************************

  Future<void> previousPage() async {
    if (state.atStart || !ttsCubit.state.ttsState.isIdle) {
      // There's not a previous page.
      // TTS is not idle.
      return;
    }

    emit(state.copyWith(code: ReaderLoadingStateCode.pageLoading));
    await _dependencies._previousPageUseCase();
    emit(state.copyWith(code: ReaderLoadingStateCode.loaded));
  }

  Future<void> nextPage() async {
    if (state.atEnd || !ttsCubit.state.ttsState.isIdle) {
      // There's not a next page.
      // TTS is not idle.
      return;
    }

    emit(state.copyWith(code: ReaderLoadingStateCode.pageLoading));
    await _dependencies._nextPageUseCase();
    emit(state.copyWith(code: ReaderLoadingStateCode.loaded));
  }

  Future<bool> goto({
    String? pageIdentifier,
    String? cfi,
  }) async {
    emit(state.copyWith(code: ReaderLoadingStateCode.pageLoading));

    final ReaderGotoUseCaseResult result =
        await _dependencies._gotoUseCase(ReaderGotoUseCaseParam(
      chapterIdentifier: pageIdentifier,
      cfi: cfi,
    ));

    emit(state.copyWith(code: ReaderLoadingStateCode.loaded));

    return result.isSuccessful;
  }

  /// *************************************************************************
  /// Communication
  /// *************************************************************************

  void _receiveSetState(ReaderSetStateData data) {
    emit(state.copyWith(
      breadcrumb: data.breadcrumb,
      chapterFileName: data.chapterIdentifier,
      startCfi: data.startCfi,
      chapterCurrentPage: data.chapterCurrentPage,
      chapterTotalPage: data.chapterTotalPage,
      htmlContent: data.content,
      atStart: data.atStart,
      atEnd: data.atEnd,
    ));

    if (state.readerPreference.isAutoSaving) {
      saveBookmark();
    }

    if (state.coreType == ReaderCoreType.htmlWidget && data.content != null) {
      loadFonts(data.content!.fonts);
    }
  }

  /// *************************************************************************
  /// Miscellaneous
  /// *************************************************************************

  String getInBookPath(String pageIdentifier, String path) {
    return normalize(join(dirname(pageIdentifier), path));
  }

  Future<void> loadFonts(Set<CssFontFile> fileSet) async {
    await _dependencies._loadFontUseCase(fileSet);
  }

  @override
  Future<void> close() async {
    // Save current reading position before closing
    await _saveReadingPosition();

    for (StreamSubscription<dynamic> subscription in _subscriptionSet) {
      await subscription.cancel();
    }

    await _dependencies._coreRepository.dispose();
    await searchCubit.close();

    super.close();
  }
}
