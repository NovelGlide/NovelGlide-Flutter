part of '../../presentation/reader_page/cubit/reader_cubit.dart';

enum ReaderLoadingStateCode {
  initial,
  // Loading codes
  preferenceLoading,
  bookLoading,
  rendering,
  pageLoading,
  // Loaded codes.
  loaded;

  bool get isInitial => this == ReaderLoadingStateCode.initial;

  bool get isLoading =>
      this == ReaderLoadingStateCode.preferenceLoading ||
      this == ReaderLoadingStateCode.bookLoading ||
      this == ReaderLoadingStateCode.rendering ||
      this == ReaderLoadingStateCode.pageLoading;

  bool get isLoaded => this == ReaderLoadingStateCode.loaded;
}
