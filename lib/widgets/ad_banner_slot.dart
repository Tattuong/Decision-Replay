import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../core/constants/ad_constants.dart';
import '../core/services/ad_service.dart';
import '../providers/shop_provider.dart';

class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key});

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _banner;
  AdSize? _size;
  bool _loaded = false;
  bool _failed = false;
  bool _loading = false;

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  bool _ownsRemoveAds({required bool watch}) {
    try {
      final shop = watch ? context.watch<ShopProvider>() : context.read<ShopProvider>();
      return shop.hasRemoveAds;
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    if (_banner != null || _failed || !AdConstants.isConfigured) return;
    if (!AdService.isSupported) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    await AdService.init();
    if (!mounted || _ownsRemoveAds(watch: false)) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width) ??
        AdSize.banner;
    if (!mounted || _ownsRemoveAds(watch: false)) return;

    final ad = BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted || _ownsRemoveAds(watch: false)) {
            loaded.dispose();
            return;
          }
          setState(() {
            _banner = loaded as BannerAd;
            _size = size;
            _loaded = true;
            _loading = false;
          });
        },
        onAdFailedToLoad: (failed, error) {
          debugPrint('AdMob banner failed: $error');
          failed.dispose();
          if (!mounted) return;
          setState(() {
            _banner = null;
            _failed = true;
            _loaded = false;
            _loading = false;
          });
        },
      ),
    );
    await ad.load();
  }

  void _dropAd() {
    _banner?.dispose();
    _banner = null;
    _loaded = false;
    _loading = false;
    _failed = false;
    _size = null;
  }

  @override
  Widget build(BuildContext context) {
    final hide = _ownsRemoveAds(watch: true) || !AdConstants.isConfigured;
    if (hide) {
      if (_banner != null || _loading || _failed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _dropAd();
          setState(() {});
        });
      }
      return const SizedBox.shrink();
    }

    if (!_loading && _banner == null && !_failed) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_load());
      });
    }

    if (_failed) return const SizedBox.shrink();

    final height = _size?.height.toDouble() ?? AdConstants.bannerHeight;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1),
          SizedBox(
            width: double.infinity,
            height: height,
            child: _loaded && _banner != null
                ? AdWidget(ad: _banner!)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
