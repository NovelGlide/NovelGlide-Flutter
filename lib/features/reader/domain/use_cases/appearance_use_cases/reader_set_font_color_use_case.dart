import 'package:flutter/material.dart';

import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_core_repository.dart';

class ReaderSetFontColorUseCase extends UseCase<void, Color> {
  ReaderSetFontColorUseCase(this._repository);

  final ReaderCoreRepository _repository;

  @override
  void call(Color color) {
    _repository.fontColor = color;
  }
}
