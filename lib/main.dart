import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:learn/common/reward_ads.dart';
import 'package:learn/courses/course.dart';
import 'package:learn/firebase_options.dart';
import 'package:learn/home.dart';
import 'package:provider/provider.dart';

bool get isDesktop {
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

Future<void> main() async {
  if (!isDesktop) {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider() // for production
          : const AndroidDebugProvider(), // for debugging
      providerWeb: ReCaptchaEnterpriseProvider(
        "6LfvicQtAAAAACIFcpNop-nim5arhg223jlp6oEb",
      ),
    );

    if (!kIsWeb) {
      await AdsService.instance.initialize();
    }
  }

  final themeController = ThemeController();

  await themeController.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),

        ChangeNotifierProvider<DiagramController>(
          create: (_) => DiagramController(),
        ),

        ChangeNotifierProvider<CourseController>(
          create: (_) => CourseController(),
        ),
      ],
      child: const LearningTechApp(),
    ),
  );
}

// flutter clean
// flutter pub get
// flutter analyze
// flutter test
// flutter build web
// flutter build apk --release
// flutter build appbundle --release
// clear
//.
