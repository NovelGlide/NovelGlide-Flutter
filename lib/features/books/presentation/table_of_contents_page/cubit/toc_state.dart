import 'package:equatable/equatable.dart';

import '../../../../../enum/loading_state_code.dart';
import 'toc_nested_chapter_data.dart';

class TocState extends Equatable {
  const TocState({
    this.code = LoadingStateCode.initial,
    this.currentPositionCfi,
    this.chapterList = const <TocNestedChapterData>[],
  });

  final LoadingStateCode code;
  final String? currentPositionCfi;
  final List<TocNestedChapterData> chapterList;

  @override
  List<Object?> get props => <Object?>[code, currentPositionCfi, chapterList];

  TocState copyWith({
    LoadingStateCode? code,
    String? currentPositionCfi,
    List<TocNestedChapterData>? chapterList,
  }) {
    return TocState(
      code: code ?? this.code,
      currentPositionCfi: currentPositionCfi ?? this.currentPositionCfi,
      chapterList: chapterList ?? this.chapterList,
    );
  }
}
