import '../entities/reader_search_result_data.dart';

abstract class ReaderSearchRepository {
  void searchInCurrentChapter(String query);

  void searchInWholeBook(String query);

  Stream<List<ReaderSearchResultData>> get onSetSearchResultList;
}
