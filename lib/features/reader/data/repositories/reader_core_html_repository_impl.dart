import 'dart:async';

import 'package:flutter/material.dart';

import '../../../books/domain/entities/book_chapter.dart';
import '../../../books/domain/entities/book_content.dart';
import '../../../books/domain/entities/book_page.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../domain/entities/reader_search_result_data.dart';
import '../../domain/entities/reader_set_state_data.dart';
import '../../domain/repositories/reader_core_repository.dart';

class ReaderCoreHtmlRepositoryImpl implements ReaderCoreRepository {
  ReaderCoreHtmlRepositoryImpl(
    this._bookRepository,
  );

  final BookRepository _bookRepository;

  late final String _bookIdentifier;
  late final List<BookPage> _pageList;
  int _currentPage = 0;

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
    // Save the current book identifier.
    _bookIdentifier = bookIdentifier;

    // Load the content.
    final BookContent content = await _bookRepository.getContent(
      bookIdentifier,
      chapterIdentifier: chapterIdentifier,
    );

    // Store the page list for page navigation.
    _pageList = content.pageList;

    // Calculate the current page number.
    _currentPage = _pageList.indexWhere(
        (BookPage page) => page.identifier == content.chapterIdentifier);

    _setStateStreamController.add(ReaderSetStateData(
      breadcrumb: _constructBreadcrumb(
            await _bookRepository.getChapterList(bookIdentifier),
            content.chapterIdentifier,
          ) ??
          '',
      chapterIdentifier: content.chapterIdentifier,
      startCfi: '',
      chapterCurrentPage: _currentPage + 1,
      chapterTotalPage: _pageList.length,
      content: content.content,
      atStart: _pageList.first.identifier == content.chapterIdentifier,
      atEnd: _pageList.last.identifier == content.chapterIdentifier,
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
        chapter.subChapterList,
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
  Future<void> nextPage() async {
    // Get the identifier of next page.
    final String chapterIdentifier = _pageList[++_currentPage].identifier;

    // Load the content.
    final BookContent content = await _bookRepository.getContent(
      _bookIdentifier,
      chapterIdentifier: chapterIdentifier,
    );

    _setStateStreamController.add(ReaderSetStateData(
      breadcrumb: _constructBreadcrumb(
            await _bookRepository.getChapterList(_bookIdentifier),
            content.chapterIdentifier,
          ) ??
          '',
      chapterIdentifier: content.chapterIdentifier,
      startCfi: '',
      chapterCurrentPage: _currentPage + 1,
      chapterTotalPage: _pageList.length,
      content: content.content,
      atStart: _pageList.first.identifier == content.chapterIdentifier,
      atEnd: _pageList.last.identifier == content.chapterIdentifier,
    ));
  }

  @override
  Future<void> previousPage() async {
    // Get the identifier of next page.
    final String chapterIdentifier = _pageList[--_currentPage].identifier;

    // Load the content.
    final BookContent content = await _bookRepository.getContent(
      _bookIdentifier,
      chapterIdentifier: chapterIdentifier,
    );

    _setStateStreamController.add(ReaderSetStateData(
      breadcrumb: _constructBreadcrumb(
            await _bookRepository.getChapterList(_bookIdentifier),
            content.chapterIdentifier,
          ) ??
          '',
      chapterIdentifier: content.chapterIdentifier,
      startCfi: '',
      chapterCurrentPage: _currentPage + 1,
      chapterTotalPage: _pageList.length,
      content: content.content,
      atStart: _pageList.first.identifier == content.chapterIdentifier,
      atEnd: _pageList.last.identifier == content.chapterIdentifier,
    ));
  }

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
  set fontColor(Color fontColor) {
    // No-ops
  }

  @override
  set fontSize(double fontSize) {
    // No-ops
  }

  @override
  set lineHeight(double lineHeight) {
    // No-ops
  }

  @override
  set smoothScroll(bool smoothScroll) {
    // No-ops
  }

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
