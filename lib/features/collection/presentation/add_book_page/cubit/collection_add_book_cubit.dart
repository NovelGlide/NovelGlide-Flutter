import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../enum/loading_state_code.dart';
import '../../../../books/domain/entities/book.dart';
import '../../../domain/entities/collection_data.dart';
import '../../../domain/use_cases/collection_get_list_use_case.dart';
import '../../../domain/use_cases/collection_observe_change_use_case.dart';
import '../../../domain/use_cases/collection_update_data_use_case.dart';
import 'collection_add_book_state.dart';

class CollectionAddBookCubit extends Cubit<CollectionAddBookState> {
  CollectionAddBookCubit(
    this._getCollectionListUseCase,
    this._observeCollectionChangeUseCase,
    this._updateCollectionDataUseCase,
  ) : super(const CollectionAddBookState());

  late final Set<Book> _dataSet;
  late final StreamSubscription<void> _onChangedSubscription;

  final CollectionGetListUseCase _getCollectionListUseCase;
  final CollectionObserveChangeUseCase _observeCollectionChangeUseCase;
  final CollectionUpdateDataUseCase _updateCollectionDataUseCase;

  /// Get data from widget.
  Future<void> init(Set<Book> dataSet) async {
    _dataSet = dataSet;

    // Refresh at first.
    refresh();

    // Listen to collection changes.
    _onChangedSubscription =
        _observeCollectionChangeUseCase().listen((_) => refresh());
  }

  Future<void> refresh() async {
    if (state.code.isLoading || state.code.isBackgroundLoading) {
      return;
    }

    // Get the collection list from repository.
    final List<CollectionData> collectionList =
        await _getCollectionListUseCase();

    // Get all the book IDs from user selected books.
    // In the new system, book.identifier IS the BookId (UUID).
    final Set<String> selectedBookIds =
        _dataSet.map((Book e) => e.identifier).toSet();

    // Get the selected collection set by
    // intersection of selected bookIds and collection's bookIds.
    final Set<CollectionData> selectedCollections = collectionList
        .where((CollectionData e) =>
            e.bookIds.toSet().intersection(selectedBookIds).isNotEmpty)
        .toSet();

    // Sort the collection list by name.
    collectionList.sort(
        (CollectionData a, CollectionData b) => compareNatural(a.name, b.name));

    emit(CollectionAddBookState(
      code: LoadingStateCode.loaded,
      collectionList: collectionList,
      selectedCollections: selectedCollections,
      bookRelativePathSet: selectedBookIds,
    ));
  }

  Future<void> select(CollectionData data) async {
    // Add selected book IDs to the collection using immutable copyWith
    final List<String> updatedBookIds = List<String>.from(data.bookIds);
    for (String bookId in state.bookRelativePathSet) {
      if (!updatedBookIds.contains(bookId)) {
        updatedBookIds.add(bookId);
      }
    }
    final CollectionData updatedData =
        data.copyWith(bookIds: updatedBookIds);

    // Update the collection in the list
    final List<CollectionData> updatedList =
        List<CollectionData>.from(state.collectionList);
    final int index = updatedList.indexWhere((CollectionData e) => e.id == data.id);
    if (index != -1) {
      updatedList[index] = updatedData;
    }

    emit(state.copyWith(
      collectionList: updatedList,
      selectedCollections: <CollectionData>{
        ...state.selectedCollections,
        updatedData
      },
    ));
  }

  void deselect(CollectionData data) {
    // Remove selected book IDs from the collection using immutable copyWith
    final List<String> updatedBookIds = data.bookIds
        .where((String bookId) =>
            !state.bookRelativePathSet.contains(bookId))
        .toList();
    final CollectionData updatedData =
        data.copyWith(bookIds: updatedBookIds);

    // Update the collection in the list
    final List<CollectionData> updatedList =
        List<CollectionData>.from(state.collectionList);
    final int index = updatedList.indexWhere((CollectionData e) => e.id == data.id);
    if (index != -1) {
      updatedList[index] = updatedData;
    }

    emit(state.copyWith(
      collectionList: updatedList,
      selectedCollections: <CollectionData>{...state.selectedCollections}
        ..remove(data),
    ));
  }

  Future<void> save() {
    return _updateCollectionDataUseCase(state.collectionList.toSet());
  }

  @override
  Future<void> close() {
    _onChangedSubscription.cancel();
    return super.close();
  }
}
