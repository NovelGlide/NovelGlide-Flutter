import 'dart:math';

import 'package:novel_glide/core/file_system/domain/repositories/json_repository.dart';
import 'package:novel_glide/core/path_provider/domain/repositories/json_path_provider.dart';
import 'package:novel_glide/core/utils/random_extension.dart';
import 'package:novel_glide/features/collection/domain/entities/collection_data.dart';
import 'collection_local_json_data_source.dart';

/// Local JSON data source implementation for collections.
///
/// Persists collections to local JSON files, with each collection
/// identified by a stable BookId-based list instead of filenames.
///
/// JSON format:
/// ```json
/// {
///   "col-id": {
///     "id": "col-id",
///     "name": "Collection Name",
///     "bookIds": ["book-uuid-1", "book-uuid-2"],
///     "description": "Collection description",
///     "createdAt": "2026-03-01T00:00:00.000Z",
///     "updatedAt": "2026-03-01T00:00:00.000Z",
///     "color": "#FF5722"
///   }
/// }
/// ```
class CollectionLocalJsonDataSourceImpl
    extends CollectionLocalJsonDataSource {
  /// Creates a [CollectionLocalJsonDataSourceImpl] instance.
  ///
  /// Requires [JsonPathProvider] for path resolution and
  /// [JsonRepository] for file I/O operations.
  CollectionLocalJsonDataSourceImpl(
    this._jsonPathProvider,
    this._jsonRepository,
  );

  final JsonPathProvider _jsonPathProvider;
  final JsonRepository _jsonRepository;

  @override
  Future<CollectionData> createData([String? name]) async {
    // Load existing collections
    final Map<String, dynamic> json = await _loadData();

    // Generate unique collection ID
    String id;
    do {
      id = Random().nextString(10);
    } while (json.containsKey(id));

    // Create new collection with default values
    final DateTime now = DateTime.now();
    final CollectionData data = CollectionData(
      id: id,
      name: name ?? id,
      bookIds: const <String>[],
      description: '',
      createdAt: now,
      updatedAt: now,
      color: '#808080',
    );

    // Persist to JSON
    json[data.id] = data.toJson();
    await _writeData(json);

    return data;
  }

  @override
  Future<void> deleteData(Set<CollectionData> dataSet) async {
    // Load existing collections
    final Map<String, dynamic> json = await _loadData();

    // Remove collections by ID
    for (final CollectionData data in dataSet) {
      json.remove(data.id);
    }

    // Persist changes
    await _writeData(json);
  }

  @override
  Future<CollectionData> getDataById(String id) async {
    // Load existing collections
    final Map<String, dynamic> json = await _loadData();

    // Return existing collection or create new one
    if (json.containsKey(id)) {
      return CollectionData.fromJson(
        json[id] as Map<String, dynamic>,
      );
    }

    // Default: new empty collection
    final DateTime now = DateTime.now();
    return CollectionData(
      id: id,
      name: id,
      bookIds: const <String>[],
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<List<CollectionData>> getList() async {
    // Load existing collections
    final Map<String, dynamic> json = await _loadData();

    // Convert JSON entries to CollectionData entities
    return json.values
        .map(
          (final dynamic entry) =>
              CollectionData.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> updateData(Set<CollectionData> dataSet) async {
    // Load existing collections
    final Map<String, dynamic> json = await _loadData();

    // Update each collection in the set
    for (final CollectionData data in dataSet) {
      json[data.id] = data.toJson();
    }

    // Persist changes
    await _writeData(json);
  }

  @override
  Future<void> reset() async {
    return _writeData(<String, dynamic>{});
  }

  /// Load collections from JSON file.
  ///
  /// Returns an empty map if the file doesn't exist or is empty.
  Future<Map<String, dynamic>> _loadData() async {
    final String jsonPath = await _jsonPathProvider.collectionJsonPath;
    return _jsonRepository.readJson(path: jsonPath);
  }

  /// Write collections to JSON file.
  ///
  /// Persists the [json] map to the collection JSON file.
  Future<void> _writeData(Map<String, dynamic> json) async {
    final String jsonPath = await _jsonPathProvider.collectionJsonPath;
    await _jsonRepository.writeJson(path: jsonPath, data: json);
  }
}
