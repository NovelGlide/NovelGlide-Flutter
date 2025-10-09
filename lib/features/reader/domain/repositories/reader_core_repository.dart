import 'package:flutter/material.dart';

import '../entities/reader_search_result_data.dart';
import '../entities/reader_set_state_data.dart';

abstract class ReaderCoreRepository {
  Future<void> init({
    required String bookIdentifier,
    String? pageIdentifier,
    String? cfi,
  });

  Future<void> goto({
    String? pageIdentifier,
    String? cfi,
  });

  Future<void> nextPage();

  Future<void> previousPage();

  void ttsPlay();

  void ttsNext();

  void ttsStop();

  void searchInCurrentChapter(String query);

  void searchInWholeBook(String query);

  set fontColor(Color fontColor);

  set fontSize(double fontSize);

  set lineHeight(double lineHeight);

  set smoothScroll(bool smoothScroll);

  Stream<ReaderSetStateData> get onSetState;

  Stream<String> get onPlayTts;

  Stream<void> get onStopTts;

  Stream<void> get onEndTts;

  Stream<List<ReaderSearchResultData>> get onSetSearchResultList;

  Future<void> dispose();
}
