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
      // 'ca-app-pub-7018091756479171/1374187926'; //Real
      'ca-app-pub-3940256099942544/6300978111'; // test
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
    // this.adSlot = '1234567890', // Test
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

// class _SmartAd {
//   final String imagePath;
//   final Widget targetWidget;
//   _SmartAd({required this.imagePath, required this.targetWidget});
// }

// class BannerAdWidget extends StatefulWidget {
//   const BannerAdWidget({super.key});

//   @override
//   State<BannerAdWidget> createState() => _BannerAdWidgetState();
// }

// class _BannerAdWidgetState extends State<BannerAdWidget> {
//   BannerAd? _bannerAd;
//   bool _isBannerLoaded = false;
//   late _SmartAd _selectedInternalAd;
//   Timer? _refreshTimer;

//   // --- INTERNAL AD INVENTORY ---
//   final List<_SmartAd> _myInternalAds = [
//     _SmartAd(
//       imagePath: "assets/ads/image.png",
//       targetWidget: const WebViewScreen(
//         title: "EarnDee Info Board",
//         url: "https://sites.google.com/view/earndeelimited/home/fans",
//       ),
//     ),
//     _SmartAd(
//       imagePath: "assets/ads/image0.png",
//       targetWidget: const WebViewScreen(
//         title: "EarnDee Info Board",
//         url: "https://sites.google.com/view/earndeelimited/home/chandelier",
//       ),
//     ),
//     _SmartAd(
//       imagePath: "assets/ads/image1.png",
//       targetWidget: const WebViewScreen(
//         title: "EarnDee Info Board",
//         url: "https://sites.google.com/view/earndeelimited/home/chandelier",
//       ),
//     ),
//     _SmartAd(
//       imagePath: "assets/ads/image2.png",
//       targetWidget: const WebViewScreen(
//         title: "EarnDee Info Board",
//         url: "https://sites.google.com/view/earndeelimited/home/solar-budgets",
//       ),
//     ),
//     _SmartAd(
//       imagePath: "assets/ads/image3.png",
//       targetWidget: const WebViewScreen(
//         title: "EarnDee Info Board",
//         url: "https://sites.google.com/view/earndeelimited/home/chandelier",
//       ),
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _pickRandomInternalAd();
//     _startRefreshTimer();
//     // Don't call _initBannerAd() here anymore!
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_bannerAd == null) {
//       _initBannerAd(); // now async, but fire-and-forget is fine here
//     }
//   }

//   void _startRefreshTimer() {
//     _refreshTimer?.cancel();
//     _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
//       if (!_isBannerLoaded) {
//         setState(() {
//           _pickRandomInternalAd();
//         });
//         _initBannerAd();
//       } else {
//         timer.cancel();
//       }
//     });
//   }

//   void _pickRandomInternalAd() {
//     _selectedInternalAd =
//         _myInternalAds[Random().nextInt(_myInternalAds.length)];
//   }

//   void _initBannerAd() async {
//     _bannerAd?.dispose();
//     _bannerAd = null;

//     // Get screen width safely (use sizeOf for efficiency, no subscription)
//     final double screenWidth = MediaQuery.sizeOf(context).width;
//     final int adWidth = screenWidth
//         .truncate(); // or .toInt() — truncate() is preferred for dp

//     // No context here — only width
//     final AnchoredAdaptiveBannerAdSize? adaptiveSize =
//         // ignore: deprecated_member_use
//         await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(adWidth);

//     if (adaptiveSize == null || !mounted) {
//       debugPrint('Could not get adaptive size');
//       setState(() => _isBannerLoaded = false);
//       return;
//     }

//     _bannerAd = BannerAd(
//       size: adaptiveSize,
//       adUnitId: 'ca-app-pub-3940256099942544/6300978111', //Test ID
//       // adUnitId: 'ca-app-pub-7018091756479171/1374187926', // Real ID
//       request: const AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (ad) {
//           if (mounted) {
//             setState(() => _isBannerLoaded = true);
//             _refreshTimer?.cancel();
//           }
//         },
//         onAdFailedToLoad: (ad, error) {
//           ad.dispose();
//           if (mounted) setState(() => _isBannerLoaded = false);
//           debugPrint('Banner failed: $error');
//         },
//       ),
//     )..load();
//   }

//   @override
//   void dispose() {
//     _refreshTimer?.cancel();
//     _bannerAd?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.grey[200],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 800),
//         child: _buildAdContent(),
//       ),
//     );
//   }

//   Widget _buildAdContent() {
//     if (_isBannerLoaded && _bannerAd != null) {
//       return SizedBox(
//         key: const ValueKey('banner_ad'),
//         width: _bannerAd!.size.width.toDouble(),
//         height: _bannerAd!.size.height.toDouble(),
//         child: AdWidget(ad: _bannerAd!),
//       );
//     }

//     return GestureDetector(
//       key: ValueKey(_selectedInternalAd.imagePath),
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => _selectedInternalAd.targetWidget,
//           ),
//         );
//       },
//       child: SizedBox(
//         height: 100,
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Stack(
//             fit: StackFit.expand,
//             children: [
//               Image.asset(_selectedInternalAd.imagePath, fit: BoxFit.cover),
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: const Text(
//                     "Announcement",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
