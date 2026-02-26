import 'dart:async';

import '../../../reader/domain/entities/reader_page_num_type.dart';
import '../../domain/entities/preference_keys.dart';
import '../../domain/entities/reader_preference_data.dart';
import '../../domain/repositories/preference_repository.dart';
import '../data_sources/preference_local_data_source.dart';

class ReaderPreferenceRepositoryImpl implements ReaderPreferenceRepository {
  ReaderPreferenceRepositoryImpl(
    this._localDataSource,
  );

  final PreferenceLocalDataSource _localDataSource;
  final StreamController<ReaderPreferenceData> _onChangedController =
      StreamController<ReaderPreferenceData>.broadcast();

  @override
  Future<ReaderPreferenceData> getPreference() async {
    final int? pageNumIndex =
        await _localDataSource.tryGetInt(PreferenceKeys.readerPageNumType);
    final int? coreTypeIndex =
        await _localDataSource.tryGetInt(PreferenceKeys.readerCoreType);

    return const ReaderPreferenceData().copyWith(
      fontSize:
          await _localDataSource.tryGetDouble(PreferenceKeys.readerFontSize),
      lineHeight:
          await _localDataSource.tryGetDouble(PreferenceKeys.readerLineHeight),
      isAutoSaving:
          await _localDataSource.tryGetBool(PreferenceKeys.readerAutoSaving),
      isSmoothScroll:
          await _localDataSource.tryGetBool(PreferenceKeys.readerSmoothScroll),
      pageNumType:
          pageNumIndex == null ? null : ReaderPageNumType.values[pageNumIndex],
      // TODO(kai): Uncomment in future.
      // coreType:
      //     coreTypeIndex == null ? null : ReaderCoreType.values[coreTypeIndex],
    );
  }

  @override
  Future<void> savePreference(ReaderPreferenceData data) async {
    await _localDataSource.setDouble(
        PreferenceKeys.readerFontSize, data.fontSize);
    await _localDataSource.setDouble(
        PreferenceKeys.readerLineHeight, data.lineHeight);
    await _localDataSource.setBool(
        PreferenceKeys.readerAutoSaving, data.isAutoSaving);
    await _localDataSource.setBool(
        PreferenceKeys.readerSmoothScroll, data.isSmoothScroll);
    await _localDataSource.setInt(
        PreferenceKeys.readerPageNumType, data.pageNumType.index);
    await _localDataSource.setInt(
        PreferenceKeys.readerCoreType, data.coreType.index);

    _onChangedController.add(data);
  }

  @override
  Stream<ReaderPreferenceData> get onChangeStream =>
      _onChangedController.stream;

  @override
  Future<void> resetPreference() async {
    final ReaderPreferenceData oldData = await getPreference();
    await _localDataSource.remove(PreferenceKeys.readerFontSize);
    await _localDataSource.remove(PreferenceKeys.readerLineHeight);
    await _localDataSource.remove(PreferenceKeys.readerAutoSaving);
    await _localDataSource.remove(PreferenceKeys.readerSmoothScroll);
    await _localDataSource.remove(PreferenceKeys.readerPageNumType);

    // Do not reset the core type.
    // await _localDataSource.remove(PreferenceKeys.readerCoreType);

    _onChangedController.add(const ReaderPreferenceData().copyWith(
      coreType: oldData.coreType,
    ));
  }
}
