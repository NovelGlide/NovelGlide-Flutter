import 'dart:async';

import '../../../../../enum/loading_state_code.dart';
import '../../../../../enum/sort_order_code.dart';
import '../../../../../features/shared_components/shared_list/shared_list.dart';
import '../../../../book_storage/data/repositories/local_book_storage.dart';
import '../../../../book_storage/domain/entities/book_metadata.dart';
import '../../../../book_storage/domain/repositories/book_storage.dart';
import '../../../../books/domain/entities/book.dart';
import '../../../domain/entities/collection_data.dart';
import '../../../domain/use_cases/collection_get_data_use_case.dart';
import '../../../domain/use_cases/collection_update_data_use_case.dart';

typedef CollectionViewerState = SharedListState<Book>;

class CollectionViewerCubit extends SharedListCubit<Book> {
  CollectionViewerCubit(
    this._localBookStorage,
    this._getCollectionDataByIdUseCase,
    this._updateCollectionDataUseCase,
  ) : super(const CollectionViewerState());

  late CollectionData collectionData;
  StreamSubscription<Book>? _listStreamSubscription;

  /// Dependencies
  final LocalBookStorage _localBookStorage;
  final CollectionGetDataUseCase _getCollectionDataByIdUseCase;
  final CollectionUpdateDataUseCase _updateCollectionDataUseCase;

  /// Get the data from UI.
  void init(CollectionData data) {
    collectionData = data;

    refresh();
  }

  /// Refresh the state of viewer by loading books from collection's bookIds.
  @override
  Future<void> refresh() async {
    // Update collection data
    collectionData = await _getCollectionDataByIdUseCase(collectionData.id);

    // Get the book IDs list
    final List<String> bookIds = collectionData.bookIds;

    if (bookIds.isEmpty) {
      // No books in collection
      emit(const CollectionViewerState(
        code: LoadingStateCode.loaded,
        dataList: <Book>[],
      ));
    } else {
      // Load books by BookId using LocalBookStorage
      final List<Book> bookList = <Book>[];

      emit(const CollectionViewerState(
        code: LoadingStateCode.loading,
        dataList: <Book>[],
      ));

      _listStreamSubscription?.cancel();
      _listStreamSubscription = _loadBooksByIdStream(bookIds).listen(
        (Book book) {
          // A new book data is received
          if (!isClosed) {
            bookList.add(book);
            emit(CollectionViewerState(
              code: LoadingStateCode.backgroundLoading,
              dataList: List<Book>.from(bookList),
            ));
          }
        },
        onDone: () {
          // All book data is received
          if (!isClosed) {
            emit(CollectionViewerState(
              code: LoadingStateCode.loaded,
              dataList: List<Book>.from(bookList),
            ));
          }
        },
        onError: (Object error) {
          // Error loading books
          if (!isClosed) {
            emit(CollectionViewerState(
              code: LoadingStateCode.error,
              dataList: List<Book>.from(bookList),
            ));
          }
        },
      );
    }
  }

  /// Load books from LocalBookStorage by BookIds as a stream.
  ///
  /// For each bookId:
  /// 1. Read BookMetadata from LocalBookStorage
  /// 2. Gracefully handle missing books (deleted books)
  /// 3. Yield Book objects for successful reads
  ///
  /// The stream completes when all books have been processed.
  Stream<Book> _loadBooksByIdStream(List<String> bookIds) async* {
    for (String bookId in bookIds) {
      try {
        // Try to read metadata for this bookId
        final BookMetadata? metadata = await _localBookStorage
            .readMetadata(bookId)
            .catchError((_) => null);

        // If metadata exists, yield a Book object
        if (metadata != null) {
          yield Book(
            identifier: bookId,
            title: metadata.title,
            modifiedDate: metadata.dateAdded,
            coverIdentifier: bookId,
            ltr: true, // Default LTR; can be extended with metadata
          );
        }
        // If metadata is null (book deleted), skip it gracefully
      } on BookStorageException {
        // Log but don't fail - continue loading other books
        // Gracefully handle missing books due to deletion
      }
    }
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) {
      return;
    }

    final Book target = state.dataList.removeAt(oldIndex);
    state.dataList
        .insert(oldIndex < newIndex ? newIndex - 1 : newIndex, target);
    emit(state.copyWith(
      code: LoadingStateCode.loaded,
      dataList: List<Book>.from(state.dataList),
    ));

    // Save the new order to the book IDs list
    final List<String> newBookIds = <String>[];
    for (Book book in state.dataList) {
      newBookIds.add(book.identifier);
    }
    collectionData = collectionData.copyWith(bookIds: newBookIds);

    // Save collection data
    _updateCollectionDataUseCase(<CollectionData>{collectionData});
  }

  Future<void> removeBooks() async {
    // Get the set of book IDs to remove
    final Set<String> bookIdsToRemove =
        state.selectedSet.map((Book book) => book.identifier).toSet();

    // Remove books from dataList
    final List<Book> bookList = List<Book>.from(state.dataList);
    bookList.removeWhere((Book e) => bookIdsToRemove.contains(e.identifier));

    // Update collection data with remaining book IDs
    final List<String> remainingBookIds = <String>[];
    for (Book book in bookList) {
      remainingBookIds.add(book.identifier);
    }
    collectionData = collectionData.copyWith(bookIds: remainingBookIds);

    emit(state.copyWith(
      code: LoadingStateCode.loaded,
      selectedSet: const <Book>{},
      dataList: bookList,
    ));

    // Save the collection data
    _updateCollectionDataUseCase(<CollectionData>{collectionData});
  }

  @override
  int sortCompare(
    Book a,
    Book b, {
    required SortOrderCode sortOrder,
    required bool isAscending,
  }) {
    // Custom order. Don't sort
    return 0;
  }

  @override
  void savePreference() {
    // No preferences for collection viewer
  }

  @override
  Future<void> refreshPreference() async {
    // No preferences for collection viewer
  }

  @override
  Future<void> close() {
    _listStreamSubscription?.cancel();
    return super.close();
  }
}
