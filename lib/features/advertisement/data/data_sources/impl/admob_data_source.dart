import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../domain/entities/ad_data.dart';
import '../../../domain/entities/ad_unit_id.dart';
import '../ad_data_source.dart';

class AdMobDataSource implements AdDataSource {
  bool _isInit = false;

  Future<void> _ensuredInitialized() async {
    if (!_isInit) {
      await MobileAds.instance.initialize();
      _isInit = true;
    }
  }

  @override
  Future<AdData> loadBannerAd(AdUnitId unitId, int width) async {
    await _ensuredInitialized();
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    final Completer<AdData> completer = Completer<AdData>();

    final BannerAd bannerAd = BannerAd(
      adUnitId: unitId.id!,
      request: const AdRequest(),
      size: size ?? AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          completer.complete(AdData(
            adMobBannerAd: ad as BannerAd,
          ));
        },
        onAdFailedToLoad: (Ad ad, LoadAdError err) {
          ad.dispose();
        },
      ),
    );

    bannerAd.load();

    return completer.future;
  }
}
