import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWrapper extends StatefulWidget {
  const AdBannerWrapper({super.key, required this.isAdRemoved});

  /// Whether the user's purchase removes advertising.
  final bool isAdRemoved;

  @override
  State<AdBannerWrapper> createState() => _AdBannerWrapperState();
}

class _AdBannerWrapperState extends State<AdBannerWrapper> {
  // Replace this ID with the production Android banner unit ID before release.
  static const _productionAdUnitId = 'ca-app-pub-5267160093414926/4367203490';
  static const _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isAdRemoved) {
      _loadAd();
    }
  }

  @override
  void didUpdateWidget(covariant AdBannerWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAdRemoved) {
      _disposeBanner();
    } else if (oldWidget.isAdRemoved && _bannerAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (widget.isAdRemoved || _bannerAd != null) {
      return;
    }

    late final BannerAd bannerAd;
    bannerAd = BannerAd(
      adUnitId: kReleaseMode ? _productionAdUnitId : _testAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted && identical(_bannerAd, ad)) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (identical(_bannerAd, ad)) {
            _bannerAd = null;
            if (mounted) {
              setState(() {
                _isLoaded = false;
              });
            }
          }
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    );
    _bannerAd = bannerAd;
    bannerAd.load();
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAdRemoved || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
