// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Central place for “Remove Ads” preference + rewarded ads.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static const _adsRemovedKey = 'learning_tech_ads_removed';

  // ── Test IDs (replace with your real AdMob unit IDs for production) ──
  static const String _androidRewardedUnitId =
  //  'ca-app-pub-7018091756479171/8581813853'; // Real ID
      'ca-app-pub-3940256099942544/5224354917'; // Google test rewarded
  static const String _iosRewardedUnitId =
      'ca-app-pub-3940256099942544/1712485313'; // Google test rewarded

  String get _rewardedUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosRewardedUnitId;
    }
    return _androidRewardedUnitId;
  }

  bool _initialized = false;
  RewardedAd? _rewardedAd;
  bool _isLoadingAd = false;

  // ---------------------------------------------------------------------------
  // Init (call once from main)
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    // Pre-load first ad
    unawaited(loadRewardedAd());
  }

  // ---------------------------------------------------------------------------
  // Remove-Ads preference
  // ---------------------------------------------------------------------------
  Future<bool> get isAdsRemoved async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adsRemovedKey) ?? false;
  }

  /// Call this after a successful “Remove Ads” IAP purchase.
  Future<void> setAdsRemoved(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adsRemovedKey, value);
  }

  // ---------------------------------------------------------------------------
  // Rewarded ad load / show
  // ---------------------------------------------------------------------------
  Future<void> loadRewardedAd() async {
    if (_isLoadingAd || _rewardedAd != null) return;
    _isLoadingAd = true;

    await RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingAd = false;
          debugPrint('RewardedAd loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoadingAd = false;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  /// Shows a rewarded ad if ads are still enabled.
  /// Returns `true` when the user earned the reward (or ads are removed).
  /// Returns `false` if the ad failed / was dismissed without reward.
Future<bool> showRewardedAdIfNeeded() async {
  if (kIsWeb) {
    // Web has no rewarded ads → block the action
    return false;
  }

  if (await isAdsRemoved) {
    return true;
  }

    // Ensure we have an ad
    if (_rewardedAd == null) {
      await loadRewardedAd();
      // Give it a short moment; if still null we fail gracefully
      await Future.delayed(const Duration(milliseconds: 800));
      if (_rewardedAd == null) {
        debugPrint('No rewarded ad available');
        return false;
      }
    }

    final completer = Completer<bool>();
    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        // Pre-load next
        unawaited(loadRewardedAd());
        if (!completer.isCompleted) {
          completer.complete(rewarded);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        unawaited(loadRewardedAd());
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );

    return completer.future;
  }
}


//   String _getAdUnitId() {
//     if (Platform.isAndroid) {
//       return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
//       // return 'ca-app-pub-7018091756479171/8581813853'; // Real ID
//     } else if (Platform.isIOS) {
//       return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
//     } else {
//       throw UnsupportedError('Unsupported platform');
//     }
//   }
