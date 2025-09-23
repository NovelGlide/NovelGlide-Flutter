import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../enum/loading_state_code.dart';
import '../../../domain/entities/reader_search_result_data.dart';
import '../../../domain/use_cases/reader_goto_use_case.dart';
import '../../../domain/use_cases/search_use_cases/reader_observe_search_list_use_case.dart';
import '../../../domain/use_cases/search_use_cases/reader_search_in_current_chapter_use_case.dart';
import '../../../domain/use_cases/search_use_cases/reader_search_in_whole_book_use_case.dart';

part 'reader_search_range_code.dart';
part 'reader_search_state.dart';

class ReaderSearchCubit extends Cubit<ReaderSearchState> {
  ReaderSearchCubit(
    this._searchInCurrentChapterUseCase,
    this._searchInWholeBookUseCase,
    this._observeSearchListUseCase,
    this._sendGotoUseCase,
  ) : super(const ReaderSearchState());

  final ReaderSearchInCurrentChapterUseCase _searchInCurrentChapterUseCase;
  final ReaderSearchInWholeBookUseCase _searchInWholeBookUseCase;
  final ReaderObserveSearchListUseCase _observeSearchListUseCase;
  final ReaderGotoUseCase _sendGotoUseCase;

  /// Stream Subscriptions
  late final StreamSubscription<List<ReaderSearchResultData>>
      _resultListSubscription =
      _observeSearchListUseCase().listen(_setResultList);

  void startSearch() {
    emit(state.copyWith(code: LoadingStateCode.loading));
    switch (state.range) {
      case ReaderSearchRangeCode.currentChapter:
        _searchInCurrentChapterUseCase(state.query);
        break;
      case ReaderSearchRangeCode.all:
        _searchInWholeBookUseCase(state.query);
        break;
    }
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query.trim()));
  }

  void setRange(ReaderSearchRangeCode range) {
    emit(state.copyWith(range: range));
  }

  void _setResultList(List<ReaderSearchResultData> list) {
    emit(
      state.copyWith(
        code: LoadingStateCode.loaded,
        resultList: list,
      ),
    );
  }

  void goto(String cfi) => _sendGotoUseCase(cfi);

  @override
  Future<void> close() async {
    await _resultListSubscription.cancel();
    super.close();
  }
}
