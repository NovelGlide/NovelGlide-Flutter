import '../../../../core/domain/use_cases/use_case.dart';
import '../repositories/bookmark_repository.dart';

class BookmarkDeleteDataUseCase extends UseCase<Future<void>, Set<String>> {
  BookmarkDeleteDataUseCase(this._repository);

  final BookmarkRepository _repository;

  @override
  Future<void> call(Set<String> parameter) {
    return _repository.deleteData(parameter);
  }
}
