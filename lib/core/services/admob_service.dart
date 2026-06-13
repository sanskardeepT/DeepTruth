import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/api_keys.dart';
import '../constants/app_constants.dart';

class AdMobService {
  AdMobService._();
  static final AdMobService instance = AdMobService._();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  int _checkCount = 0;
  DateTime? _lastInterstitialShown;

  // ── BANNER ────────────────────────────────────────────────────────
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: ApiKeys.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed: ${error.message}');
        },
      ),
    )..load();
  }

  // ── INTERSTITIAL ──────────────────────────────────────────────────
  void preloadInterstitial() {
    if (!ApiKeys.isAdMobConfigured) return;
    InterstitialAd.load(
      adUnitId: ApiKeys.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: ${error.message}');
          Future<void>.delayed(
            const Duration(seconds: 30),
            preloadInterstitial,
          );
        },
      ),
    );
  }

  /// Call after every fact-check. Frequency-capped.
  void onCheckCompleted() {
    _checkCount++;
    if (_checkCount % AppConstants.interstitialEvery != 0) return;

    final now = DateTime.now();
    if (_lastInterstitialShown != null) {
      final diffMin =
          now.difference(_lastInterstitialShown!).inMinutes;
      if (diffMin < AppConstants.interstitialCooldownMinutes) return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _lastInterstitialShown = now;
    }
  }

  // ── REWARDED ──────────────────────────────────────────────────────
  void preloadRewardedAd() {
    if (!ApiKeys.isAdMobConfigured) return;
    RewardedAd.load(
      adUnitId: ApiKeys.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed: ${error.message}');
          Future<void>.delayed(
            const Duration(seconds: 30),
            preloadRewardedAd,
          );
        },
      ),
    );
  }

  /// Returns true if user earned the reward.
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) return false;

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    return completer.future;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
