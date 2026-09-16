import 'package:flutter/material.dart';
import 'package:learn/courses/course.dart';
import 'package:learn/home.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
