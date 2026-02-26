import 'dart:async';

import '../entities/bookmark_data.dart';

abstract class BookmarkRepository {
  Stream<void> get onChangedStream;

  Future<BookmarkData?> getDataById(String id);

  Future<List<BookmarkData>> getList();

  Future<void> updateData(Set<BookmarkData> dataSet);

  Future<void> deleteData(Set<String> identifierSet);

  Future<void> reset();
}
