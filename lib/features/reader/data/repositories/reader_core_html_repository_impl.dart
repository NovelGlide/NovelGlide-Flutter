import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../books/domain/entities/book_chapter.dart';
import '../../../books/domain/entities/book_html_content.dart';
import '../../../books/domain/entities/book_page.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../domain/entities/reader_search_result_data.dart';
import '../../domain/entities/reader_set_state_data.dart';
import '../../domain/exceptions/reader_page_not_in_book_exception.dart';
import '../../domain/repositories/reader_core_repository.dart';

class ReaderCoreHtmlRepositoryImpl implements ReaderCoreRepository {
  ReaderCoreHtmlRepositoryImpl(
    this._bookRepository,
  );

  final BookRepository _bookRepository;

  late final String _bookIdentifier;
  late final List<BookPage> _pageList;
  int _currentPageNumber = 0;
  late BookHtmlContent _htmlContent;

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

  String _normalizePageIdentifier(String pageIdentifier) {
    // Remove fragment identifier.
    final int hashSymbolIndex = pageIdentifier.indexOf('#');
    return hashSymbolIndex != -1
        ? pageIdentifier.substring(0, hashSymbolIndex)
        : pageIdentifier;
  }

  @override
  Future<void> init({
    required String bookIdentifier,
    String? pageIdentifier,
    String? cfi,
  }) async {
    // Save the current book identifier.
    _bookIdentifier = bookIdentifier;

    // Normalize page identifier
    final String normalizedIdentifier =
        _normalizePageIdentifier(pageIdentifier ?? '');

    // Enable book cache.
    _bookRepository.enableBookCache();

    // Load the content.
    final BookHtmlContent content = await _bookRepository.getContent(
      _bookIdentifier,
      pageIdentifier: normalizedIdentifier,
    );

    // Store the page list for page navigation.
    _pageList = content.pageList;

    await _sendState(content);
  }

  String? _constructBreadcrumb(
    List<BookChapter> chapterList,
    String chapterIdentifier, {
    String breadcrumbs = '',
    int level = 0,
  }) {
    for (BookChapter chapter in chapterList) {
      String currentBreadcrumbs = breadcrumbs;
      currentBreadcrumbs +=
          (currentBreadcrumbs.isNotEmpty ? ' > ' : '') + chapter.title.trim();

      if (chapter.identifier == chapterIdentifier) {
        return currentBreadcrumbs;
      }

      final String? result = _constructBreadcrumb(
        chapter.subChapterList,
        chapterIdentifier,
        breadcrumbs: currentBreadcrumbs,
        level: level + 1,
      );

      if (result?.isNotEmpty == true) {
        return result;
      }
    }

    return null;
  }

  @override
  Future<void> goto({String? pageIdentifier, String? cfi}) async {
    // Load the content.
    final BookHtmlContent content = await _loadContent(
      pageIdentifier: pageIdentifier,
      cfi: cfi,
    );

    _sendState(content);
  }

  Future<BookHtmlContent> _loadContent({
    String? pageIdentifier,
    String? cfi,
  }) async {
    // Normalize page identifier
    final String normalizedIdentifier =
        _normalizePageIdentifier(pageIdentifier ?? '');

    final bool isInBook = _pageList
        .any((BookPage page) => page.identifier == normalizedIdentifier);

    if (isInBook) {
      // Load the content.
      return await _bookRepository.getContent(
        _bookIdentifier,
        pageIdentifier: normalizedIdentifier,
      );
    } else {
      throw ReaderPageNotInBookException(
        pageIdentifier: normalizedIdentifier,
      );
    }
  }

  @override
  Future<void> nextPage() async {
    // Get the identifier of next page.
    final String chapterIdentifier = _pageList[++_currentPageNumber].identifier;

    // Load the content.
    final BookHtmlContent content = await _bookRepository.getContent(
      _bookIdentifier,
      pageIdentifier: chapterIdentifier,
    );

    await _sendState(content);
  }

  @override
  Future<void> previousPage() async {
    // Get the identifier of next page.
    final String chapterIdentifier = _pageList[--_currentPageNumber].identifier;

    // Load the content.
    final BookHtmlContent content = await _bookRepository.getContent(
      _bookIdentifier,
      pageIdentifier: chapterIdentifier,
    );

    await _sendState(content);
  }

  Future<void> _sendState(BookHtmlContent content) async {
    // Save the content
    _htmlContent = content;

    // Calculate the current page number.
    _currentPageNumber = _pageList.indexWhere(
        (BookPage page) => page.identifier == content.pageIdentifier);

    _setStateStreamController.add(ReaderSetStateData(
      breadcrumb: _constructBreadcrumb(
            await _bookRepository.getChapterList(_bookIdentifier),
            content.pageIdentifier,
          ) ??
          '',
      chapterIdentifier: content.pageIdentifier,
      startCfi: '',
      chapterCurrentPage: _currentPageNumber + 1,
      chapterTotalPage: _pageList.length,
      content: content,
      atStart: _pageList.first.identifier == content.pageIdentifier,
      atEnd: _pageList.last.identifier == content.pageIdentifier,
    ));
  }

  @override
  void ttsPlay() {
    // Play the content.
    _ttsPlayStreamController.add(_htmlContent.textContent);
  }

  @override
  void ttsNext() {
    _ttsEndStreamController.add(null);
  }

  @override
  void ttsStop() {
    _ttsStopStreamController.add(null);
  }

  @override
  Future<void> searchInCurrentChapter(String query) async {
    _searchResultStreamController.add(await _searchInContent(
      _htmlContent,
      query,
    ));
  }

  @override
  Future<void> searchInWholeBook(String query) async {
    final List<ReaderSearchResultData> resultList = <ReaderSearchResultData>[];

    for (BookPage page in _pageList) {
      final BookHtmlContent content = await _loadContent(
        pageIdentifier: page.identifier,
      );

      resultList.addAll(await _searchInContent(content, query));
    }

    _searchResultStreamController.add(resultList);
  }

  Future<List<ReaderSearchResultData>> _searchInContent(
    BookHtmlContent content,
    String query,
  ) async {
    final List<ReaderSearchResultData> resultList = <ReaderSearchResultData>[];
    int startIndex = 0;
    int targetIndex = content.textContent.indexOf(query, startIndex);

    while (targetIndex != -1) {
      final int start = max(0, targetIndex - 100);
      final int end = min(targetIndex + 100, content.textContent.length - 1);
      resultList.add(ReaderSearchResultData(
        destination: content.pageIdentifier,
        excerpt: content.textContent.substring(start, end),
        targetIndex: targetIndex - start,
      ));

      startIndex = targetIndex + query.length;
      targetIndex = content.textContent.indexOf(query, startIndex);
    }

    return resultList;
  }

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
    // Disable book cache.
    _bookRepository.disableBookCache();

    await _setStateStreamController.close();
    await _ttsPlayStreamController.close();
    await _ttsStopStreamController.close();
    await _ttsEndStreamController.close();
    await _searchResultStreamController.close();
  }
}
