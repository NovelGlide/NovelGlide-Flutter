import 'dart:async';

import '../../domain/entities/bookmark_data.dart';

abstract class BookmarkLocalJsonDataSource {
  Future<BookmarkData?> getDataById(String identifier);

  Future<List<BookmarkData>> getList();

  Future<void> updateData(Set<BookmarkData> dataSet);

  Future<void> deleteData(Set<String> identifierSet);

  Future<void> reset();
}
