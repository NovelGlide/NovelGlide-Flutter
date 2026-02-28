import '../../../../core/domain/use_cases/use_case.dart';
import '../entities/collection_data.dart';
import '../repositories/collection_repository.dart';

class CollectionDeleteAllBooksUseCase extends UseCase<Future<void>, void> {
  const CollectionDeleteAllBooksUseCase(this._repository);

  final CollectionRepository _repository;

  @override
  Future<void> call([void parameter]) async {
    // Get the data list
    final List<CollectionData> list = await _repository.getList();

    // Remove all the books from all collections using immutable copyWith
    final Set<CollectionData> updatedSet = <CollectionData>{};
    for (CollectionData data in list) {
      updatedSet.add(data.copyWith(bookIds: const <String>[]));
    }

    await _repository.updateData(updatedSet);
  }
}
