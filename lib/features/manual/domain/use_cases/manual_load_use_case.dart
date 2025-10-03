import 'package:equatable/equatable.dart';

import '../../../../core/domain/use_cases/use_case.dart';
import '../../../../core/log_system/log_system.dart';
import '../../../locale_system/domain/entities/app_locale.dart';
import '../entities/shared_manual_path_enum.dart';
import '../repositories/manual_repository.dart';

class ManualLoadUseCaseParam extends Equatable {
  const ManualLoadUseCaseParam({
    required this.filePath,
    required this.appLocale,
  });

  final SharedManualPathEnum filePath;
  final AppLocale appLocale;

  @override
  List<Object?> get props => <Object?>[
        filePath,
        appLocale,
      ];
}

class ManualLoadUseCase
    extends UseCase<Future<String?>, ManualLoadUseCaseParam> {
  ManualLoadUseCase(this._repository);

  final ManualRepository _repository;

  @override
  Future<String?> call(ManualLoadUseCaseParam parameter) async {
    try {
      return await _repository.loadManual(
          parameter.filePath, parameter.appLocale);
    } catch (e, s) {
      LogSystem.error(
        'Failed to load manual. ($parameter)',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }
}
