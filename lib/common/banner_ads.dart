
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:learn/home.dart';

class _SmartAd {
  final String imagePath;
  final Widget targetWidget;
  _SmartAd({required this.imagePath, required this.targetWidget});
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  late _SmartAd _selectedInternalAd;
  Timer? _refreshTimer;

  // --- INTERNAL AD INVENTORY ---
  final List<_SmartAd> _myInternalAds = [
    _SmartAd(
      imagePath: "assets/ads/image.png",
      targetWidget: const WebViewScreen(
        title: "EarnDee Info Board",
        url: "https://sites.google.com/view/earndeelimited/home/fans",
      ),
    ),
    _SmartAd(
      imagePath: "assets/ads/image0.png",
      targetWidget: const WebViewScreen(
        title: "EarnDee Info Board",
        url: "https://sites.google.com/view/earndeelimited/home/chandelier",
      ),
    ),
    _SmartAd(
      imagePath: "assets/ads/image1.png",
      targetWidget: const WebViewScreen(
        title: "EarnDee Info Board",
        url: "https://sites.google.com/view/earndeelimited/home/chandelier",
      ),
    ),
    _SmartAd(
      imagePath: "assets/ads/image2.png",
      targetWidget: const WebViewScreen(
        title: "EarnDee Info Board",
        url: "https://sites.google.com/view/earndeelimited/home/solar-budgets",
      ),
    ),
    _SmartAd(
      imagePath: "assets/ads/image3.png",
      targetWidget: const WebViewScreen(
        title: "EarnDee Info Board",
        url: "https://sites.google.com/view/earndeelimited/home/chandelier",
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pickRandomInternalAd();
    _startRefreshTimer();
    // Don't call _initBannerAd() here anymore!
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _initBannerAd(); // now async, but fire-and-forget is fine here
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isBannerLoaded) {
        setState(() {
          _pickRandomInternalAd();
        });
        _initBannerAd();
      } else {
        timer.cancel();
      }
    });
  }

  void _pickRandomInternalAd() {
    _selectedInternalAd =
        _myInternalAds[Random().nextInt(_myInternalAds.length)];
  }

  void _initBannerAd() async {
    _bannerAd?.dispose();
    _bannerAd = null;

    // Get screen width safely (use sizeOf for efficiency, no subscription)
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final int adWidth = screenWidth
        .truncate(); // or .toInt() — truncate() is preferred for dp

    // No context here — only width
    final AnchoredAdaptiveBannerAdSize? adaptiveSize =
        // ignore: deprecated_member_use
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(adWidth);

    if (adaptiveSize == null || !mounted) {
      debugPrint('Could not get adaptive size');
      setState(() => _isBannerLoaded = false);
      return;
    }

    _bannerAd = BannerAd(
      size: adaptiveSize,
      // adUnitId: 'ca-app-pub-3940256099942544/6300978111', //Test ID
      adUnitId: 'ca-app-pub-7018091756479171/1374187926', // Real ID
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isBannerLoaded = true);
            _refreshTimer?.cancel();
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _isBannerLoaded = false);
          debugPrint('Banner failed: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: _buildAdContent(),
      ),
    );
  }

  Widget _buildAdContent() {
    if (_isBannerLoaded && _bannerAd != null) {
      return SizedBox(
        key: const ValueKey('banner_ad'),
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return GestureDetector(
      key: ValueKey(_selectedInternalAd.imagePath),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _selectedInternalAd.targetWidget,
          ),
        );
      },
      child: SizedBox(
        height: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_selectedInternalAd.imagePath, fit: BoxFit.cover),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Announcement",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
