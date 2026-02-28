import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../enum/loading_state_code.dart';
import '../../../../book_storage/data/repositories/local_book_storage.dart';
import '../../../domain/entities/book_chapter.dart';
import '../../../domain/use_cases/book_get_chapter_list_use_case.dart';
import 'toc_nested_chapter_data.dart';
import 'toc_state.dart';

class TocCubit extends Cubit<TocState> {
  TocCubit(
    this._bookGetChapterListUseCase,
    this._localBookStorage,
  ) : super(const TocState());

  /// Use cases and repositories
  final BookGetChapterListUseCase _bookGetChapterListUseCase;
  final LocalBookStorage _localBookStorage;

  /// Used by widgets
  final PageStorageBucket bucket = PageStorageBucket();
  final ScrollController scrollController = ScrollController();

  /// Cubit data
  late final String _bookIdentifier;

  /// Stream subscription
  late final StreamSubscription<void> _onChangedSubscription;

  Future<void> startLoading(String identifier) async {
    _bookIdentifier = identifier;

    // Listen to book metadata changes via LocalBookStorage
    _onChangedSubscription =
        _localBookStorage.changeStream().listen((changedId) {
      if (changedId == _bookIdentifier) {
        refresh();
      }
    });

    // Refresh at first
    refresh();
  }

  Future<void> refresh() async {
    // Start loading
    emit(const TocState(code: LoadingStateCode.loading));

    // Get the current reading position from BookMetadata
    String? currentPositionCfi;
    try {
      final metadata = await _localBookStorage.readMetadata(_bookIdentifier);
      if (metadata != null) {
        currentPositionCfi = metadata.readingState.cfiPosition;
      }
    } catch (e) {
      print('Error reading metadata for TOC: $e');
    }

    // Load the chapter list
    final List<BookChapter> chapterList =
        await _bookGetChapterListUseCase(_bookIdentifier);

    // Finish loading
    emit(state.copyWith(
      code: LoadingStateCode.loaded,
      currentPositionCfi: currentPositionCfi,
      chapterList: _constructChapterTree(chapterList, 0),
    ));
  }

  /// Constructs the chapter n-ary tree.
  /// [chapterDataList] is the list of chapters to be traversed.
  /// [nestedLevel] is the nesting level of the current chapter.
  /// [nestedLevel] will be used to calculate the indentation of the chapter tile.
  List<TocNestedChapterData> _constructChapterTree(
    List<BookChapter> chapterDataList,
    int nestedLevel,
  ) {
    // Tree root
    final List<TocNestedChapterData> list = <TocNestedChapterData>[];

    // Traverse the sub chapters
    for (final BookChapter data in chapterDataList) {
      list.add(TocNestedChapterData(
        chapterData: data,
        nestedLevel: nestedLevel,
      ));

      // If the chapter has sub chapters, traverse them
      if (data.subChapterList.isNotEmpty) {
        list.addAll(
          _constructChapterTree(data.subChapterList, nestedLevel + 1),
        );
      }
    }
    return list;
  }

  @override
  Future<void> close() {
    _onChangedSubscription.cancel();
    return super.close();
  }
}
