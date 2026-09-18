import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:learn/courses/course.dart';
import 'package:learn/firebase_options.dart';
import 'package:learn/home.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    // for production
    providerAndroid: const AndroidPlayIntegrityProvider(),

    // for debugging
    // providerAndroid: const AndroidDebugProvider(),
  );

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
