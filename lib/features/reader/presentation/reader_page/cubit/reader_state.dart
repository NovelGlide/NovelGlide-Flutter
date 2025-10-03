part of 'reader_cubit.dart';

class ReaderState extends Equatable {
  const ReaderState({
    this.code = ReaderLoadingStateCode.initial,
    this.coreType,
    this.bookName = '',
    this.breadcrumb = '',
    this.chapterFileName = '',
    this.startCfi = '',
    this.chapterCurrentPage = 0,
    this.chapterTotalPage = 0,
    this.content = '',
    this.navigationStateCode = ReaderNavigationStateCode.defaultState,
    this.bookmarkData,
    this.readerPreference = const ReaderPreferenceData(),
    this.atStart = true,
    this.atEnd = true,
  });

  final ReaderLoadingStateCode code;
  final ReaderCoreType? coreType;

  /// Book state.
  final String bookName;
  final String breadcrumb;
  final String chapterFileName;
  final String startCfi;
  final int chapterCurrentPage;
  final int chapterTotalPage;
  final String content;
  final bool atStart;
  final bool atEnd;

  /// Bottom buttons state.
  final ReaderNavigationStateCode navigationStateCode;

  /// Bookmark
  final BookmarkData? bookmarkData;

  /// Settings
  final ReaderPreferenceData readerPreference;

  @override
  List<Object?> get props => <Object?>[
        code,
        bookName,
        breadcrumb,
        chapterFileName,
        chapterCurrentPage,
        chapterTotalPage,
        content,
        navigationStateCode,
        bookmarkData,
        readerPreference,
        atStart,
        atEnd,
      ];

  ReaderState copyWith({
    ReaderCoreType? coreType,
    ReaderLoadingStateCode? code,
    String? bookName,
    String? breadcrumb,
    String? chapterFileName,
    String? startCfi,
    int? chapterCurrentPage,
    int? chapterTotalPage,
    String? content,
    ReaderNavigationStateCode? navigationStateCode,
    ValueGetter<BookmarkData?>? bookmarkDataGetter,
    ReaderPreferenceData? readerPreference,
    bool? atStart,
    bool? atEnd,
  }) {
    return ReaderState(
      coreType: coreType ?? this.coreType,
      code: code ?? this.code,
      bookName: bookName ?? this.bookName,
      breadcrumb: breadcrumb ?? this.breadcrumb,
      chapterFileName: chapterFileName ?? this.chapterFileName,
      startCfi: startCfi ?? this.startCfi,
      chapterCurrentPage: chapterCurrentPage ?? this.chapterCurrentPage,
      chapterTotalPage: chapterTotalPage ?? this.chapterTotalPage,
      content: content ?? this.content,
      navigationStateCode: navigationStateCode ?? this.navigationStateCode,
      bookmarkData:
          bookmarkDataGetter == null ? bookmarkData : bookmarkDataGetter(),
      readerPreference: readerPreference ?? this.readerPreference,
      atStart: atStart ?? this.atStart,
      atEnd: atEnd ?? this.atEnd,
    );
  }
}
