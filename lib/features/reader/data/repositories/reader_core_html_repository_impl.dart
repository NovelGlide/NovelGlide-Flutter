import 'dart:async';

import 'package:flutter/material.dart';

import '../../../books/domain/repositories/book_repository.dart';
import '../../domain/entities/reader_search_result_data.dart';
import '../../domain/entities/reader_set_state_data.dart';
import '../../domain/repositories/reader_core_repository.dart';

class ReaderCoreHtmlRepositoryImpl implements ReaderCoreRepository {
  ReaderCoreHtmlRepositoryImpl(this._bookRepository);

  final BookRepository _bookRepository;

  /// Stream Controllers
  final StreamController<void> _loadDoneStreamController =
      StreamController<void>.broadcast();
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

  @override
  Future<void> init({
    required String bookIdentifier,
    String? chapterIdentifier,
    String? cfi,
  }) async {}

  @override
  Future<void> goto(String destination) async {}

  @override
  Future<void> nextPage() async {}

  @override
  Future<void> previousPage() async {}

  @override
  void ttsPlay() {}

  @override
  void ttsNext() {}

  @override
  void ttsStop() {}

  @override
  void searchInCurrentChapter(String query) {}

  @override
  void searchInWholeBook(String query) {}

  @override
  set fontColor(Color fontColor) {}

  @override
  set fontSize(double fontSize) {}

  @override
  set lineHeight(double lineHeight) {}

  @override
  set smoothScroll(bool smoothScroll) {}

  @override
  Stream<void> get onLoadDone => _loadDoneStreamController.stream;

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
    await _loadDoneStreamController.close();
    await _setStateStreamController.close();
    await _ttsPlayStreamController.close();
    await _ttsStopStreamController.close();
    await _ttsEndStreamController.close();
    await _searchResultStreamController.close();
  }
}
