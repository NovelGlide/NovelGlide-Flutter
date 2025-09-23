import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ad_data.dart';
import '../../domain/entities/ad_unit_id.dart';
import '../../domain/use_cases/ad_check_enabled_use_case.dart';
import '../../domain/use_cases/ad_load_banner_ad_use_case.dart';
import 'advertisement_state.dart';

class AdvertisementCubit extends Cubit<AdvertisementState> {
  factory AdvertisementCubit(AdLoadBannerAdUseCase loadBannerAdUseCase,
      AdCheckEnabledUseCase checkEnabledUseCase) {
    final AdvertisementCubit instance = AdvertisementCubit._(
      loadBannerAdUseCase,
      checkEnabledUseCase,
      AdvertisementState(
        isEnabled: checkEnabledUseCase(),
      ),
    );
    return instance;
  }

  AdvertisementCubit._(
    this._loadBannerAdUseCase,
    this._checkEnabledUseCase,
    super.initialState,
  );

  final AdLoadBannerAdUseCase _loadBannerAdUseCase;
  final AdCheckEnabledUseCase _checkEnabledUseCase;

  Future<void> loadAd(AdUnitId unitId, int width) async {
    if (!_checkEnabledUseCase() || unitId.id == null) {
      // Ad is not enabled.
      emit(state.copyWith(
        isEnabled: false,
      ));
      return;
    }

    final AdData data = await _loadBannerAdUseCase(AdLoadBannerAdUseCaseParam(
      unitId: unitId,
      width: width,
    ));

    emit(state.copyWith(
      adMobBannerAd: data.adMobBannerAd,
      isEnabled: true,
    ));
  }

  @override
  Future<void> close() async {
    state.adMobBannerAd?.dispose();
    super.close();
  }
}
