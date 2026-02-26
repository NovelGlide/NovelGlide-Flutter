import 'dart:async';

import '../../../../core/file_system/domain/repositories/json_repository.dart';
import '../../../../core/path_provider/domain/repositories/json_path_provider.dart';
import '../../domain/entities/bookmark_data.dart';
import 'bookmark_json_parser.dart';
import 'bookmark_local_json_data_source.dart';

class BookmarkLocalJsonDataSourceImpl extends BookmarkLocalJsonDataSource
    with BookmarkJsonParser {
  BookmarkLocalJsonDataSourceImpl(this._jsonPathProvider, this._jsonRepository);

  final JsonPathProvider _jsonPathProvider;
  final JsonRepository _jsonRepository;

  @override
  Future<void> deleteData(Set<String> identifierSet) async {
    // Load the data
    final Map<String, dynamic> json = await _loadData();

    // Process the data set
    for (String identifier in identifierSet) {
      if (json.containsKey(identifier)) {
        json.remove(identifier);
      }
    }

    // Save to file
    await _writeData(json);
  }

  @override
  Future<BookmarkData?> getDataById(String identifier) async {
    // Load the data
    final Map<String, dynamic> json = await _loadData();

    if (json.containsKey(identifier) && json[identifier] != null) {
      return decodeBookmarkJson(json[identifier]);
    }

    return null;
  }

  @override
  Future<List<BookmarkData>> getList() async {
    // Load the data
    final Map<String, dynamic> json = await _loadData();

    // Create the list
    final List<BookmarkData> retList = <BookmarkData>[];

    // Loop through the data
    for (Map<String, dynamic> value in json.values) {
      retList.add(decodeBookmarkJson(value));
    }

    return retList;
  }

  @override
  Future<void> reset() {
    return _writeData(<String, dynamic>{});
  }

  @override
  Future<void> updateData(Set<BookmarkData> dataSet) async {
    // Load the data
    final Map<String, dynamic> json = await _loadData();

    // Process the data set
    for (BookmarkData data in dataSet) {
      // Get the identifier of the book
      final String identifier = data.bookIdentifier;

      json[identifier] = encodeBookmarkJson(data);
    }

    // Write to file
    await _writeData(json);
  }

  /// ========== Utilities ==========

  /// Load json data
  Future<Map<String, dynamic>> _loadData() async {
    final String jsonPath = await _jsonPathProvider.bookmarkJsonPath;
    return _jsonRepository.readJson(path: jsonPath);
  }

  /// Write to file
  Future<void> _writeData(Map<String, dynamic> json) async {
    final String jsonPath = await _jsonPathProvider.bookmarkJsonPath;
    await _jsonRepository.writeJson(path: jsonPath, data: json);
  }
}
