// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/common/common.dart';
import 'package:learn/courses/course.dart';
import 'package:learn/home.dart';
import 'package:learn/jobs/jobs.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // -'Find Jobs With'--------------------------------------------------------------------------
  // ThemeController
  // ---------------------------------------------------------------------------
  group('ThemeController', () {
    test('starts in system mode after loadTheme', () async {
      final theme = ThemeController();
      await theme.loadTheme();
      expect(theme.themeMode, ThemeMode.system);
      expect(theme.isSystemMode, isTrue);
    });

    test('toggleLightDark switches between light and dark', () async {
      final theme = ThemeController();
      await theme.loadTheme();

      theme.setLightMode();
      expect(theme.isLightMode, isTrue);

      theme.toggleLightDark();
      expect(theme.isDarkMode, isTrue);

      theme.toggleLightDark();
      expect(theme.isLightMode, isTrue);
    });

    test('useSystemMode restores system', () {
      final theme = ThemeController();
      theme.setDarkMode();
      theme.useSystemMode();
      expect(theme.isSystemMode, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // DiagramController – shapes, lines, groups, export
  // ---------------------------------------------------------------------------
  group('DiagramController', () {
    late DiagramController controller;

    setUp(() {
      controller = DiagramController();
    });

    test('addShape creates a shape and selects it', () {
      controller.addShape(const Offset(100, 100));
      expect(controller.shapes, hasLength(1));
      expect(controller.selectedShapeId, isNotNull);
      expect(controller.hasSelection, isTrue);
    });

    test('addContainer creates a group', () {
      controller.addContainer(const Offset(50, 50));
      expect(controller.groups, hasLength(1));
      expect(controller.selectedGroupId, isNotNull);
    });

    test('connectShapes creates a line between two shapes', () async {
      controller.addShape(const Offset(0, 0));
      final a = controller.shapes.first.id;

      // Shape IDs are generated from DateTime.microsecondsSinceEpoch.
      // Give the next creation a separate timestamp in the test.
      await Future<void>.delayed(const Duration(milliseconds: 2));

      controller.addShape(const Offset(200, 0));
      final b = controller.shapes.last.id;

      expect(a, isNot(b));

      controller.connectShapes(a, b);
      expect(controller.lines, hasLength(1));
      expect(controller.lines.first.sourceShapeId, a);
      expect(controller.lines.first.targetShapeId, b);
    });

    test('connectShapes does not create self-loop or duplicate', () async {
      controller.addShape(const Offset(0, 0));
      final id = controller.shapes.first.id;
      controller.connectShapes(id, id);
      expect(controller.lines, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 2));

      controller.addShape(const Offset(100, 0));
      final other = controller.shapes.last.id;
      expect(id, isNot(other));
      controller.connectShapes(id, other);
      controller.connectShapes(id, other);
      expect(controller.lines, hasLength(1));
    });

    test('container can connect to shape', () {
      controller.addContainer(const Offset(50, 50));
      final groupId = controller.groups.first.id;

      controller.addShape(const Offset(600, 100));
      final shapeId = controller.shapes.first.id;

      controller.connectNodes(groupId, shapeId);

      expect(controller.lines, hasLength(1));
      expect(controller.lines.first.sourceShapeId, groupId);
      expect(controller.lines.first.targetShapeId, shapeId);
    });

    test('container can connect to another container', () async {
      controller.addContainer(const Offset(50, 50));
      final firstId = controller.groups.first.id;

      await Future<void>.delayed(const Duration(milliseconds: 2));

      controller.addContainer(const Offset(700, 50));
      final secondId = controller.groups.last.id;

      expect(firstId, isNot(secondId));

      controller.connectNodes(firstId, secondId);

      expect(controller.lines, hasLength(1));
      expect(controller.lines.first.sourceShapeId, firstId);
      expect(controller.lines.first.targetShapeId, secondId);
    });

    test('container child lists remain mutable', () {
      controller.addContainer(const Offset(100, 100));
      final group = controller.groups.first;

      controller.addShape(const Offset(150, 150));
      final shape = controller.shapes.first;

      expect(() => controller.finishShapeMove(shape.id), returnsNormally);

      expect(group.childShapeIds, contains(shape.id));
    });

    test('container colors can be updated', () {
      controller.addContainer(const Offset(100, 100));
      final group = controller.groups.first;

      controller.updateGroupBorderColor(group.id, const Color(0xFF3B82F6));

      controller.updateGroupBackgroundColor(group.id, const Color(0xFFDBEAFE));

      expect(group.borderColor, const Color(0xFF3B82F6));

      expect(group.backgroundColor, const Color(0xFFDBEAFE));
    });

    test('shape colors can be updated independently', () {
      controller.addShape(const Offset(100, 100));
      final shape = controller.shapes.first;

      controller.updateShapeBorderColor(shape.id, const Color(0xFFEF4444));

      controller.updateShapeBackgroundColor(shape.id, const Color(0xFFFEE2E2));

      expect(shape.borderColor, const Color(0xFFEF4444));

      expect(shape.backgroundColor, const Color(0xFFFEE2E2));
    });

    test('line color can be updated independently', () async {
  controller.addShape(const Offset(0, 0));
  final first = controller.shapes.first;

  // Give the next shape a different timestamp-based ID
  await Future<void>.delayed(const Duration(milliseconds: 2));

  controller.addShape(const Offset(300, 0));
  final second = controller.shapes.last;

  expect(first.id, isNot(second.id));

  controller.connectShapes(first.id, second.id);

  expect(controller.lines, hasLength(1));

  final line = controller.lines.first;

  controller.updateLineColor(line.id, const Color(0xFF008080));

  expect(line.color, const Color(0xFF008080));
});
    test('moving container moves contained shapes', () {
      controller.addContainer(const Offset(100, 100));
      final group = controller.groups.first;

      controller.addShape(const Offset(150, 150));
      final shape = controller.shapes.first;

      controller.finishShapeMove(shape.id);

      final oldShapePosition = shape.position;

      controller.moveGroup(group.id, const Offset(200, 200));

      expect(shape.position, oldShapePosition + const Offset(100, 100));
    });

    test('moveShape updates position', () {
      controller.addShape(const Offset(10, 20));
      final id = controller.shapes.first.id;
      controller.moveShape(id, const Offset(80, 90));
      expect(controller.shapes.first.position, const Offset(80, 90));
    });

    test('selectShape then deleteSelected removes selected shape', () {
      controller.addShape(const Offset(100, 100));

      final id = controller.shapes.first.id;

      controller.selectShape(id);
      controller.deleteSelected();

      expect(controller.shapes, isEmpty);
      expect(controller.hasSelection, isFalse);
    });

    test('selectLine then deleteSelected removes selected line', () async {
      controller.addShape(const Offset(0, 0));
      final firstId = controller.shapes.first.id;

      await Future<void>.delayed(const Duration(milliseconds: 2));

      controller.addShape(const Offset(300, 0));
      final secondId = controller.shapes.last.id;

      controller.connectShapes(firstId, secondId);

      expect(controller.lines, hasLength(1));

      final lineId = controller.lines.first.id;

      controller.selectLine(lineId);
      controller.deleteSelected();

      expect(controller.lines, isEmpty);

      // Deleting a connection must not delete its endpoint shapes.
      expect(controller.shapes, hasLength(2));
    });

    test('shape becomes child of container after move finishes', () {
      controller.addContainer(const Offset(100, 100));
      final group = controller.groups.first;

      controller.addShape(const Offset(150, 150));
      final shape = controller.shapes.first;

      controller.finishShapeMove(shape.id);

      expect(shape.parentContainerId, group.id);
      expect(group.childShapeIds, contains(shape.id));
    });

    test('moveGroup updates position', () {
      controller.addContainer(const Offset(10, 10));
      final id = controller.groups.first.id;
      controller.moveGroup(id, const Offset(40, 50));
      expect(controller.groups.first.position, const Offset(40, 50));
    });

    test('resizeShape respects minimum size', () {
      controller.addShape(const Offset(0, 0));
      final id = controller.shapes.first.id;
      controller.resizeShape(id, const Size(10, 10));
      expect(controller.shapes.first.width, 45);
      expect(controller.shapes.first.height, 45);
    });

    test('resizeGroup respects minimum size', () {
      controller.addContainer(const Offset(0, 0));
      final id = controller.groups.first.id;
      controller.resizeGroup(id, const Size(20, 20));
      expect(controller.groups.first.size.width, 160);
      expect(controller.groups.first.size.height, 100);
    });

    test('updateShapeText and updateLineName', () async {
      controller.addShape(const Offset(0, 0));
      final shapeId = controller.shapes.first.id;
      controller.updateShapeText(shapeId, 'API Gateway');
      expect(controller.shapes.first.text, 'API Gateway');

      await Future<void>.delayed(const Duration(milliseconds: 2));

      controller.addShape(const Offset(100, 0));
      final other = controller.shapes.last.id;
      expect(shapeId, isNot(other));
      controller.connectShapes(shapeId, other);
      final lineId = controller.lines.first.id;
      controller.updateLineName(lineId, 'HTTP');
      expect(controller.lines.first.name, 'HTTP');
    });

    test('deleteSelected removes shape and connected lines', () async {
      controller.addShape(const Offset(0, 0));
      final a = controller.shapes.first.id;

      await Future<void>.delayed(const Duration(milliseconds: 2));

      controller.addShape(const Offset(100, 0));
      final b = controller.shapes.last.id;
      expect(a, isNot(b));
      controller.connectShapes(a, b);
      expect(controller.lines, hasLength(1));

      controller.selectShape(a);
      controller.deleteSelected();
      expect(controller.shapes.any((s) => s.id == a), isFalse);
      expect(controller.lines, isEmpty);
    });

    test('clearCanvas empties everything', () {
      controller.addShape(const Offset(0, 0));
      controller.addContainer(const Offset(0, 0));
      controller.clearCanvas();
      expect(controller.shapes, isEmpty);
      expect(controller.lines, isEmpty);
      expect(controller.groups, isEmpty);
      expect(controller.hasSelection, isFalse);
    });

    test('exportJson / importJson round-trip', () async {
      controller.addShape(const Offset(12, 34));
      controller.shapes.first.text = 'RoundTrip';

      await Future<void>.delayed(const Duration(milliseconds: 2));

      controller.addShape(const Offset(100, 100));
      expect(controller.shapes.first.id, isNot(controller.shapes.last.id));

      controller.connectShapes(
        controller.shapes.first.id,
        controller.shapes.last.id,
      );

      final json = controller.exportJson();
      expect(json['shapes'], isA<List>());
      expect(json['lines'], isA<List>());

      final other = DiagramController();
      other.importJson(json);
      expect(other.shapes, hasLength(2));
      expect(other.lines, hasLength(1));
      expect(other.shapes.first.text, 'RoundTrip');
    });

    test('loadDemo populates demo architecture', () {
      controller.loadDemo();
      expect(controller.shapes.length, greaterThanOrEqualTo(4));
      expect(controller.lines.length, greaterThanOrEqualTo(3));
    });

    test('hitTestLine finds nearby line', () async {
      controller.addShape(const Offset(0, 0), type: ShapeType.rectangle);
      final a = controller.shapes.first;
      // Force known size/position for predictable midpoint
      a.position = const Offset(0, 0);
      a.width = 100;
      a.height = 100;

      await Future<void>.delayed(const Duration(milliseconds: 2));

      controller.addShape(const Offset(300, 0), type: ShapeType.rectangle);
      final b = controller.shapes.last;
      expect(a.id, isNot(b.id));
      b.position = const Offset(300, 0);
      b.width = 100;
      b.height = 100;

      controller.connectShapes(a.id, b.id);
      final mid = Offset(
        (a.position.dx + a.width / 2 + b.position.dx + b.width / 2) / 2,
        (a.position.dy + a.height / 2 + b.position.dy + b.height / 2) / 2,
      );

      final hit = controller.hitTestLine(mid, threshold: 30);
      expect(hit, isNotNull);
      expect(hit, controller.lines.first.id);

      final miss = controller.hitTestLine(const Offset(9999, 9999));
      expect(miss, isNull);
    });

    test('undo and redo restore diagram snapshots', () {
      controller.addShape(const Offset(0, 0));
      expect(controller.shapes, hasLength(1));

      controller.clearCanvas();
      expect(controller.shapes, isEmpty);

      controller.undo();

      expect(controller.shapes, hasLength(1));
      expect(controller.canRedo, isTrue);

      controller.redo();

      expect(controller.shapes, isEmpty);
      expect(controller.canUndo, isTrue);
    });

    test('duplicateSelected duplicates selected shape', () {
      controller.addShape(const Offset(100, 100), type: ShapeType.rectangle);

      final original = controller.shapes.first;

      controller.duplicateSelected();

      expect(controller.shapes, hasLength(2));

      final duplicate = controller.shapes.last;

      expect(duplicate.id, isNot(original.id));
      expect(duplicate.type, original.type);
      expect(duplicate.width, original.width);
      expect(duplicate.height, original.height);
      expect(duplicate.position, original.position + const Offset(30, 30));
      expect(duplicate.text, '${original.text} Copy');
    });

    test('play / pause / resetAnimation', () {
      controller.play();
      expect(controller.isPlaying, isTrue);
      controller.pause();
      expect(controller.isPlaying, isFalse);
      controller.togglePlayPause();
      expect(controller.isPlaying, isTrue);
      controller.resetAnimation();
      expect(controller.animationProgress, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // CourseController
  // ---------------------------------------------------------------------------
  group('CourseController', () {
    test('has courses and categories', () {
      final c = CourseController();
      expect(c.courses, isNotEmpty);
      expect(c.categories, isNotEmpty);
    });

    test('byCategory filters', () {
      final c = CourseController();
      final web = c.byCategory('Web Development');
      expect(web, isNotEmpty);
      expect(web.every((x) => x.category == 'Web Development'), isTrue);
    });

    test('courses contain learning, project and game urls', () {
      final controller = CourseController();

      for (final course in controller.courses) {
        expect(
          course.learnUrl,
          isNotEmpty,
          reason: '${course.name} must have a learn URL',
        );

        expect(
          course.projectUrl,
          isNotEmpty,
          reason: '${course.name} must have a project URL',
        );

        expect(
          course.gameUrl,
          isNotEmpty,
          reason: '${course.name} must have a game URL',
        );
      }
    });

    test('project urls use projects/home.html', () {
      final controller = CourseController();

      for (final course in controller.courses) {
        expect(
          course.projectUrl.endsWith('/projects/home.html'),
          isTrue,
          reason: '${course.name} has an invalid project URL',
        );
      }
    });

    test('game urls use games/home.html', () {
      final controller = CourseController();

      for (final course in controller.courses) {
        expect(
          course.gameUrl.endsWith('/games/home.html'),
          isTrue,
          reason: '${course.name} has an invalid game URL',
        );
      }
    });

    test('findById returns matching course', () {
      final c = CourseController();
      final flutter = c.findById('flutter');
      expect(flutter, isNotNull);
      expect(flutter!.name, 'Flutter');
      expect(c.findById('does-not-exist'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // DiagramStorage (SharedPreferences mock)
  // ---------------------------------------------------------------------------
  group('DiagramStorage', () {
    test('save, load, delete, folders', () async {
      final storage = DiagramStorage();
      final project = await storage.save(
        name: 'Test Arch',
        folder: 'demos',
        data: {
          'shapes': <dynamic>[],
          'lines': <dynamic>[],
          'groups': <dynamic>[],
        },
      );

      expect(project.name, 'Test Arch');
      expect(project.folder, 'demos');

      final all = await storage.loadAll();
      expect(all, hasLength(1));
      expect(all.first.id, project.id);

      final folders = await storage.listFolders();
      expect(folders, contains('demos'));

      final byFolder = await storage.byFolder();
      expect(byFolder['demos'], hasLength(1));

      await storage.delete(project.id);
      expect(await storage.loadAll(), isEmpty);
    });

    test('empty name becomes Untitled, empty folder becomes General', () async {
      final storage = DiagramStorage();
      final project = await storage.save(
        name: '   ',
        folder: '',
        data: {'shapes': [], 'lines': [], 'groups': []},
      );
      expect(project.name, 'Untitled');
      expect(project.folder, 'General');
    });
  });

  // ---------------------------------------------------------------------------
  // Widget tests
  // ---------------------------------------------------------------------------
  group('LearningTechApp widgets', () {
    testWidgets('WelcomeScreen shows branding and loading state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => DiagramController()),
            ChangeNotifierProvider(create: (_) => CourseController()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const WelcomeScreen(),
          ),
        ),
      );

      expect(find.text('Learning Tech'), findsOneWidget);
      expect(find.textContaining('Communicate'), findsOneWidget);
      expect(find.text('loading...'), findsOneWidget);

      // Advance past the 5s auto-navigation timer without hanging
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('HomeScreen shows Start Work and Guide Video', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => DiagramController()),
            ChangeNotifierProvider(create: (_) => CourseController()),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
        ),
      );

      expect(find.text('Start Work'), findsOneWidget);
      expect(find.text('Guide Video'), findsOneWidget);
      expect(find.text('View Saved Work'), findsOneWidget);
    });

    testWidgets('MainNavigationScreen shows bottom destinations', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => DiagramController()),
            ChangeNotifierProvider(create: (_) => CourseController()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MainNavigationScreen(),
          ),
        ),
      );

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Courses'), findsWidgets);
      expect(find.text('Games'), findsWidgets);
      expect(find.text('Jobs'), findsWidgets);
    });

    testWidgets('HomeScreen shows Save FAB and toolbar actions', (
      tester,
    ) async {
      final diagram = DiagramController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider<DiagramController>.value(value: diagram),
            ChangeNotifierProvider(create: (_) => CourseController()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const WorkspaceScreen(),
          ),
        ),
      );

      // Let DiagramCanvas post-frame loadDemo run
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Save'), findsOneWidget);
      expect(find.byTooltip('Help'), findsOneWidget);
      expect(find.text('Untitled Project'), findsOneWidget);
    });

    testWidgets('CoursesScreen lists courses and filters by category', (
      tester,
    ) async {
      final courseController = CourseController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => DiagramController()),
            ChangeNotifierProvider<CourseController>.value(
              value: courseController,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CoursesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the Courses screen is displayed.
      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Learn Technology'), findsOneWidget);

      // Verify at least one course visible on the initial screen.
      expect(find.text('HTML5'), findsWidgets);

      // Verify Flutter exists in the course data.
      expect(
        courseController.courses.any((course) => course.name == 'Flutter'),
        isTrue,
      );

      // Verify Cloud filtering through the controller.
      final cloudCourses = courseController.byCategory('Cloud');

      expect(cloudCourses, isNotEmpty);
      expect(
        cloudCourses.every((course) => course.category == 'Cloud'),
        isTrue,
      );
    });

    testWidgets('Course cards show Learn and Practice Project actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => DiagramController()),
            ChangeNotifierProvider(create: (_) => CourseController()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CoursesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Learn'), findsWidgets);

      expect(find.text('Projects'), findsWidgets);
    });

    testWidgets('JobsScreen defaults to Contact Us tab', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => DiagramController()),
            ChangeNotifierProvider(create: (_) => CourseController()),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const JobsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Jobs'), findsOneWidget);

      expect(find.text('Contact Us'), findsOneWidget);

      expect(find.text('Find Jobs'), findsOneWidget);

      expect(find.text('WhatsApp'), findsOneWidget);

      expect(find.text('Email'), findsOneWidget);

      expect(find.text('TikTok'), findsOneWidget);

      expect(find.text('LinkedIn'), findsOneWidget);

      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('navigating bottom bar switches pages', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => DiagramController()),
            ChangeNotifierProvider(create: (_) => CourseController()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MainNavigationScreen(),
          ),
        ),
      );

      await tester.pump();

      // Courses tab
      await tester.tap(find.text('Courses').last);
      await tester.pumpAndSettle();
      expect(find.text('Learn Technology'), findsOneWidget);

      // Jobs tab
      await tester.tap(find.text('Jobs').last);
      await tester.pumpAndSettle();
      expect(find.text('Contact Us'), findsOneWidget);
      expect(find.text('Find Jobs'), findsOneWidget);

      // Home tab
      // Home tab
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(find.text('Start Work'), findsOneWidget);
      expect(find.text('Guide Video'), findsOneWidget);
    });
  });

  group('JobSearchRequest', () {
    test('serializes job search data', () {
      const request = JobSearchRequest(
        skills: 'Flutter, AWS',
        currentLocation: 'Nigeria',
        targetLocation: 'United Kingdom',
        experienceLevel: 'Entry Level',
        includeRemoteJobs: true,
      );

      final json = request.toJson();

      expect(json['skills'], 'Flutter, AWS');

      expect(json['currentLocation'], 'Nigeria');

      expect(json['targetLocation'], 'United Kingdom');

      expect(json['experienceLevel'], 'Entry Level');

      expect(json['includeRemoteJobs'], isTrue);
    });
  });

  group('EarnDee contact message', () {
    test('builds service request correctly', () {
      final message = buildEarnDeeContactMessage(
        name: 'Test Business',
        service: 'Cloud',
        description: 'I need help deploying my application.',
      );

      expect(message, contains('Hello, EarnDee.'));

      expect(message, contains('I will need your Cloud services.'));

      expect(message, contains('Test Business'));

      expect(message, contains('I need help deploying my application.'));
    });
  });

  // ---------------------------------------------------------------------------
  // Shape / line model serialization
  // ---------------------------------------------------------------------------
  group('Model JSON', () {
    test('DiagramShape toJson / fromJson', () {
      final shape = DiagramShape(
        id: 's1',
        type: ShapeType.hexagon,
        position: const Offset(1.5, 2.5),
        width: 100,
        height: 80,
        text: 'Service',
        borderColor: const Color(0xFF111827),
        backgroundColor: Colors.white,
        borderWidth: 2,
        zIndex: 3,
      );
      final restored = DiagramShape.fromJson(shape.toJson());
      expect(restored.id, 's1');
      expect(restored.type, ShapeType.hexagon);
      expect(restored.position.dx, 1.5);
      expect(restored.text, 'Service');
      expect(restored.zIndex, 3);
    });

    test('DiagramLine toJson / fromJson', () {
      final line = DiagramLine(
        id: 'l1',
        sourceShapeId: 'a',
        targetShapeId: 'b',
        type: LineType.double,
        name: 'Sync',
        color: const Color(0xFF111827),
        width: 3,
        animationProgress: 0.4,
      );
      final restored = DiagramLine.fromJson(line.toJson());
      expect(restored.id, 'l1');
      expect(restored.type, LineType.double);
      expect(restored.name, 'Sync');
      expect(restored.animationProgress, closeTo(0.4, 0.001));
    });

    test('DiagramGroup toJson / fromJson', () {
      final group = DiagramGroup(
        id: 'g1',
        type: ShapeType.rectangle,
        position: const Offset(5, 6),
        size: const Size(200, 150),
        name: 'VPC',
        childShapeIds: const ['s1'],
        childLineIds: const [],
      );
      final restored = DiagramGroup.fromJson(group.toJson());
      expect(restored.id, 'g1');
      expect(restored.name, 'VPC');
      expect(restored.size.width, 200);
      expect(restored.childShapeIds, ['s1']);
    });
  });
}
