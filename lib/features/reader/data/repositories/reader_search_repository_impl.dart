import 'dart:async';

import '../../domain/entities/reader_search_result_data.dart';
import '../../domain/repositories/reader_search_repository.dart';
import '../../domain/repositories/reader_webview_repository.dart';

class ReaderSearchRepositoryImpl implements ReaderSearchRepository {
  ReaderSearchRepositoryImpl(this._webViewRepository);

  final ReaderWebViewRepository _webViewRepository;

  @override
  void searchInCurrentChapter(String query) {
    _webViewRepository.searchInCurrentChapter(query);
  }

  @override
  void searchInWholeBook(String query) {
    _webViewRepository.searchInWholeBook(query);
  }

  @override
  Stream<List<ReaderSearchResultData>> get onSetSearchResultList =>
      _webViewRepository.onSetSearchResultList;
}
