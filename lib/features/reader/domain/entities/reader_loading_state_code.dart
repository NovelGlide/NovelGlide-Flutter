part of '../../presentation/reader_page/cubit/reader_cubit.dart';

enum ReaderLoadingStateCode {
  initial,
  preferenceLoading,
  bookLoading,
  rendering,
  loaded;

  bool get isInitial => this == ReaderLoadingStateCode.initial;

  bool get isLoading =>
      this == ReaderLoadingStateCode.preferenceLoading ||
      this == ReaderLoadingStateCode.bookLoading ||
      this == ReaderLoadingStateCode.rendering;

  bool get isLoaded => this == ReaderLoadingStateCode.loaded;
}
