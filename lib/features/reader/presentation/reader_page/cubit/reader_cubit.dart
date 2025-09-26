import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../bookmark/domain/entities/bookmark_data.dart';
import '../../../../bookmark/domain/use_cases/bookmark_get_data_use_case.dart';
import '../../../../bookmark/domain/use_cases/bookmark_update_data_use_case.dart';
import '../../../../books/domain/entities/book.dart';
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
import '../../../domain/use_cases/reader_next_page_use_case.dart';
import '../../../domain/use_cases/reader_observe_load_done_use_case.dart';
import '../../../domain/use_cases/reader_observe_set_state_use_case.dart';
import '../../../domain/use_cases/reader_previous_page_use_case.dart';
import '../../search_page/cubit/reader_search_cubit.dart';
import 'reader_tts_cubit.dart';

part '../../../domain/entities/reader_loading_state_code.dart';
part 'reader_gesture_handler.dart';
part 'reader_state.dart';

class ReaderCubitDependencies {
  ReaderCubitDependencies(
    this._webViewController,
    this._coreRepository,
    this._observeLoadDoneUseCase,
    this._observeSetStateUseCase,
    this._nextPageUseCase,
    this._previousPageUseCase,
    this._setFontColorUseCase,
    this._setFontSizeUseCase,
    this._setLineHeightUseCase,
    this._setSmoothScrollUseCase,
    this._searchCubit,
    this._ttsCubit,
  );

  final WebViewController? _webViewController;
  final ReaderCoreRepository _coreRepository;

  /// Reader use cases
  final ReaderObserveLoadDoneUseCase _observeLoadDoneUseCase;
  final ReaderObserveSetStateUseCase _observeSetStateUseCase;
  final ReaderNextPageUseCase _nextPageUseCase;
  final ReaderPreviousPageUseCase _previousPageUseCase;
  final ReaderSetFontColorUseCase _setFontColorUseCase;
  final ReaderSetFontSizeUseCase _setFontSizeUseCase;
  final ReaderSetLineHeightUseCase _setLineHeightUseCase;
  final ReaderSetSmoothScrollUseCase _setSmoothScrollUseCase;

  /// Cubits.
  final ReaderSearchCubit _searchCubit;
  final ReaderTtsCubit _ttsCubit;
}

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit(
    this._dependenciesFactory,
    // Book use cases
    this._bookGetUseCase,
    // Bookmark use cases
    this._bookmarkGetDataUseCase,
    this._bookmarkUpdateDataUseCase,
    // Reader preference use cases
    this._getPreferenceUseCase,
    this._savePreferenceUseCase,
    this._observePreferenceChangeUseCase,
    this._resetPreferenceUseCase,
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

  ReaderSearchCubit get searchCubit => _dependencies._searchCubit;

  ReaderTtsCubit get ttsCubit => _dependencies._ttsCubit;

  /// Book use cases
  final BookGetUseCase _bookGetUseCase;

  /// Bookmark use cases
  final BookmarkGetDataUseCase _bookmarkGetDataUseCase;
  final BookmarkUpdateDataUseCase _bookmarkUpdateDataUseCase;

  /// Reader preference use cases
  final ReaderGetPreferenceUseCase _getPreferenceUseCase;
  final ReaderSavePreferenceUseCase _savePreferenceUseCase;
  final ReaderObservePreferenceChangeUseCase _observePreferenceChangeUseCase;
  final ReaderResetPreferenceUseCase _resetPreferenceUseCase;

  /// Stream Subscriptions
  final Set<StreamSubscription<dynamic>> _subscriptionSet =
      <StreamSubscription<dynamic>>{};

  /// Initialize from widgets.
  Future<void> init({
    required String bookIdentifier,
    required ThemeData currentTheme,
    String? chapterIdentifier,
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

    // Load the book data.
    emit(state.copyWith(
      coreType: readerSettingsData.coreType,
      code: ReaderLoadingStateCode.bookLoading,
    ));

    // Register Listeners
    _subscriptionSet
        .add(_dependencies._observeLoadDoneUseCase().listen(_receiveLoadDone));
    _subscriptionSet
        .add(_dependencies._observeSetStateUseCase().listen(_receiveSetState));
    _subscriptionSet
        .add(_observePreferenceChangeUseCase().listen(_refreshPreference));

    // Start loading the data of book, and bookmarks.
    late BookmarkData? bookmarkData;
    await Future.wait<void>(<Future<void>>[
      _bookGetUseCase(bookIdentifier)
          .then((Book value) => this.bookData = value),
      _bookmarkGetDataUseCase(bookIdentifier)
          .then((BookmarkData? data) => bookmarkData = data),
    ]);

    if (!isClosed) {
      // Emit state.
      emit(state.copyWith(
        code: ReaderLoadingStateCode.rendering,
        bookName: this.bookData?.title,
        bookmarkData: bookmarkData,
        readerPreference: readerSettingsData,
      ));

      await _dependencies._coreRepository.init(
        bookIdentifier: bookIdentifier,
        chapterIdentifier: chapterIdentifier,
        cfi: cfi,
      );
    }
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

  void savePreference() => _savePreferenceUseCase(state.readerPreference);

  Future<void> resetPreference() async {
    await _resetPreferenceUseCase();
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

  void saveBookmark() {
    final BookmarkData data = BookmarkData(
      bookIdentifier: bookData!.identifier,
      bookName: state.bookName,
      chapterTitle: state.breadcrumb,
      chapterIdentifier: state.chapterFileName,
      startCfi: state.startCfi,
      savedTime: DateTime.now(),
    );

    _bookmarkUpdateDataUseCase(<BookmarkData>{data});

    emit(state.copyWith(bookmarkData: data));
  }

  /// *************************************************************************
  /// Page Navigation
  /// *************************************************************************

  void previousPage() {
    _dependencies._previousPageUseCase();
  }

  void nextPage() {
    _dependencies._nextPageUseCase();
  }

  /// *************************************************************************
  /// Communication
  /// *************************************************************************

  void _receiveLoadDone(void _) {
    emit(state.copyWith(code: ReaderLoadingStateCode.loaded));

    // Send theme data after the page is loaded.
    sendThemeData();

    // Set smooth scroll.
    _dependencies
        ._setSmoothScrollUseCase(state.readerPreference.isSmoothScroll);
  }

  void _receiveSetState(ReaderSetStateData data) {
    emit(state.copyWith(
      breadcrumb: data.breadcrumb,
      chapterFileName: data.chapterIdentifier,
      startCfi: data.startCfi,
      chapterCurrentPage: data.chapterCurrentPage,
      chapterTotalPage: data.chapterTotalPage,
    ));

    if (state.readerPreference.isAutoSaving) {
      saveBookmark();
    }
  }

  /// *************************************************************************
  /// Miscellaneous
  /// *************************************************************************

  @override
  Future<void> close() async {
    for (StreamSubscription<dynamic> subscription in _subscriptionSet) {
      await subscription.cancel();
    }

    await _dependencies._coreRepository.dispose();
    super.close();
  }
}
