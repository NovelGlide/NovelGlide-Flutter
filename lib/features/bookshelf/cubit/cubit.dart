import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data_model/book_data.dart';
import '../../../enum/loading_state_code.dart';
import '../../../enum/sort_order_code.dart';
import '../../../preference_keys/preference_keys.dart';
import '../../../repository/book_repository.dart';
import '../../../utils/book_utils.dart';
import '../../../utils/file_path.dart';
import '../../../utils/mime_resolver.dart';
import '../../common_components/common_list/list_template.dart';

class BookshelfCubit extends CommonListCubit<BookData> {
  factory BookshelfCubit() {
    final BookshelfCubit cubit =
        BookshelfCubit._(const CommonListState<BookData>());
    cubit._init();
    return cubit;
  }

  BookshelfCubit._(super.initialState);

  final String _sortOrderKey = PreferenceKeys.bookshelf.sortOrder;
  final String _isAscendingKey = PreferenceKeys.bookshelf.isAscending;
  late final SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  @override
  Future<void> refresh() async {
    if (!_isInitialized ||
        state.code.isLoading ||
        state.code.isBackgroundLoading) {
      return;
    }

    emit(state.copyWith(code: LoadingStateCode.loading));

    int sortOrder;
    try {
      sortOrder = _prefs.getInt(_sortOrderKey) ?? SortOrderCode.name.index;
    } catch (_) {
      sortOrder = SortOrderCode.name.index;
    }

    final SortOrderCode sortOrderCode = SortOrderCode.values[sortOrder];
    final bool isAscending = _prefs.getBool(_isAscendingKey) ?? true;

    final Directory folder = Directory(FilePath.libraryRoot);
    final Iterable<File> fileList = folder
        .listSync()
        .whereType<File>()
        .where((File e) => MimeResolver.lookupAll(e) == 'application/epub+zip');

    if (fileList.isEmpty) {
      emit(CommonListState<BookData>(
        code: LoadingStateCode.loaded,
        sortOrder: sortOrderCode,
        isAscending: isAscending,
      ));
    } else {
      final List<BookData> list = <BookData>[];
      final List<BookData> oldList = List<BookData>.from(state.dataList);

      // Only read the books that are not read yet.
      for (File epubFile in fileList) {
        final BookData target = oldList.firstWhereOrNull(
                (BookData e) => e.absoluteFilePath == epubFile.path) ??
            await BookRepository.get(epubFile.path);

        list.add(target);
        list.sort(BookUtils.sortCompare(sortOrderCode, isAscending));

        if (!isClosed) {
          emit(CommonListState<BookData>(
            code: LoadingStateCode.backgroundLoading,
            sortOrder: sortOrderCode,
            dataList: List<BookData>.from(list), // Make a copy.
            isAscending: isAscending,
          ));
        }
      }

      if (!isClosed) {
        emit(state.copyWith(code: LoadingStateCode.loaded));
      }
    }
  }

  void setListOrder({SortOrderCode? sortOrder, bool? isAscending}) {
    final SortOrderCode order = sortOrder ?? state.sortOrder;
    final bool ascending = isAscending ?? state.isAscending;

    _prefs.setInt(_sortOrderKey, order.index);
    _prefs.setBool(_isAscendingKey, ascending);

    state.dataList.sort(BookUtils.sortCompare(order, ascending));
    emit(state.copyWith(
      isAscending: ascending,
      sortOrder: order,
    ));
  }

  bool deleteSelectedBooks() {
    final List<BookData> newList = List<BookData>.from(state.dataList);
    for (BookData bookData in state.selectedSet) {
      BookRepository.delete(bookData.absoluteFilePath);
      newList.remove(bookData);
    }
    emit(state.copyWith(dataList: newList));
    return true;
  }

  bool deleteBook(BookData bookData) {
    final bool isSuccess = BookRepository.delete(bookData.absoluteFilePath);

    final List<BookData> newList = List<BookData>.from(state.dataList);
    newList.remove(bookData);
    emit(state.copyWith(dataList: newList));
    return isSuccess;
  }
}
