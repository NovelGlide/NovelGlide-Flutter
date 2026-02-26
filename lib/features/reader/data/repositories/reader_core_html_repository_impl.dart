import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../books/domain/entities/book_chapter.dart';
import '../../../books/domain/entities/book_html_content.dart';
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
  late List<BookPage> _pageList;
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

  String? _normalizePageIdentifier(String? pageIdentifier) {
    if (pageIdentifier == null) {
      return null;
    }

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

    // Enable book cache.
    _bookRepository.enableBookCache();

    await goto(
      pageIdentifier: pageIdentifier,
      cfi: cfi,
    );
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
    // Load the content.
    final BookHtmlContent content = await _bookRepository.getContent(
      _bookIdentifier,
      pageIdentifier: _normalizePageIdentifier(pageIdentifier),
    );

    // Store the page list for page navigation.
    _pageList = content.pageList;

    return content;
  }

  @override
  Future<void> nextPage() async {
    // Get the identifier of next page.
    final String pageIdentifier = _pageList[++_currentPageNumber].identifier;
    await goto(pageIdentifier: pageIdentifier);
  }

  @override
  Future<void> previousPage() async {
    // Get the identifier of next page.
    final String pageIdentifier = _pageList[--_currentPageNumber].identifier;
    await goto(pageIdentifier: pageIdentifier);
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
    final String optimalContent =
        content.textContent.replaceAll(RegExp(r'\s+'), ' ');
    int startIndex = 0;
    int targetIndex = optimalContent.indexOf(query, startIndex);

    while (targetIndex != -1) {
      final int start = max(0, targetIndex - 100);
      final int end = min(targetIndex + 100, optimalContent.length - 1);

      final bool hasPrevious = start > 0;
      final bool hasNext = end < optimalContent.length - 1;

      resultList.add(ReaderSearchResultData(
        destination: content.pageIdentifier,
        excerpt: (hasPrevious ? '...' : '') +
            optimalContent.substring(start, end) +
            (hasNext ? '...' : ''),
        targetIndex: targetIndex - start + (hasPrevious ? 3 : 0),
      ));

      startIndex = targetIndex + query.length;
      targetIndex = optimalContent.indexOf(query, startIndex);
    }

    return resultList;
  }

  // ---------------------------------------------------------------------------
  // Appearance setters
  //
  // The HTML Widget engine does NOT use imperative style setters. Instead,
  // all appearance changes are driven reactively through Flutter's state
  // management:
  //
  //   - fontSize & lineHeight: ReaderCubit emits a new ReaderPreferenceData
  //     state, which causes ReaderCoreHtmlWrapper to rebuild. ReaderCoreHtml
  //     reads fontSize and lineHeight directly from the state and passes them
  //     to flutter_html's Style API.
  //
  //   - fontColor: The HTML Widget inherits text color from the surrounding
  //     Flutter theme (Theme.of(context).colorScheme.onSurface) automatically.
  //     Font color is NOT user-configurable — ReaderCubit.sendThemeData() calls
  //     this setter only to keep parity with the WebView engine interface, which
  //     requires an explicit color push over the JS bridge.
  //
  //   - smoothScroll: Not applicable. Scroll behavior is controlled by Flutter's
  //     SingleChildScrollView and is not a toggleable property in this engine.
  // ---------------------------------------------------------------------------

  @override
  set fontColor(Color fontColor) {
    // No-op: font color is inherited from the Flutter theme automatically.
    // See note above.
  }

  @override
  set fontSize(double fontSize) {
    // No-op: font size is applied reactively via ReaderCoreHtml rebuilding
    // on ReaderPreferenceData state changes. See note above.
  }

  @override
  set lineHeight(double lineHeight) {
    // No-op: line height is applied reactively via ReaderCoreHtml rebuilding
    // on ReaderPreferenceData state changes. See note above.
  }

  @override
  set smoothScroll(bool smoothScroll) {
    // No-op: not applicable for SingleChildScrollView. See note above.
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
