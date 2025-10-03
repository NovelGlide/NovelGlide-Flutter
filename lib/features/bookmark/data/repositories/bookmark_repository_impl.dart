import 'dart:async';

import '../../../books/domain/repositories/book_repository.dart';
import '../../domain/entities/bookmark_data.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../data_sources/bookmark_local_json_data_source.dart';

class BookmarkRepositoryImpl extends BookmarkRepository {
  BookmarkRepositoryImpl(this._localJsonDataSource, this._bookRepository);

  final BookmarkLocalJsonDataSource _localJsonDataSource;
  final BookRepository _bookRepository;

  final StreamController<void> _onChangedController =
      StreamController<void>.broadcast();

  @override
  Future<void> deleteData(Set<String> identifierSet) async {
    await _localJsonDataSource.deleteData(identifierSet);

    // Send a notification
    _onChangedController.add(null);
  }

  @override
  Future<BookmarkData?> getDataById(String id) {
    return _localJsonDataSource.getDataById(id);
  }

  @override
  Future<List<BookmarkData>> getList() async {
    final List<BookmarkData> list = await _localJsonDataSource.getList();
    final Set<String> deleted = <String>{};
    final List<BookmarkData> retList = <BookmarkData>[];

    // Filter the book doesn't exist
    for (BookmarkData data in list) {
      if (await _bookRepository.exists(data.bookIdentifier)) {
        retList.add(data);
      } else {
        deleted.add(data.bookIdentifier);
      }
    }

    // Delete the data
    if (deleted.isNotEmpty) {
      await deleteData(deleted);
    }

    return list;
  }

  @override
  Stream<void> get onChangedStream => _onChangedController.stream;

  @override
  Future<void> reset() async {
    await _localJsonDataSource.reset();

    // Send a notification
    _onChangedController.add(null);
  }

  @override
  Future<void> updateData(Set<BookmarkData> dataSet) async {
    await _localJsonDataSource.updateData(dataSet);

    // Send a notification
    _onChangedController.add(null);
  }
}
