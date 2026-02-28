import 'package:collection/collection.dart';

import '../../../../../enum/loading_state_code.dart';
import '../../../../../enum/sort_order_code.dart';
import '../../../../preference/domain/entities/bookmark_list_preference_data.dart';
import '../../../../preference/domain/use_cases/preference_get_use_cases.dart';
import '../../../../preference/domain/use_cases/preference_observe_change_use_case.dart';
import '../../../../preference/domain/use_cases/preference_save_use_case.dart';
import '../../../../shared_components/shared_list/shared_list.dart';
import '../../../domain/entities/bookmark_item.dart';
import '../../../domain/use_cases/bookmark_delete_use_case.dart';
import '../../../domain/use_cases/bookmark_get_list_use_case.dart';
import '../../../domain/use_cases/bookmark_observe_change_use_case.dart';

typedef BookmarkListState = SharedListState<BookmarkItem>;

class BookmarkListCubit extends SharedListCubit<BookmarkItem> {
  factory BookmarkListCubit(
    BookmarkGetListUseCase getListUseCase,
    BookmarkDeleteUseCase deleteUseCase,
    BookmarkObserveChangeUseCase observeChangeUseCase,
    BookmarkListGetPreferenceUseCase getPreferenceUseCase,
    BookmarkListSavePreferenceUseCase savePreferenceUseCase,
    BookmarkListObserveChangeUseCase observePreferenceUseCase,
  ) {
    final BookmarkListCubit cubit = BookmarkListCubit._(
      getListUseCase,
      deleteUseCase,
      getPreferenceUseCase,
      savePreferenceUseCase,
    );

    // Refresh at first
    cubit.refresh();

    // Listen to bookmarks changes.
    cubit.onRepositoryChangedSubscription =
        observeChangeUseCase().listen((_) => cubit.refresh());

    // Listen to bookmark list preference changes.
    cubit.onPreferenceChangedSubscription =
        observePreferenceUseCase().listen((_) => cubit.refreshPreference());

    return cubit;
  }

  BookmarkListCubit._(
    this._getListUseCase,
    this._deleteUseCase,
    this._getPreferenceUseCase,
    this._savePreferenceUseCase,
  ) : super(const SharedListState<BookmarkItem>());

  /// Bookmark use cases
  final BookmarkGetListUseCase _getListUseCase;
  final BookmarkDeleteUseCase _deleteUseCase;

  /// Bookmark list preference use cases
  final BookmarkListGetPreferenceUseCase _getPreferenceUseCase;
  final BookmarkListSavePreferenceUseCase _savePreferenceUseCase;

  @override
  Future<void> refresh() async {
    if (state.code.isLoading || state.code.isBackgroundLoading) {
      return;
    }

    // Load preferences.
    final BookmarkListPreferenceData preference = await _getPreferenceUseCase();

    // Load bookmark list.
    emit(BookmarkListState(
      code: LoadingStateCode.loaded,
      dataList: sortList(
        await _getListUseCase(),
        preference.sortOrder,
        preference.isAscending,
      ),
      sortOrder: preference.sortOrder,
      isAscending: preference.isAscending,
      listType: preference.listType,
    ));
  }

  Future<void> deleteBookmark(BookmarkItem data) {
    return _deleteUseCase(<String>[data.id]);
  }

  void deleteSelectedBookmarks() {
    _deleteUseCase(
        state.selectedSet.map((BookmarkItem data) => data.id).toList());
  }

  @override
  int sortCompare(
    BookmarkItem a,
    BookmarkItem b, {
    required SortOrderCode sortOrder,
    required bool isAscending,
  }) {
    switch (sortOrder) {
      case SortOrderCode.name:
        return isAscending
            ? compareNatural(a.bookTitle, b.bookTitle)
            : compareNatural(b.bookTitle, a.bookTitle);

      default:
        return isAscending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt);
    }
  }

  @override
  void savePreference() {
    _savePreferenceUseCase(BookmarkListPreferenceData(
      sortOrder: state.sortOrder,
      isAscending: state.isAscending,
      listType: state.listType,
    ));
  }

  @override
  Future<void> refreshPreference() async {
    final BookmarkListPreferenceData preference = await _getPreferenceUseCase();
    emit(state.copyWith(
      sortOrder: preference.sortOrder,
      isAscending: preference.isAscending,
      listType: preference.listType,
    ));
  }
}
