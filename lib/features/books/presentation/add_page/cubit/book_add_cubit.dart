import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../pick_file/domain/use_cases/pick_file_clear_temp_use_case.dart';
import '../../../domain/entities/book_pick_file_data.dart';
import '../../../domain/use_cases/book_add_use_case.dart';
import '../../../domain/use_cases/book_get_allowed_extensions_use_case.dart';
import '../../../domain/use_cases/book_pick_use_case.dart';
import 'book_add_state.dart';

/// Cubit to manage the state of adding a book_service.
class BookAddCubit extends Cubit<BookAddState> {
  BookAddCubit(
    this._addBooksUseCase,
    this._getBookAllowedExtensionsUseCase,
    this._pickBooksUseCase,
    this._pickFileClearTempUseCase,
  ) : super(const BookAddState());

  final BookAddUseCase _addBooksUseCase;
  final BookGetAllowedExtensionsUseCase _getBookAllowedExtensionsUseCase;
  final BookPickUseCase _pickBooksUseCase;
  final PickFileClearTempUseCase _pickFileClearTempUseCase;

  List<String> get allowedExtensions => _getBookAllowedExtensionsUseCase();

  /// Allows the user to pick a file.
  Future<void> pickFile() async {
    final Set<String> selectedFileName =
        state.fileSet.map((BookPickFileData s) => s.baseName).toSet();

    // Pick file
    final Set<BookPickFileData> pickedFileSet = await _pickBooksUseCase();

    // Intersection
    final Set<BookPickFileData> fileSet =
        Set<BookPickFileData>.from(state.fileSet);
    for (BookPickFileData fileData in pickedFileSet) {
      if (!selectedFileName.contains(fileData.baseName)) {
        fileSet.add(fileData);
      }
    }

    if (!isClosed) {
      emit(BookAddState(fileSet: fileSet));
    }
  }

  Future<void> removeFile(BookPickFileData itemState) async {
    final Set<BookPickFileData> fileSet =
        Set<BookPickFileData>.from(state.fileSet);

    // Remove from list.
    fileSet.remove(itemState);

    // Update state.
    emit(BookAddState(fileSet: fileSet));
  }

  Future<void> submit() async {
    await _addBooksUseCase(state.fileSet
        .map((BookPickFileData itemState) => itemState.absolutePath)
        .toSet());
  }

  @override
  Future<void> close() async {
    // Clear temporary files.
    await _pickFileClearTempUseCase();
    return super.close();
  }
}
