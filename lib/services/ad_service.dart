import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  Future<void> initialize({required String appId}) async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    // App ID is usually set in Info.plist/AndroidManifest via the SDK;
    // here we just ensure the SDK is initialized.
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  BannerAd createBanner({
    required String unitId,
    required AdSize size,
    void Function(Ad)? onLoaded,
    void Function(Ad, LoadAdError)? onFailed,
  }) {
    if (kIsWeb) {
      return null as dynamic;
    }
    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
    );
    ad.load();
    return ad;
  }

  // Helper to use test IDs on emulators/simulators.
  static String bannerTestUnit() {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }
}
