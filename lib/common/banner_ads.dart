import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

// ─────────────────────────────────────────────────────────────
// 1. Mobile AdMob Banner
// ─────────────────────────────────────────────────────────────
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // Replace with your real AdMob banner unit ID
  static const String _androidUnitId =
      'ca-app-pub-7018091756479171/1374187926'; //Real
      // 'ca-app-pub-3940256099942544/6300978111'; // test
  static const String _iosUnitId =
      'ca-app-pub-3940256099942544/2934735716'; // test

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return; // never load AdMob on web

    final unitId = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosUnitId
        : _androidUnitId;

    _bannerAd = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. Web AdSense Banner (simple display unit)
// ─────────────────────────────────────────────────────────────
class AdSenseBanner extends StatelessWidget {
  final String adSlot;
  final double width;
  final double height;

  const AdSenseBanner({
    super.key,
    this.adSlot = "5765666212", //Real
    this.width = 320,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    // Lightweight placeholder that still reserves space.
    // Replace the child with a real HtmlElementView / package
    // once your AdSense account is approved.
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Text(
        'AdSense $adSlot',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. Unified platform-aware banner (use this everywhere)
// ─────────────────────────────────────────────────────────────
class PlatformBannerAd extends StatelessWidget {
  final double? width;
  final double? height;

  const PlatformBannerAd({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return AdSenseBanner(
        width: width ?? 320,
        height: height ?? 100,
      );
    }
    return const BannerAdWidget();
  }
}

// ─────────────────────────────────────────────────────────────
// 4. Responsive ad shell
//    • large (≥ 900 px) → left + right side bars
//    • small            → top (or bottom) banner
// ─────────────────────────────────────────────────────────────
class ResponsiveAdShell extends StatelessWidget {
  final Widget child;
  final bool showTopOnSmall;
  final bool showBottomOnSmall;

  const ResponsiveAdShell({
    super.key,
    required this.child,
    this.showTopOnSmall = true,
    this.showBottomOnSmall = false,
  });

  static const double _wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;

        if (isWide) {
          // LEFT + RIGHT side ads
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left ad rail
              SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 8),
                  child: PlatformBannerAd(width: 160, height: 600),
                ),
              ),
              // Main content
              Expanded(child: child),
              // Right ad rail
              SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 8),
                  child: PlatformBannerAd(width: 160, height: 600),
                ),
              ),
            ],
          );
        }

        // Small screen → top and/or bottom
        return Column(
          children: [
            if (showTopOnSmall)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: PlatformBannerAd()),
              ),
            Expanded(child: child),
            if (showBottomOnSmall)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: PlatformBannerAd()),
              ),
          ],
        );
      },
    );
  }
}
