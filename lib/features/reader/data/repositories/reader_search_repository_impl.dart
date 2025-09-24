import 'dart:async';

import '../../domain/entities/reader_search_result_data.dart';
import '../../domain/repositories/reader_core_repository.dart';
import '../../domain/repositories/reader_search_repository.dart';

class ReaderSearchRepositoryImpl implements ReaderSearchRepository {
  ReaderSearchRepositoryImpl(this._coreRepository);

  final ReaderCoreRepository _coreRepository;

  @override
  void searchInCurrentChapter(String query) {
    _coreRepository.searchInCurrentChapter(query);
  }

  @override
  void searchInWholeBook(String query) {
    _coreRepository.searchInWholeBook(query);
  }

  @override
  Stream<List<ReaderSearchResultData>> get onSetSearchResultList =>
      _coreRepository.onSetSearchResultList;
}
