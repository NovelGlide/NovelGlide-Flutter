import 'dart:async';

import 'package:flutter/material.dart';

import '../../../books/domain/entities/book_chapter.dart';
import '../../../books/domain/entities/book_content.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../domain/entities/reader_search_result_data.dart';
import '../../domain/entities/reader_set_state_data.dart';
import '../../domain/repositories/reader_core_repository.dart';

class ReaderCoreHtmlRepositoryImpl implements ReaderCoreRepository {
  ReaderCoreHtmlRepositoryImpl(this._bookRepository);

  final BookRepository _bookRepository;

  /// Stream Controllers
  final StreamController<ReaderSetStateData> _setStateStreamController =
      StreamController<ReaderSetStateData>.broadcast();
  final StreamController<String> _ttsPlayStreamController =
      StreamController<String>.broadcast();
  final StreamController<void> _ttsStopStreamController =
      StreamController<void>.broadcast();
  final StreamController<void> _ttsEndStreamController =
      StreamController<void>.broadcast();
  final StreamController<List<ReaderSearchResultData>>
      _searchResultStreamController =
      StreamController<List<ReaderSearchResultData>>.broadcast();

  @override
  Future<void> loadContent({
    required String bookIdentifier,
    String? chapterIdentifier,
    String? cfi,
  }) async {
    final BookContent content = await _bookRepository.getContent(
      bookIdentifier,
      chapterIdentifier: chapterIdentifier,
    );

    _setStateStreamController.add(ReaderSetStateData(
      breadcrumb: _constructBreadcrumb(
        await _bookRepository.getChapterList(bookIdentifier),
        chapterIdentifier ?? '',
      ),
      chapterIdentifier: content.chapterIdentifier,
      startCfi: '',
      chapterCurrentPage: 1,
      chapterTotalPage: 1,
      content: content.content,
    ));
  }

  String? _constructBreadcrumb(
    List<BookChapter> chapterList,
    String chapterIdentifier, {
    String breadcrumbs = '',
    int level = 0,
  }) {
    for (BookChapter chapter in chapterList) {
      breadcrumbs +=
          (breadcrumbs.isNotEmpty ? ' > ' : '') + chapter.title.trim();

      if (chapter.identifier == chapterIdentifier) {
        return breadcrumbs;
      }

      final String? result = _constructBreadcrumb(
        chapterList,
        chapterIdentifier,
        breadcrumbs: breadcrumbs,
        level: level + 1,
      );

      if (result?.isNotEmpty == true) {
        return result;
      }
    }

    return null;
  }

  @override
  Future<void> goto(String destination) async {}

  @override
  Future<void> nextPage() async {}

  @override
  Future<void> previousPage() async {}

  @override
  void ttsPlay() {}

  @override
  void ttsNext() {}

  @override
  void ttsStop() {}

  @override
  void searchInCurrentChapter(String query) {}

  @override
  void searchInWholeBook(String query) {}

  @override
  set fontColor(Color fontColor) {}

  @override
  set fontSize(double fontSize) {}

  @override
  set lineHeight(double lineHeight) {}

  @override
  set smoothScroll(bool smoothScroll) {}

  @override
  Stream<ReaderSetStateData> get onSetState => _setStateStreamController.stream;

  @override
  Stream<String> get onPlayTts => _ttsPlayStreamController.stream;

  @override
  Stream<void> get onStopTts => _ttsStopStreamController.stream;

  @override
  Stream<void> get onEndTts => _ttsEndStreamController.stream;

  @override
  Stream<List<ReaderSearchResultData>> get onSetSearchResultList =>
      _searchResultStreamController.stream;

  @override
  Future<void> dispose() async {
    await _setStateStreamController.close();
    await _ttsPlayStreamController.close();
    await _ttsStopStreamController.close();
    await _ttsEndStreamController.close();
    await _searchResultStreamController.close();
  }
}
