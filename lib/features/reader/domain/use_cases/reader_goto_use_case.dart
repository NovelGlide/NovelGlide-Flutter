import '../../../../core/domain/use_cases/use_case.dart';
import '../../../../core/log_system/log_system.dart';
import '../exceptions/reader_page_not_in_book_exception.dart';
import '../repositories/reader_core_repository.dart';

class ReaderGotoUseCaseParam {
  const ReaderGotoUseCaseParam({
    this.chapterIdentifier,
    this.cfi,
  });

  final String? chapterIdentifier;
  final String? cfi;
}

class ReaderGotoUseCaseResult {
  const ReaderGotoUseCaseResult({
    required this.isSuccessful,
    this.failureCode,
  });

  final bool isSuccessful;
  final ReaderGotoUseCaseFailureCode? failureCode;
}

enum ReaderGotoUseCaseFailureCode {
  unknown,
  pageNotInBook,
}

class ReaderGotoUseCase
    extends UseCase<Future<ReaderGotoUseCaseResult>, ReaderGotoUseCaseParam> {
  ReaderGotoUseCase(this._repository);

  final ReaderCoreRepository _repository;

  @override
  Future<ReaderGotoUseCaseResult> call(ReaderGotoUseCaseParam parameter) async {
    try {
      await _repository.goto(
        pageIdentifier: parameter.chapterIdentifier,
        cfi: parameter.cfi,
      );
    } on ReaderPageNotInBookException {
      return const ReaderGotoUseCaseResult(
        isSuccessful: false,
        failureCode: ReaderGotoUseCaseFailureCode.pageNotInBook,
      );
    } catch (e, s) {
      LogSystem.error(
        'ReaderGotoUseCase: An unexpected error occurred',
        error: e,
        stackTrace: s,
      );
      return const ReaderGotoUseCaseResult(
        isSuccessful: false,
        failureCode: ReaderGotoUseCaseFailureCode.unknown,
      );
    }

    return const ReaderGotoUseCaseResult(isSuccessful: true);
  }
}
