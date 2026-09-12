import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

bool get supportsEmbeddedWebView {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

Future<void> openCourseUrl(
  BuildContext context, {
  required String title,
  required String url,
}) async {
  if (supportsEmbeddedWebView) {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(title: title, url: url),
      ),
    );
    return;
  }

  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}

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

class LearningTechApp extends StatelessWidget {
  const LearningTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learning Tech',

      theme: AppTheme.light,

      darkTheme: AppTheme.darkTheme,

      themeMode: themeController.themeMode,

      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _timer = Timer(const Duration(seconds: 5), _openApplication);
  }

  void _openApplication() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final scale = 1 + (_animationController.value * 0.06);

                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0C75C),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF0C75C)
                                .withValues(alpha: 0.25),
                            blurRadius: 35,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_tree_rounded,
                        size: 56,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Learning Tech',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Communicate/ Animate your thought easily',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFF0C75C),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'loading...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ShapeType { square, rectangle, triangle, hexagon, pentagon, circle }

class DiagramShape {
  final String id;

  ShapeType type;

  Offset position;

  double width;

  double height;

  String text;

  Color borderColor;

  Color backgroundColor;

  double borderWidth;

  String? parentContainerId;

  int zIndex;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'position': {'dx': position.dx, 'dy': position.dy},
    'width': width,
    'height': height,
    'text': text,
    'borderColor': borderColor.toARGB32(),
    'backgroundColor': backgroundColor.toARGB32(),
    'borderWidth': borderWidth,
    'parentContainerId': parentContainerId,
    'zIndex': zIndex,
  };

  DiagramShape({
    required this.id,
    required this.type,
    required this.position,
    required this.width,
    required this.height,
    required this.text,
    required this.borderColor,
    required this.backgroundColor,
    required this.borderWidth,
    this.parentContainerId,
    required this.zIndex,
  });

  static DiagramShape fromJson(Map<String, dynamic> json) {
    return DiagramShape(
      id: json['id'] as String,
      type: ShapeType.values.byName(json['type'] as String),
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      text: json['text'] as String,
      borderColor: Color(json['borderColor'] as int),
      backgroundColor: Color(json['backgroundColor'] as int),
      borderWidth: (json['borderWidth'] as num).toDouble(),
      parentContainerId: json['parentContainerId'] as String?,
      zIndex: json['zIndex'] as int,
    );
  }
}

class ShapeWidget extends StatefulWidget {
  final DiagramShape shape;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<Size> onResize;
  final ValueChanged<Offset> onMove;
  final VoidCallback onMoveEnd;

  const ShapeWidget({
    super.key,
    required this.shape,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onResize,
    required this.onMove,
    required this.onMoveEnd,
  });

  @override
  State<ShapeWidget> createState() => _ShapeWidgetState();
}

class _ShapeWidgetState extends State<ShapeWidget> {
  Offset? _shapeStartPosition;
  Offset _totalDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final shape = widget.shape;
    final selected = widget.selected;

    return Positioned(
      left: shape.position.dx,
      top: shape.position.dy,
      width: shape.width,
      height: shape.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onPanStart: (_) {
          _shapeStartPosition = shape.position;
          _totalDelta = Offset.zero;
          if (!selected) {
            widget.onTap();
          }
        },
        onPanUpdate: (details) {
          if (_shapeStartPosition == null) return;
          _totalDelta += details.delta;
          widget.onMove(_shapeStartPosition! + _totalDelta);
        },
        onPanEnd: (_) {
          _shapeStartPosition = null;
          _totalDelta = Offset.zero;
          widget.onMoveEnd();
        },
        onPanCancel: () {
          _shapeStartPosition = null;
          _totalDelta = Offset.zero;
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ShapePainter(
                  type: shape.type,
                  backgroundColor: shape.backgroundColor,
                  borderColor: selected
                      ? const Color(0xFFF0C75C)
                      : shape.borderColor,
                  borderWidth: selected
                      ? shape.borderWidth + 2
                      : shape.borderWidth,
                  selected: selected,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        shape.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (selected)
              Positioned(
                right: -7,
                bottom: -7,
                child: _ResizeHandle(
                  onDrag: widget.onResize,
                  currentSize: Size(shape.width, shape.height),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatefulWidget {
  final ValueChanged<Size> onDrag;
  final Size currentSize;

  const _ResizeHandle({required this.onDrag, required this.currentSize});

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  late Size _startSize;
  Offset _totalDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {
        _startSize = widget.currentSize;
        _totalDelta = Offset.zero;
      },
      onPanUpdate: (details) {
        _totalDelta += details.delta;
        final newSize = Size(
          math.max(45, _startSize.width + _totalDelta.dx),
          math.max(45, _startSize.height + _totalDelta.dy),
        );

        widget.onDrag(newSize);
      },
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFFF0C75C),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFF111827), width: 1.5),
        ),
        child: const Icon(
          Icons.open_in_full,
          size: 10,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final ShapeType type;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final bool selected;

  _ShapePainter({
    required this.type,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    switch (type) {
      case ShapeType.square:
      case ShapeType.rectangle:
        path.addRRect(
          RRect.fromRectAndRadius(
            Offset.zero & size,
            const Radius.circular(14),
          ),
        );
        break;

      case ShapeType.circle:
        path.addOval(Offset.zero & size);
        break;

      case ShapeType.triangle:
        path.moveTo(size.width / 2, 0);

        path.lineTo(size.width, size.height);

        path.lineTo(0, size.height);

        path.close();
        break;

      case ShapeType.pentagon:
        _regularPolygon(path, size, 5);
        break;

      case ShapeType.hexagon:
        _regularPolygon(path, size, 6);
        break;
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = backgroundColor,
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = borderColor,
    );

    if (selected) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFF0C75C),
      );
    }
  }

  void _regularPolygon(Path path, Size size, int sides) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2;

    for (var i = 0; i < sides; i++) {
      final angle = (-math.pi / 2) + ((2 * math.pi * i) / sides);

      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.selected != selected;
  }
}

enum LineType { single, double }

class DiagramLine {
  final String id;

  String sourceShapeId;
  String targetShapeId;

  LineType type;

  String name;

  Color color;

  double width;

  double animationProgress;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceShapeId': sourceShapeId,
    'targetShapeId': targetShapeId,
    'type': type.name,
    'name': name,
    'color': color.toARGB32(),
    'width': width,
    'animationProgress': animationProgress,
  };

  static DiagramLine fromJson(Map<String, dynamic> json) {
    return DiagramLine(
      id: json['id'] as String,
      sourceShapeId: json['sourceShapeId'] as String,
      targetShapeId: json['targetShapeId'] as String,
      type: LineType.values.byName(json['type'] as String),
      name: json['name'] as String? ?? '',
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      animationProgress: (json['animationProgress'] as num?)?.toDouble() ?? 0,
    );
  }

  DiagramLine({
    required this.id,
    required this.sourceShapeId,
    required this.targetShapeId,
    this.type = LineType.single,
    this.name = '',
    this.color = const Color(0xFF111827),
    this.width = 2,
    this.animationProgress = 0,
  });

  DiagramLine copyWith({
    String? sourceShapeId,
    String? targetShapeId,
    LineType? type,
    String? name,
    Color? color,
    double? width,
    double? animationProgress,
  }) {
    return DiagramLine(
      id: id,
      sourceShapeId: sourceShapeId ?? this.sourceShapeId,
      targetShapeId: targetShapeId ?? this.targetShapeId,
      type: type ?? this.type,
      name: name ?? this.name,
      color: color ?? this.color,
      width: width ?? this.width,
      animationProgress: animationProgress ?? this.animationProgress,
    );
  }
}

class DiagramGroup {
  final String id;

  ShapeType type;

  Offset position;

  Size size;

  String name;

  List<String> childShapeIds;

  List<String> childLineIds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'position': {'dx': position.dx, 'dy': position.dy},
    'size': {'width': size.width, 'height': size.height},
    'name': name,
    'childShapeIds': childShapeIds,
    'childLineIds': childLineIds,
  };

  static DiagramGroup fromJson(Map<String, dynamic> json) {
    return DiagramGroup(
      id: json['id'] as String,
      type: ShapeType.values.byName(json['type'] as String),
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      size: Size(
        (json['size']['width'] as num).toDouble(),
        (json['size']['height'] as num).toDouble(),
      ),
      name: json['name'] as String,
      childShapeIds: List<String>.from(json['childShapeIds'] as List),
      childLineIds: List<String>.from(json['childLineIds'] as List),
    );
  }

  DiagramGroup({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.name,
    required this.childShapeIds,
    required this.childLineIds,
  });
}

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  /// Every time the application starts, it begins in
  /// the device/browser system theme.
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isLightMode => _themeMode == ThemeMode.light;

  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeController();

  Future<void> loadTheme() async {
    // Intentionally do not load a saved preference.
    //
    // Learning Tech always starts in the device/browser's
    // system theme.
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  void setLightMode() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  void setDarkMode() {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  void toggleLightDark() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }

    notifyListeners();
  }

  void useSystemMode() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}

enum CanvasTool { select, component, container, connect }

class DiagramController extends ChangeNotifier {
  final List<DiagramShape> _shapes = [];
  final List<DiagramLine> _lines = [];
  final List<DiagramGroup> _groups = [];

  List<DiagramShape> get shapes => List.unmodifiable(_shapes);
  List<DiagramLine> get lines => List.unmodifiable(_lines);
  List<DiagramGroup> get groups => List.unmodifiable(_groups);

  ShapeType _activeShapeType = ShapeType.rectangle;

  ShapeType get activeShapeType => _activeShapeType;

  ShapeType _activeContainerType = ShapeType.rectangle;

  ShapeType get activeContainerType => _activeContainerType;

  LineType _activeLineType = LineType.single;

  LineType get activeLineType => _activeLineType;

  CanvasTool _activeTool = CanvasTool.select;

  CanvasTool get activeTool => _activeTool;

  String? _selectedShapeId;
  String? _selectedLineId;
  String? _selectedGroupId;

  String? get selectedShapeId => _selectedShapeId;
  String? get selectedLineId => _selectedLineId;
  String? get selectedGroupId => _selectedGroupId;

  final Set<String> _multiSelectedShapeIds = {};
  final Set<String> _multiSelectedLineIds = {};
  final Set<String> _multiSelectedGroupIds = {};

  Set<String> get multiSelectedShapeIds =>
      Set.unmodifiable(_multiSelectedShapeIds);

  Set<String> get multiSelectedLineIds =>
      Set.unmodifiable(_multiSelectedLineIds);

  Set<String> get multiSelectedGroupIds =>
      Set.unmodifiable(_multiSelectedGroupIds);
  bool get hasSelection =>
      _selectedShapeId != null ||
      _selectedLineId != null ||
      _selectedGroupId != null ||
      _multiSelectedShapeIds.isNotEmpty ||
      _multiSelectedLineIds.isNotEmpty ||
      _multiSelectedGroupIds.isNotEmpty;
  bool get hasMultipleSelection => totalSelectedComponents > 1;
  int get totalSelectedComponents =>
      _multiSelectedShapeIds.length +
      _multiSelectedLineIds.length +
      _multiSelectedGroupIds.length +
      (_selectedShapeId != null &&
              !_multiSelectedShapeIds.contains(_selectedShapeId)
          ? 1
          : 0) +
      (_selectedLineId != null &&
              !_multiSelectedLineIds.contains(_selectedLineId)
          ? 1
          : 0) +
      (_selectedGroupId != null &&
              !_multiSelectedGroupIds.contains(_selectedGroupId)
          ? 1
          : 0);
  String? _connectionSourceId;
  String? get connectionSourceId => _connectionSourceId;
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  double _animationProgress = 0;
  double get animationProgress => _animationProgress;
  double animationSpeed = 1;
  String? currentProjectId;
  String? currentProjectName;
  String currentFolder = 'General'; // default only; user can change to anything

  final List<_DiagramSnapshot> _undoStack = [];

  void setShapeType(ShapeType type) {
    _activeShapeType = type;
    _activeTool = CanvasTool.component;
    notifyListeners();
  }

  void setContainerType(ShapeType type) {
    _activeContainerType = type;
    _activeTool = CanvasTool.container;
    notifyListeners();
  }

  void setLineType(LineType type) {
    _activeLineType = type;
    _activeTool = CanvasTool.connect;
    notifyListeners();
  }

  void setTool(CanvasTool tool) {
    _activeTool = tool;

    if (tool != CanvasTool.connect) {
      _connectionSourceId = null;
    }

    notifyListeners();
  }

  DiagramShape? findShape(String id) {
    for (final shape in _shapes) {
      if (shape.id == id) {
        return shape;
      }
    }

    return null;
  }

  DiagramGroup? findGroup(String id) {
    for (final group in _groups) {
      if (group.id == id) {
        return group;
      }
    }

    return null;
  }

  DiagramLine? findLine(String id) {
    for (final line in _lines) {
      if (line.id == id) {
        return line;
      }
    }

    return null;
  }

  void addShape(Offset position, {ShapeType? type}) {
    _saveHistory();

    final shapeType = type ?? _activeShapeType;

    final shape = DiagramShape(
      id: 'shape-${DateTime.now().microsecondsSinceEpoch}',
      type: shapeType,
      position: position,
      width: _defaultShapeWidth(shapeType),
      height: _defaultShapeHeight(shapeType),
      text: _defaultShapeName(shapeType),
      borderColor: const Color(0xFF111827),
      backgroundColor: Colors.white,
      borderWidth: 2,
      zIndex: _shapes.length,
    );

    _shapes.add(shape);

    _selectShapeInternal(shape.id);

    notifyListeners();
  }

  double _defaultShapeWidth(ShapeType type) {
    switch (type) {
      case ShapeType.square:
        return 130;
      case ShapeType.rectangle:
        return 170;
      case ShapeType.triangle:
        return 150;
      case ShapeType.hexagon:
        return 170;
      case ShapeType.pentagon:
        return 160;
      case ShapeType.circle:
        return 130;
    }
  }

  double _defaultShapeHeight(ShapeType type) {
    switch (type) {
      case ShapeType.square:
        return 130;
      case ShapeType.rectangle:
        return 90;
      case ShapeType.triangle:
        return 130;
      case ShapeType.hexagon:
        return 110;
      case ShapeType.pentagon:
        return 130;
      case ShapeType.circle:
        return 130;
    }
  }

  String _defaultShapeName(ShapeType type) {
    switch (type) {
      case ShapeType.square:
        return 'Square';
      case ShapeType.rectangle:
        return 'Component';
      case ShapeType.triangle:
        return 'Triangle';
      case ShapeType.hexagon:
        return 'Service';
      case ShapeType.pentagon:
        return 'Pentagon';
      case ShapeType.circle:
        return 'Component';
    }
  }

  void addContainer(Offset position, {ShapeType? type}) {
    _saveHistory();

    final containerType = type ?? _activeContainerType;

    final group = DiagramGroup(
      id: 'group-${DateTime.now().microsecondsSinceEpoch}',
      type: containerType,
      position: position,
      size: const Size(420, 260),
      name: 'Container',
      childShapeIds: const [],
      childLineIds: const [],
    );

    _groups.add(group);

    _selectGroupInternal(group.id);

    notifyListeners();
  }

  void moveShape(String id, Offset newPosition) {
    final shape = findShape(id);

    if (shape == null) return;

    shape.position = newPosition;

    notifyListeners();
  }

  void moveGroup(String id, Offset newPosition) {
    final group = findGroup(id);

    if (group == null) return;

    group.position = newPosition;

    notifyListeners();
  }

  void resizeShape(String id, Size newSize) {
    final shape = findShape(id);

    if (shape == null) return;

    shape.width = math.max(45, newSize.width);
    shape.height = math.max(45, newSize.height);

    notifyListeners();
  }

  void resizeGroup(String id, Size newSize) {
    final group = findGroup(id);

    if (group == null) return;

    group.size = Size(
      math.max(160, newSize.width),
      math.max(100, newSize.height),
    );

    notifyListeners();
  }

  void finishShapeMove() {
    _saveHistory();
  }

  void finishGroupMove() {
    _saveHistory();
  }

  /// Returns the id of the nearest line to [point], or null if none within [threshold].
  String? hitTestLine(Offset point, {double threshold = 16}) {
    String? bestId;
    double bestDist = threshold;

    for (final line in _lines) {
      final source = findShape(line.sourceShapeId);
      final target = findShape(line.targetShapeId);
      if (source == null || target == null) continue;

      final start = connectionPoint(source, centerOf(target));
      final end = connectionPoint(target, centerOf(source));

      final dist = _distanceToSegment(point, start, end);
      if (dist < bestDist) {
        bestDist = dist;
        bestId = line.id;
      }
    }

    return bestId;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLen2 == 0) return (p - a).distance;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / abLen2).clamp(0.0, 1.0);
    final closest = a + ab * t;
    return (p - closest).distance;
  }

  void selectShape(String id, {bool addToSelection = false}) {
    if (addToSelection) {
      _toggleShapeSelection(id);
    } else {
      _selectShapeInternal(id);
    }

    notifyListeners();
  }

  void selectLine(String id, {bool addToSelection = false}) {
    if (addToSelection) {
      _toggleLineSelection(id);
    } else {
      _selectLineInternal(id);
    }

    notifyListeners();
  }

  void selectGroup(String id, {bool addToSelection = false}) {
    if (addToSelection) {
      _toggleGroupSelection(id);
    } else {
      _selectGroupInternal(id);
    }

    notifyListeners();
  }

  void _selectShapeInternal(String id) {
    _selectedShapeId = id;
    _selectedLineId = null;
    _selectedGroupId = null;

    _multiSelectedShapeIds
      ..clear()
      ..add(id);

    _multiSelectedLineIds.clear();
    _multiSelectedGroupIds.clear();
  }

  void _selectLineInternal(String id) {
    _selectedShapeId = null;
    _selectedLineId = id;
    _selectedGroupId = null;

    _multiSelectedShapeIds.clear();

    _multiSelectedLineIds
      ..clear()
      ..add(id);

    _multiSelectedGroupIds.clear();
  }

  void _selectGroupInternal(String id) {
    _selectedShapeId = null;
    _selectedLineId = null;
    _selectedGroupId = id;

    _multiSelectedShapeIds.clear();
    _multiSelectedLineIds.clear();

    _multiSelectedGroupIds
      ..clear()
      ..add(id);
  }

  void _toggleShapeSelection(String id) {
    if (_multiSelectedShapeIds.contains(id)) {
      _multiSelectedShapeIds.remove(id);
    } else {
      _multiSelectedShapeIds.add(id);
    }

    _selectedShapeId = id;
    _selectedLineId = null;
    _selectedGroupId = null;
  }

  void _toggleLineSelection(String id) {
    if (_multiSelectedLineIds.contains(id)) {
      _multiSelectedLineIds.remove(id);
    } else {
      _multiSelectedLineIds.add(id);
    }

    _selectedShapeId = null;
    _selectedLineId = id;
    _selectedGroupId = null;
  }

  void _toggleGroupSelection(String id) {
    if (_multiSelectedGroupIds.contains(id)) {
      _multiSelectedGroupIds.remove(id);
    } else {
      _multiSelectedGroupIds.add(id);
    }

    _selectedShapeId = null;
    _selectedLineId = null;
    _selectedGroupId = id;
  }

  bool isShapeSelected(String id) {
    return _selectedShapeId == id || _multiSelectedShapeIds.contains(id);
  }

  bool isLineSelected(String id) {
    return _selectedLineId == id || _multiSelectedLineIds.contains(id);
  }

  bool isGroupSelected(String id) {
    return _selectedGroupId == id || _multiSelectedGroupIds.contains(id);
  }

  void clearSelection() {
    _selectedShapeId = null;
    _selectedLineId = null;
    _selectedGroupId = null;

    _multiSelectedShapeIds.clear();
    _multiSelectedLineIds.clear();
    _multiSelectedGroupIds.clear();

    _connectionSourceId = null;

    notifyListeners();
  }

  void handleShapeTap(String shapeId, {bool multiSelect = false}) {
    if (_activeTool == CanvasTool.connect) {
      if (_connectionSourceId == null) {
        _connectionSourceId = shapeId;
        _selectShapeInternal(shapeId);
      } else if (_connectionSourceId != shapeId) {
        connectShapes(_connectionSourceId!, shapeId);

        _connectionSourceId = null;
      }

      notifyListeners();
      return;
    }

    selectShape(shapeId, addToSelection: multiSelect);
  }

  void handleGroupTap(String groupId, {bool multiSelect = false}) {
    selectGroup(groupId, addToSelection: multiSelect);
  }

  void connectShapes(String sourceId, String targetId) {
    final source = findShape(sourceId);
    final target = findShape(targetId);

    if (source == null || target == null) return;

    if (sourceId == targetId) return;

    final exists = _lines.any(
      (line) =>
          line.sourceShapeId == sourceId && line.targetShapeId == targetId,
    );

    if (exists) return;

    _saveHistory();

    _lines.add(
      DiagramLine(
        id: 'line-${DateTime.now().microsecondsSinceEpoch}',
        sourceShapeId: sourceId,
        targetShapeId: targetId,
        type: _activeLineType,
        name: 'Connection',
        color: const Color(0xFF111827),
        width: 3,
        animationProgress: 0,
      ),
    );

    notifyListeners();
  }

  void updateShapeText(String id, String text) {
    final shape = findShape(id);

    if (shape == null) return;

    _saveHistory();

    shape.text = text.trim().isEmpty ? 'Component' : text.trim();

    notifyListeners();
  }

  void updateGroupName(String id, String name) {
    final group = findGroup(id);

    if (group == null) return;

    _saveHistory();

    group.name = name.trim().isEmpty ? 'Container' : name.trim();

    notifyListeners();
  }

  void updateShapeBorderColor(String id, Color color) {
    final shape = findShape(id);

    if (shape == null) return;

    _saveHistory();

    shape.borderColor = color;

    notifyListeners();
  }

  void updateShapeBackgroundColor(String id, Color color) {
    final shape = findShape(id);

    if (shape == null) return;

    _saveHistory();

    shape.backgroundColor = color;

    notifyListeners();
  }

  void updateLineName(String id, String name) {
    final line = findLine(id);

    if (line == null) return;

    _saveHistory();

    line.name = name.trim().isEmpty ? 'Connection' : name.trim();

    notifyListeners();
  }

  void updateLineColor(String id, Color color) {
    final line = findLine(id);

    if (line == null) return;

    _saveHistory();

    line.color = color;

    notifyListeners();
  }

  void updateLineType(String id, LineType type) {
    final line = findLine(id);

    if (line == null) return;

    _saveHistory();

    line.type = type;

    notifyListeners();
  }

  void editSelected() {
    notifyListeners();
  }

  void deleteSelected() {
    _saveHistory();

    final shapeIds = <String>{..._multiSelectedShapeIds};

    if (_selectedShapeId != null) {
      shapeIds.add(_selectedShapeId!);
    }

    final lineIds = <String>{..._multiSelectedLineIds};

    if (_selectedLineId != null) {
      lineIds.add(_selectedLineId!);
    }

    final groupIds = <String>{..._multiSelectedGroupIds};

    if (_selectedGroupId != null) {
      groupIds.add(_selectedGroupId!);
    }

    if (shapeIds.isNotEmpty) {
      _lines.removeWhere(
        (line) =>
            shapeIds.contains(line.sourceShapeId) ||
            shapeIds.contains(line.targetShapeId),
      );

      for (final group in _groups) {
        group.childShapeIds.removeWhere(shapeIds.contains);
      }

      _shapes.removeWhere((shape) => shapeIds.contains(shape.id));
    }

    if (lineIds.isNotEmpty) {
      _lines.removeWhere((line) => lineIds.contains(line.id));

      for (final group in _groups) {
        group.childLineIds.removeWhere(lineIds.contains);
      }
    }

    if (groupIds.isNotEmpty) {
      _groups.removeWhere((group) => groupIds.contains(group.id));
    }

    clearSelection();
  }

  void deleteSelectedShape() {
    if (_selectedShapeId == null) return;

    deleteSelected();
  }

  void deleteSelectedLine() {
    if (_selectedLineId == null) return;

    deleteSelected();
  }

  void clearCanvas() {
    _saveHistory();

    _shapes.clear();
    _lines.clear();
    _groups.clear();

    clearSelection();
  }

  void play() {
    _isPlaying = true;
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void resetAnimation() {
    _animationProgress = 0;

    for (final line in _lines) {
      line.animationProgress = 0;
    }

    notifyListeners();
  }

  void updateAnimation(double value) {
    _animationProgress = value;

    for (final line in _lines) {
      line.animationProgress = value;
    }

    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    final snapshot = _undoStack.removeLast();

    _shapes
      ..clear()
      ..addAll(snapshot.shapes);

    _lines
      ..clear()
      ..addAll(snapshot.lines);

    _groups
      ..clear()
      ..addAll(snapshot.groups);

    clearSelection();
  }

  void _saveHistory() {
    _undoStack.add(
      _DiagramSnapshot(
        shapes: _shapes.map(_copyShape).toList(),
        lines: _lines.map(_copyLine).toList(),
        groups: _groups.map(_copyGroup).toList(),
      ),
    );

    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  Map<String, dynamic> exportJson() {
    return {
      'shapes': _shapes.map((s) => s.toJson()).toList(),
      'lines': _lines.map((l) => l.toJson()).toList(),
      'groups': _groups.map((g) => g.toJson()).toList(),
    };
  }

  void importJson(Map<String, dynamic> data) {
    _saveHistory();
    _shapes
      ..clear()
      ..addAll(
        (data['shapes'] as List<dynamic>).map(
          (e) => DiagramShape.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
    _lines
      ..clear()
      ..addAll(
        (data['lines'] as List<dynamic>).map(
          (e) => DiagramLine.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
    _groups
      ..clear()
      ..addAll(
        (data['groups'] as List<dynamic>).map(
          (e) => DiagramGroup.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
    clearSelection();
    notifyListeners();
  }

  DiagramShape _copyShape(DiagramShape shape) {
    return DiagramShape(
      id: shape.id,
      type: shape.type,
      position: shape.position,
      width: shape.width,
      height: shape.height,
      text: shape.text,
      borderColor: shape.borderColor,
      backgroundColor: shape.backgroundColor,
      borderWidth: shape.borderWidth,
      parentContainerId: shape.parentContainerId,
      zIndex: shape.zIndex,
    );
  }

  DiagramLine _copyLine(DiagramLine line) {
    return DiagramLine(
      id: line.id,
      sourceShapeId: line.sourceShapeId,
      targetShapeId: line.targetShapeId,
      type: line.type,
      name: line.name,
      color: line.color,
      width: line.width,
      animationProgress: line.animationProgress,
    );
  }

  DiagramGroup _copyGroup(DiagramGroup group) {
    return DiagramGroup(
      id: group.id,
      type: group.type,
      position: group.position,
      size: group.size,
      name: group.name,
      childShapeIds: List<String>.from(group.childShapeIds),
      childLineIds: List<String>.from(group.childLineIds),
    );
  }

  Offset centerOf(DiagramShape shape) {
    return shape.position + Offset(shape.width / 2, shape.height / 2);
  }

  Offset connectionPoint(DiagramShape shape, Offset target) {
    final center = centerOf(shape);

    final dx = target.dx - center.dx;
    final dy = target.dy - center.dy;

    if (dx == 0 && dy == 0) {
      return center;
    }

    final angle = math.atan2(dy, dx);

    final halfWidth = shape.width / 2;
    final halfHeight = shape.height / 2;

    final denominator = math.sqrt(
      math.pow(math.cos(angle) / halfWidth, 2) +
          math.pow(math.sin(angle) / halfHeight, 2),
    );

    final distance = 1 / denominator;

    return center +
        Offset(math.cos(angle) * distance, math.sin(angle) * distance);
  }

  void loadDemo() {
    _shapes.clear();
    _lines.clear();
    _groups.clear();

    final user = DiagramShape(
      id: 'demo-user',
      type: ShapeType.circle,
      position: const Offset(100, 300),
      width: 120,
      height: 120,
      text: 'User',
      borderColor: const Color(0xFF111827),
      backgroundColor: Colors.white,
      borderWidth: 2,
      zIndex: 0,
    );

    final app = DiagramShape(
      id: 'demo-app',
      type: ShapeType.rectangle,
      position: const Offset(350, 290),
      width: 190,
      height: 90,
      text: 'Flutter App',
      borderColor: const Color(0xFF111827),
      backgroundColor: Colors.white,
      borderWidth: 2,
      zIndex: 1,
    );

    final api = DiagramShape(
      id: 'demo-api',
      type: ShapeType.hexagon,
      position: const Offset(650, 290),
      width: 180,
      height: 100,
      text: 'API',
      borderColor: const Color(0xFF111827),
      backgroundColor: Colors.white,
      borderWidth: 2,
      zIndex: 2,
    );

    final database = DiagramShape(
      id: 'demo-db',
      type: ShapeType.rectangle,
      position: const Offset(940, 290),
      width: 180,
      height: 90,
      text: 'Database',
      borderColor: const Color(0xFF111827),
      backgroundColor: Colors.white,
      borderWidth: 2,
      zIndex: 3,
    );

    _shapes.addAll([user, app, api, database]);

    _lines.addAll([
      DiagramLine(
        id: 'demo-line-1',
        sourceShapeId: user.id,
        targetShapeId: app.id,
        type: LineType.single,
        name: 'Request',
        color: const Color(0xFF111827),
        width: 3,
        animationProgress: 0,
      ),
      DiagramLine(
        id: 'demo-line-2',
        sourceShapeId: app.id,
        targetShapeId: api.id,
        type: LineType.single,
        name: 'API Call',
        color: const Color(0xFF111827),
        width: 3,
        animationProgress: 0,
      ),
      DiagramLine(
        id: 'demo-line-3',
        sourceShapeId: api.id,
        targetShapeId: database.id,
        type: LineType.double,
        name: 'Data',
        color: const Color(0xFF111827),
        width: 3,
        animationProgress: 0,
      ),
    ]);

    clearSelection();
  }
}

class _DiagramSnapshot {
  final List<DiagramShape> shapes;
  final List<DiagramLine> lines;
  final List<DiagramGroup> groups;

  const _DiagramSnapshot({
    required this.shapes,
    required this.lines,
    required this.groups,
  });
}

class AppTheme {
  AppTheme._();

  static const Color gold = Color(0xFFF0C75C);
  static const Color dark = Color(0xFF111827);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.light,
        surface: Colors.white,
      ),

      scaffoldBackgroundColor: Colors.white,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: dark,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: gold.withValues(alpha: 0.25),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontWeight: FontWeight.w800, color: dark);
          }

          return const TextStyle(fontWeight: FontWeight.w600);
        }),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: dark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: dark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dividerTheme: const DividerThemeData(thickness: 1, space: 1),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.dark,
        surface: dark,
      ),

      scaffoldBackgroundColor: dark,

      appBarTheme: const AppBarTheme(
        backgroundColor: dark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1F2937),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: gold.withValues(alpha: 0.25),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            );
          }

          return const TextStyle(fontWeight: FontWeight.w600);
        }),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: dark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: dark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.10),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

class Math {
  static double cos(double value) {
    return _cos(value);
  }

  static double sin(double value) {
    return _sin(value);
  }
}

double _cos(double value) {
  double result = 1;
  double term = 1;

  for (int i = 1; i <= 10; i++) {
    term *= -value * value / ((2 * i - 1) * (2 * i));

    result += term;
  }

  return result;
}

double _sin(double value) {
  double result = value;
  double term = value;

  for (int i = 1; i <= 10; i++) {
    term *= -value * value / ((2 * i) * (2 * i + 1));

    result += term;
  }

  return result;
}

class DiagramCanvas extends StatefulWidget {
  const DiagramCanvas({super.key});

  @override
  State<DiagramCanvas> createState() => _DiagramCanvasState();
}

class _DiagramCanvasState extends State<DiagramCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1800),
        )..addListener(() {
          context.read<DiagramController>().updateAnimation(
            _animationController.value,
          );
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<DiagramController>();

      controller.loadDemo();

      if (controller.isPlaying) {
        _animationController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagramController>(
      builder: (context, controller, child) {
        if (controller.isPlaying) {
          if (!_animationController.isAnimating) {
            _animationController.repeat();
          }
        } else {
          _animationController.stop();
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.35,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(600),
            constrained: false,
            panEnabled: true,
            scaleEnabled: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                if (controller.activeTool == CanvasTool.component) {
                  controller.addShape(details.localPosition);
                } else if (controller.activeTool == CanvasTool.container) {
                  controller.addContainer(details.localPosition);
                } else {
                  // Try selecting a nearby line first (select / connect tools)
                  final lineId = controller.hitTestLine(details.localPosition);
                  if (lineId != null) {
                    controller.selectLine(lineId);
                  } else {
                    controller.clearSelection();
                  }
                }
              },
              child: SizedBox(
                width: 1800,
                height: 1200,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: const Size(1800, 1200),
                      painter: _CanvasBackgroundPainter(
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),

                    ...controller.groups.map((group) {
                      return _GroupWidget(
                        key: ValueKey(group.id),
                        group: group,
                        selected: controller.isGroupSelected(group.id),
                        onTap: () {
                          controller.selectGroup(group.id);
                        },
                        onMove: (pos) {
                          controller.moveGroup(group.id, pos);
                        },
                        onMoveEnd: controller.finishGroupMove,
                        onResize: (size) {
                          controller.resizeGroup(group.id, size);
                        },
                      );
                    }),

                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LinePainter(
                          controller: controller,
                          animationValue: controller.animationProgress,
                        ),
                      ),
                    ),

                    ...controller.shapes.map((shape) {
                      return ShapeWidget(
                        shape: shape,
                        selected: controller.isShapeSelected(shape.id),
                        onTap: () {
                          controller.handleShapeTap(shape.id);
                        },
                        onLongPress: () {
                          controller.handleShapeTap(
                            shape.id,
                            multiSelect: true,
                          );
                        },
                        onResize: (size) {
                          controller.resizeShape(shape.id, size);
                        },
                        onMove: (pos) {
                          controller.moveShape(shape.id, pos);
                        },
                        onMoveEnd: controller.finishShapeMove,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

void _showSaveDialog(BuildContext context, DiagramController controller) {
  final nameController = TextEditingController(
    text: controller.currentProjectName ?? '',
  );
  final folderController = TextEditingController(
    text: controller.currentFolder.isEmpty
        ? 'General'
        : controller.currentFolder,
  );

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return FutureBuilder<List<String>>(
        future: DiagramStorage().listFolders(),
        builder: (context, snapshot) {
          final existingFolders = snapshot.data ?? <String>[];

          return AlertDialog(
            title: const Text(
              'Save diagram',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'File name',
                      hintText: 'e.g. API architecture',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: folderController,
                    decoration: const InputDecoration(
                      labelText: 'Folder',
                      hintText: 'Type any folder name',
                      helperText: 'Create a new folder just by typing its name',
                    ),
                  ),
                  if (existingFolders.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Or pick an existing folder',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: existingFolders.map((f) {
                        return ActionChip(
                          label: Text(f),
                          onPressed: () {
                            folderController.text = f;
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final project = await DiagramStorage().save(
                    name: nameController.text,
                    folder: folderController.text,
                    data: controller.exportJson(),
                    existingId: controller.currentProjectId,
                  );
                  controller.currentProjectId = project.id;
                  controller.currentProjectName = project.name;
                  controller.currentFolder = project.folder;
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Saved "${project.name}" in ${project.folder}/',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    final diagramController = context.watch<DiagramController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Learning Tech',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),

        actions: [
          IconButton(
            tooltip: themeController.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: () {
              themeController.toggleLightDark();
            },
            icon: Icon(
              themeController.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),

          IconButton(
            tooltip: 'Help',
            onPressed: () {
              _showHelp(context);
            },
            icon: const Icon(Icons.help_outline_rounded),
          ),

          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),

          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF0C75C),
        foregroundColor: const Color(0xFF111827),
        icon: const Icon(Icons.save_rounded),
        label: const Text(
          'Save',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: () {
          _showSaveDialog(context, diagramController);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ShapePalette(),
            _ActionToolbar(controller: diagramController),
            const Expanded(child: DiagramCanvas()),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learning Tech Help',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 18),

                _HelpItem(
                  icon: Icons.touch_app_outlined,
                  text: 'Tap a component to select it.',
                ),

                _HelpItem(
                  icon: Icons.open_with_outlined,
                  text: 'Drag a selected component to move it.',
                ),

                _HelpItem(
                  icon: Icons.crop_free_outlined,
                  text: 'Drag the resize handle to change its size.',
                ),

                _HelpItem(
                  icon: Icons.touch_app,
                  text: 'Long press components to support multiple selection and editing.',
                ),

                _HelpItem(
                  icon: Icons.link,
                  text: 'Select Connect and tap two shapes to create a connection.',
                ),

                _HelpItem(
                  icon: Icons.play_arrow_rounded,
                  text: 'Play demonstrates the movement of information through your architecture.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionToolbar extends StatelessWidget {
  final DiagramController controller;

  const _ActionToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasSelection = controller.hasSelection;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.folder_open_rounded,
              label: 'Saved files',
              onPressed: () {
                _showSavedFilesSheet(context, controller);
              },
            ),
            _ToolButton(
              icon: controller.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              label: controller.isPlaying ? 'Pause' : 'Play',
              onPressed: controller.togglePlayPause,
            ),

            _ToolButton(
              icon: Icons.restart_alt_rounded,
              label: 'Reset',
              onPressed: controller.resetAnimation,
            ),

            _ToolButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              onPressed: controller.undo,
            ),

            _ToolButton(
              icon: Icons.edit_outlined,
              label: 'Edit',
              enabled: hasSelection,
              onPressed: () {
                _editSelection(context, controller);
              },
            ),

            _ToolButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              enabled: hasSelection,
              onPressed: () {
                _confirmDeleteSelected(context, controller);
              },
            ),

            _ToolButton(
              icon: Icons.delete_sweep_outlined,
              label: 'Delete All',
              onPressed: () {
                _confirmDeleteAll(context, controller);
              },
            ),

            const SizedBox(width: 8),

            if (hasSelection)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0C75C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.totalSelectedComponents} selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A6A00),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _editSelection(BuildContext context, DiagramController controller) {
    if (controller.selectedShapeId != null) {
      _editShape(context, controller, controller.selectedShapeId!);
      return;
    }

    if (controller.selectedLineId != null) {
      _editLine(context, controller, controller.selectedLineId!);
      return;
    }

    if (controller.selectedGroupId != null) {
      _editGroup(context, controller, controller.selectedGroupId!);
      return;
    }
  }

  void _editShape(
    BuildContext context,
    DiagramController controller,
    String id,
  ) {
    final shape = controller.findShape(id);

    if (shape == null) return;

    final textController = TextEditingController(text: shape.text);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Component',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Component name',
              hintText: 'Enter component name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                controller.updateShapeText(id, textController.text);

                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editLine(
    BuildContext context,
    DiagramController controller,
    String id,
  ) {
    final line = controller.findLine(id);

    if (line == null) return;

    final textController = TextEditingController(text: line.name);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        LineType selectedType = line.type;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Edit Connection',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Connection name',
                    ),
                  ),

                  const SizedBox(height: 18),

                  SegmentedButton<LineType>(
                    segments: const [
                      ButtonSegment(
                        value: LineType.single,
                        label: Text('Single'),
                        icon: Icon(Icons.arrow_forward),
                      ),
                      ButtonSegment(
                        value: LineType.double,
                        label: Text('Double'),
                        icon: Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (value) {
                      setState(() {
                        selectedType = value.first;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    controller.updateLineName(id, textController.text);

                    controller.updateLineType(id, selectedType);

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editGroup(
    BuildContext context,
    DiagramController controller,
    String id,
  ) {
    final group = controller.findGroup(id);

    if (group == null) return;

    final textController = TextEditingController(text: group.name);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Container',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: 'Container name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                controller.updateGroupName(id, textController.text);

                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSelected(
    BuildContext context,
    DiagramController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete selected?'),
          content: Text(
            'Delete ${controller.totalSelectedComponents} selected component(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                controller.deleteSelected();
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSavedFilesSheet(
    BuildContext context,
    DiagramController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _SavedFilesSheet(
          controller: controller,
          onOpen: (project) {
            controller.importJson(project.data);
            controller.currentProjectId = project.id;
            controller.currentProjectName = project.name;
            controller.currentFolder = project.folder;
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Opened "${project.name}"')));
          },
          onDelete: (project) async {
            await DiagramStorage().delete(project.id);
            if (controller.currentProjectId == project.id) {
              controller.currentProjectId = null;
              controller.currentProjectName = null;
            }
          },
        );
      },
    );
  }

  void _confirmDeleteAll(BuildContext context, DiagramController controller) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete everything?'),
          content: const Text(
            'This will remove all shapes, containers and connections from the canvas.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                controller.clearCanvas();
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: label,
        child: IconButton.filledTonal(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            foregroundColor: enabled ? const Color(0xFF111827) : null,
            backgroundColor: enabled
                ? const Color(0xFFF0C75C).withValues(alpha: 0.22)
                : null,
          ),
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HelpItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: const Color(0xFFF0C75C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _CanvasBackgroundPainter extends CustomPainter {
  final bool isDark;

  _CanvasBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0xFF1F2937).withValues(alpha: 0.35)
          : const Color(0xFFE5E7EB).withValues(alpha: 0.5)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _LinePainter extends CustomPainter {
  final DiagramController controller;
  final double animationValue;

  _LinePainter({required this.controller, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in controller.lines) {
      final source = _findShape(line.sourceShapeId);

      final target = _findShape(line.targetShapeId);

      if (source == null || target == null) {
        continue;
      }

      final sourceCenter = controller.centerOf(source);

      final targetCenter = controller.centerOf(target);

      final start = controller.connectionPoint(source, targetCenter);

      final end = controller.connectionPoint(target, sourceCenter);

      final isSelected = controller.isLineSelected(line.id);
      final lineColor = isSelected ? const Color(0xFFF0C75C) : line.color;
      final strokeWidth = isSelected ? line.width + 2 : line.width;

      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start, end, paint);

      _drawArrow(canvas, end, start, lineColor);

      if (line.type == LineType.double) {
        _drawArrow(canvas, start, end, lineColor);
      }

      if (line.name.isNotEmpty) {
        _drawLabel(canvas, start, end, line.name);
      }

      if (controller.isPlaying) {
        _drawParticle(canvas, start, end, line);

        if (line.type == LineType.double) {
          _drawParticle(canvas, end, start, line);
        }
      }
    }
  }

  DiagramShape? _findShape(String id) {
    for (final shape in controller.shapes) {
      if (shape.id == id) {
        return shape;
      }
    }

    return null;
  }

  void _drawArrow(Canvas canvas, Offset tip, Offset previous, Color color) {
    final direction = tip - previous;

    final angle = math.atan2(direction.dy, direction.dx);

    const length = 10.0;

    final path = Path();

    path.moveTo(tip.dx, tip.dy);

    path.lineTo(
      tip.dx - length * math.cos(angle - 0.5),
      tip.dy - length * math.sin(angle - 0.5),
    );

    path.lineTo(
      tip.dx - length * math.cos(angle + 0.5),
      tip.dy - length * math.sin(angle + 0.5),
    );

    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas, Offset start, Offset end, String text) {
    final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    painter.layout();

    final background = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(
      center: midpoint,
      width: painter.width + 14,
      height: painter.height + 8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      background,
    );

    painter.paint(
      canvas,
      Offset(midpoint.dx - painter.width / 2, midpoint.dy - painter.height / 2),
    );
  }

  void _drawParticle(
    Canvas canvas,
    Offset start,
    Offset end,
    DiagramLine line,
  ) {
    final progress = line.animationProgress.clamp(0.0, 1.0);

    final point = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );

    final paint = Paint()
      ..color = const Color(0xFFF0C75C)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(point, 7, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return true;
  }
}

class _GroupWidget extends StatefulWidget {
  final DiagramGroup group;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMove;
  final VoidCallback onMoveEnd;
  final ValueChanged<Size> onResize;

  const _GroupWidget({
    super.key,
    required this.group,
    required this.selected,
    required this.onTap,
    required this.onMove,
    required this.onMoveEnd,
    required this.onResize,
  });

  @override
  State<_GroupWidget> createState() => _GroupWidgetState();
}

class _GroupWidgetState extends State<_GroupWidget> {
  Offset? _groupStartPosition;
  Offset _totalDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final selected = widget.selected;

    return Positioned(
      left: group.position.dx,
      top: group.position.dy,
      width: group.size.width,
      height: group.size.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanStart: (_) {
          _groupStartPosition = group.position;
          _totalDelta = Offset.zero;
          if (!selected) {
            widget.onTap();
          }
        },
        onPanUpdate: (details) {
          if (_groupStartPosition == null) return;
          _totalDelta += details.delta;
          widget.onMove(_groupStartPosition! + _totalDelta);
        },
        onPanEnd: (_) {
          _groupStartPosition = null;
          _totalDelta = Offset.zero;
          widget.onMoveEnd();
        },
        onPanCancel: () {
          _groupStartPosition = null;
          _totalDelta = Offset.zero;
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFF0C75C)
                        : const Color(0xFF111827),
                    width: selected ? 3 : 2,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0C75C).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                right: -7,
                bottom: -7,
                child: _ResizeHandle(
                  onDrag: widget.onResize,
                  currentSize: group.size,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ShapePalette extends StatelessWidget {
  const ShapePalette({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiagramController>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _ToolCard(
            title: 'Tool Shape',
            child: Row(
              children: ShapeType.values.map((type) {
                return _ShapeChoice(
                  label: _label(type),
                  selected:
                      controller.activeShapeType == type &&
                      controller.activeTool == CanvasTool.component,
                  onTap: () {
                    controller.setShapeType(type);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 10),
          _ToolCard(
            title: 'Container',
            child: Row(
              children:
                  [
                    ShapeType.square,
                    ShapeType.rectangle,
                    ShapeType.triangle,
                    ShapeType.circle,
                  ].map((type) {
                    return _ShapeChoice(
                      label: _label(type),
                      selected:
                          controller.activeContainerType == type &&
                          controller.activeTool == CanvasTool.container,
                      onTap: () {
                        controller.setContainerType(type);
                      },
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(width: 10),
          _ToolCard(
            title: 'Connection',
            child: Row(
              children: [
                _ShapeChoice(
                  label: 'Single →',
                  selected:
                      controller.activeLineType == LineType.single &&
                      controller.activeTool == CanvasTool.connect,
                  onTap: () {
                    controller.setLineType(LineType.single);
                  },
                ),
                _ShapeChoice(
                  label: 'Double ↔',
                  selected:
                      controller.activeLineType == LineType.double &&
                      controller.activeTool == CanvasTool.connect,
                  onTap: () {
                    controller.setLineType(LineType.double);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _label(ShapeType type) {
    return type.name[0].toUpperCase() + type.name.substring(1);
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ToolCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ShapeChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ShapeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF0C75C).withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFFF0C75C)
                  : Colors.grey.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class Course {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String practiceUrl;
  final String gameUrl;
  final String category;

  const Course({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.practiceUrl,
    required this.gameUrl,
    required this.category,
  });
}

class CourseController extends ChangeNotifier {
  final List<Course> _courses = const [
    Course(
      id: 'html',
      name: 'HTML5',
      description: 'Learn how to structure professional, semantic and accessible websites.',
      icon: Icons.html,
      color: Color(0xFFE44D26),
      practiceUrl: 'https://developer.mozilla.org/en-US/docs/Web/HTML',
      gameUrl: 'https://developer.mozilla.org/en-US/docs/Web/HTML',
      category: 'Web Development',
    ),

    Course(
      id: 'css',
      name: 'CSS3',
      description: 'Master responsive layouts, animations, positioning, grids and modern styling.',
      icon: Icons.style,
      color: Color(0xFF1572B6),
      practiceUrl: 'https://developer.mozilla.org/en-US/docs/Web/CSS',
      gameUrl: 'https://developer.mozilla.org/en-US/docs/Web/CSS',
      category: 'Web Development',
    ),

    Course(
      id: 'javascript',
      name: 'JavaScript',
      description: 'Build interactive web applications using modern JavaScript and browser APIs.',
      icon: Icons.javascript,
      color: Color(0xFFF7DF1E),
      practiceUrl: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript',
      gameUrl: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript',
      category: 'Web Development',
    ),

    Course(
      id: 'flutter',
      name: 'Flutter',
      description: 'Build responsive cross-platform mobile, desktop and web applications.',
      icon: Icons.flutter_dash,
      color: Color(0xFF02569B),
      practiceUrl: 'https://docs.flutter.dev/',
      gameUrl: 'https://docs.flutter.dev/',
      category: 'App Development',
    ),

    Course(
      id: 'dart',
      name: 'Dart',
      description: 'Learn the Dart language powering modern Flutter application development.',
      icon: Icons.code,
      color: Color(0xFF0175C2),
      practiceUrl: 'https://dart.dev/language',
      gameUrl: 'https://dart.dev/language',
      category: 'App Development',
    ),

    Course(
      id: 'aws',
      name: 'AWS',
      description: 'Practice cloud architecture using EC2, VPC, ALB, ASG, IAM, S3 and more.',
      icon: Icons.cloud,
      color: Color(0xFFFF9900),
      practiceUrl: 'https://aws.amazon.com/getting-started/',
      gameUrl: 'https://aws.amazon.com/getting-started/',
      category: 'Cloud',
    ),

    Course(
      id: 'azure',
      name: 'Microsoft Azure',
      description: 'Explore Azure compute, networking, identity, storage and cloud architecture.',
      icon: Icons.cloud_queue,
      color: Color(0xFF0078D4),
      practiceUrl: 'https://learn.microsoft.com/azure/',
      gameUrl: 'https://learn.microsoft.com/azure/',
      category: 'Cloud',
    ),

    Course(
      id: 'gcp',
      name: 'Google Cloud',
      description: 'Learn compute, networking, storage, IAM and scalable Google Cloud architectures.',
      icon: Icons.cloud_circle,
      color: Color(0xFF4285F4),
      practiceUrl: 'https://cloud.google.com/docs',
      gameUrl: 'https://cloud.google.com/docs',
      category: 'Cloud',
    ),

    Course(
      id: 'docker',
      name: 'Docker',
      description: 'Learn containers, images, Dockerfiles, networks, volumes and deployments.',
      icon: Icons.inventory_2,
      color: Color(0xFF2496ED),
      practiceUrl: 'https://docs.docker.com/get-started/',
      gameUrl: 'https://docs.docker.com/get-started/',
      category: 'DevOps',
    ),

    Course(
      id: 'github-actions',
      name: 'GitHub Actions',
      description: 'Create CI/CD workflows for testing, building and deploying applications.',
      icon: Icons.account_tree,
      color: Color(0xFF24292F),
      practiceUrl: 'https://docs.github.com/actions',
      gameUrl: 'https://docs.github.com/actions',
      category: 'DevOps',
    ),

    Course(
      id: 'kubernetes',
      name: 'Kubernetes',
      description: 'Understand containers orchestration, pods, services, deployments and clusters.',
      icon: Icons.hub,
      color: Color(0xFF326CE5),
      practiceUrl: 'https://kubernetes.io/docs/home/',
      gameUrl: 'https://kubernetes.io/docs/home/',
      category: 'DevOps',
    ),

    Course(
      id: 'terraform',
      name: 'Terraform',
      description: 'Practice infrastructure as code and repeatable cloud infrastructure deployment.',
      icon: Icons.construction,
      color: Color(0xFF844FBA),
      practiceUrl: 'https://developer.hashicorp.com/terraform/docs',
      gameUrl: 'https://developer.hashicorp.com/terraform/docs',
      category: 'Infrastructure',
    ),

    Course(
      id: 'lambda',
      name: 'AWS Lambda',
      description:
          'Build serverless applications using event-driven cloud functions.',
      icon: Icons.functions,
      color: Color(0xFFFF9900),
      practiceUrl: 'https://docs.aws.amazon.com/lambda/',
      gameUrl: 'https://docs.aws.amazon.com/lambda/',
      category: 'Serverless',
    ),

    Course(
      id: 'cloud-security',
      name: 'Cloud Security',
      description: 'Learn IAM, encryption, network security, secrets and cloud security principles.',
      icon: Icons.security,
      color: Color(0xFF64748B),
      practiceUrl: 'https://aws.amazon.com/security/',
      gameUrl: 'https://aws.amazon.com/security/',
      category: 'Security',
    ),

    Course(
      id: 'devops',
      name: 'DevOps',
      description: 'Combine development, automation, CI/CD, monitoring and infrastructure practices.',
      icon: Icons.sync_alt,
      color: Color(0xFF475569),
      practiceUrl: 'https://aws.amazon.com/devops/',
      gameUrl: 'https://aws.amazon.com/devops/',
      category: 'DevOps',
    ),

    Course(
      id: 'databases',
      name: 'Databases',
      description: 'Understand relational, NoSQL, distributed and cloud database architecture.',
      icon: Icons.storage,
      color: Color(0xFF0F766E),
      practiceUrl: 'https://www.mongodb.com/docs/',
      gameUrl: 'https://www.mongodb.com/docs/',
      category: 'Backend',
    ),

    Course(
      id: 'git',
      name: 'Git & GitHub',
      description: 'Learn source control, branching, merging, pull requests and collaboration.',
      icon: Icons.merge_type,
      color: Color(0xFFF05032),
      practiceUrl: 'https://docs.github.com/',
      gameUrl: 'https://docs.github.com/',
      category: 'Development',
    ),

    Course(
      id: 'agentic-ai',
      name: 'Agentic AI',
      description: 'Explore AI agents, tools, workflows, orchestration and autonomous systems.',
      icon: Icons.auto_awesome,
      color: Color(0xFF7C3AED),
      practiceUrl: 'https://platform.openai.com/docs',
      gameUrl: 'https://platform.openai.com/docs',
      category: 'Artificial Intelligence',
    ),
  ];

  List<Course> get courses => List.unmodifiable(_courses);

  List<String> get categories {
    return _courses.map((course) => course.category).toSet().toList();
  }

  List<Course> byCategory(String category) {
    return _courses.where((course) => course.category == category).toList();
  }

  Course? findById(String id) {
    for (final course in _courses) {
      if (course.id == id) {
        return course;
      }
    }

    return null;
  }
}

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onPractice;

  const CourseCard({super.key, required this.course, required this.onPractice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: course.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(course.icon, color: course.color, size: 28),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    course.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              course.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Text(
                course.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.72,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  openCourseUrl(
                    context,
                    title: '${course.name} Practice',
                    url: course.practiceUrl,
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Practice Project'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF0C75C),
                  foregroundColor: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final Course course;
  final VoidCallback onPlay;

  const GameCard({super.key, required this.course, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF0C75C).withValues(alpha: 0.28),
                        course.color.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    Icons.sports_esports_outlined,
                    color: course.color,
                    size: 29,
                  ),
                ),
                const Spacer(),
                Icon(course.icon, color: course.color),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              '${course.name} Game',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Text(
                'Test your knowledge of ${course.name} through an interactive technology challenge.',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.72,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  openCourseUrl(
                    context,
                    title: '${course.name} Game',
                    url: course.gameUrl,
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 21),
                label: const Text('Play Course Game'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF0C75C),
                  foregroundColor: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const WebViewScreen({super.key, required this.title, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _progress = progress;
              });
            }
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _hasError = false;
                _progress = 0;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _progress = 100;
              });
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (_) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _reload() async {
    setState(() {
      _hasError = false;
      _progress = 0;
    });

    await _controller.reload();
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Back',
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          IconButton(
            tooltip: 'Forward',
            onPressed: _goForward,
            icon: const Icon(Icons.arrow_forward_ios),
          ),
          IconButton(
            tooltip: 'Reload',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: _progress < 100 && !_hasError
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                  color: const Color(0xFFF0C75C),
                ),
              )
            : null,
      ),
      body: _hasError
          ? _ErrorView(onRetry: _reload)
          : WebViewWidget(controller: _controller),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 18),
            const Text(
              'Unable to load this page',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _selectedCategory = 'All';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CourseController>();
    final theme = Theme.of(context);

    final categories = ['All', ...controller.categories];

    final courses = controller.courses.where((course) {
      final categoryMatch =
          _selectedCategory == 'All' || course.category == _selectedCategory;

      final searchMatch =
          _search.trim().isEmpty ||
          course.name.toLowerCase().contains(_search.toLowerCase()) ||
          course.description.toLowerCase().contains(_search.toLowerCase());

      return categoryMatch && searchMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Courses',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CoursesHeader(
              totalCourses: controller.courses.length,
              search: _search,
            ),

            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = category == _selectedCategory;

                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: const Color(0xFFF0C75C),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF111827)
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: courses.isEmpty
                  ? const _EmptyCourses()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;

                        int columns;

                        if (width >= 1200) {
                          columns = 4;
                        } else if (width >= 850) {
                          columns = 3;
                        } else if (width >= 560) {
                          columns = 2;
                        } else {
                          columns = 1;
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: columns == 1 ? 1.35 : 0.92,
                              ),
                          itemCount: courses.length,
                          itemBuilder: (context, index) {
                            final course = courses[index];

                            return CourseCard(
                              course: course,
                              onPractice: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => WebViewScreen(
                                      title: '${course.name} Practice',
                                      url: course.practiceUrl,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final controller = TextEditingController(text: _search);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Search Courses'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'AWS, Flutter, Docker...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) {
              setState(() {
                _search = controller.text;
              });

              Navigator.pop(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();

                setState(() {
                  _search = '';
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _search = controller.text;
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}

class _CoursesHeader extends StatelessWidget {
  final int totalCourses;
  final String search;

  const _CoursesHeader({required this.totalCourses, required this.search});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF0C75C).withValues(alpha: 0.18),
              theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFF0C75C).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFFF0C75C),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF111827),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn Technology',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    search.isEmpty
                        ? '$totalCourses technology courses available'
                        : 'Searching for "$search"',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 60,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.4),
          ),
          const SizedBox(height: 14),
          const Text(
            'No courses found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Try another search or category.'),
        ],
      ),
    );
  }
}

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CourseController>();

    final categories = ['All', ...controller.categories];

    final games = _selectedCategory == 'All'
        ? controller.courses
        : controller.byCategory(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Games',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Game Help',
            onPressed: () => _showGameHelp(context),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF0C75C).withValues(alpha: 0.22),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFF0C75C).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0C75C),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        color: Color(0xFF111827),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Technology Challenge',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Practice what you have learned and test your technical knowledge.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = category == _selectedCategory;

                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: const Color(0xFFF0C75C),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? const Color(0xFF111827) : null,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  int columns;

                  if (width >= 1200) {
                    columns = 4;
                  } else if (width >= 850) {
                    columns = 3;
                  } else if (width >= 560) {
                    columns = 2;
                  } else {
                    columns = 1;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: columns == 1 ? 1.35 : 0.92,
                    ),
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final course = games[index];

                      return GameCard(
                        course: course,
                        onPlay: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WebViewScreen(
                                title: '${course.name} Game',
                                url: course.gameUrl,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGameHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How Games Work',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                _HelpRow(
                  icon: Icons.play_arrow_rounded,
                  text: 'Choose a technology and start its challenge.',
                ),
                _HelpRow(
                  icon: Icons.quiz_outlined,
                  text: 'Answer technical questions and complete challenges.',
                ),
                _HelpRow(
                  icon: Icons.emoji_events_outlined,
                  text: 'Use your results to identify areas that need more practice.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HelpRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 9, color: Color(0xFFF0C75C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0C75C),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF0C75C)
                              .withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 50,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Text(
                    'Learning Tech',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Learn. Practice. Design. Demonstrate.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.65,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 35),

                  _InfoCard(
                    icon: Icons.description_outlined,
                    title: 'About Learning Tech',
                    description: 'Learning Tech is designed to help technology learners understand concepts visually, practice technical skills and demonstrate how systems work through interactive diagrams.',
                  ),

                  const SizedBox(height: 16),

                  _InfoCard(
                    icon: Icons.account_tree_outlined,
                    title: 'Visual System Design',
                    description: 'Create your own architecture diagrams by placing components, connecting them with lines, grouping related components and demonstrating how information flows through a system.',
                  ),

                  const SizedBox(height: 16),

                  _InfoCard(
                    icon: Icons.school_outlined,
                    title: 'Technology Learning',
                    description: 'Explore Web Development, Flutter, Dart, AWS, Azure, Google Cloud, Docker, Kubernetes, GitHub Actions, Terraform, DevOps, Databases and Artificial Intelligence.',
                  ),

                  const SizedBox(height: 30),

                  _ContactTile(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: 'your-email@example.com',
                    onTap: () {},
                  ),

                  const SizedBox(height: 10),

                  _ContactTile(
                    icon: Icons.language_outlined,
                    title: 'Website',
                    value: 'your-website.com',
                    onTap: () {},
                  ),

                  const SizedBox(height: 10),

                  _ContactTile(
                    icon: Icons.business_outlined,
                    title: 'Technology Portfolio',
                    value: 'Learning Tech Portfolio',
                    onTap: () {},
                  ),

                  const SizedBox(height: 35),

                  Text(
                    'Built with Flutter & Dart',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '© ${DateTime.now().year} Learning Tech',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF0C75C).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFFF0C75C),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: const Color(0xFFF0C75C)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF0C75C).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFFF0C75C)),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    CoursesScreen(),
    GamesScreen(),
    ContactScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'Games',
          ),
          NavigationDestination(
            icon: Icon(Icons.contact_page_outlined),
            selectedIcon: Icon(Icons.contact_page),
            label: 'Contact',
          ),
        ],
      ),
    );
  }
}

class SavedProject {
  final String id;
  final String name;
  final String
  folder; // any user-defined string, e.g. "web", "client-x", "demo-day"
  final DateTime updatedAt;
  final Map<String, dynamic> data;

  SavedProject({
    required this.id,
    required this.name,
    required this.folder,
    required this.updatedAt,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'folder': folder,
    'updatedAt': updatedAt.toIso8601String(),
    'data': data,
  };

  static SavedProject fromJson(Map<String, dynamic> json) {
    return SavedProject(
      id: json['id'] as String,
      name: json['name'] as String,
      folder: (json['folder'] as String?)?.trim().isNotEmpty == true
          ? (json['folder'] as String).trim()
          : 'General',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}

class DiagramStorage {
  static const _key = 'learning_tech_saved_projects';

  Future<List<SavedProject>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SavedProject.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _persist(List<SavedProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(projects.map((p) => p.toJson()).toList()),
    );
  }

  /// All unique folder names derived from saved projects (sorted).
  Future<List<String>> listFolders() async {
    final all = await loadAll();
    final set = <String>{};
    for (final p in all) {
      final f = p.folder.trim().isEmpty ? 'General' : p.folder.trim();
      set.add(f);
    }
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<Map<String, List<SavedProject>>> byFolder() async {
    final all = await loadAll();
    final map = <String, List<SavedProject>>{};
    for (final p in all) {
      final f = p.folder.trim().isEmpty ? 'General' : p.folder.trim();
      map.putIfAbsent(f, () => []).add(p);
    }
    // sort files inside each folder by date desc
    for (final entry in map.entries) {
      entry.value.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return map;
  }

  Future<SavedProject> save({
    required String name,
    required String folder,
    required Map<String, dynamic> data,
    String? existingId,
  }) async {
    final cleanFolder = folder.trim().isEmpty ? 'General' : folder.trim();
    final all = await loadAll();
    final id = existingId ?? 'proj-${DateTime.now().microsecondsSinceEpoch}';
    final project = SavedProject(
      id: id,
      name: name.trim().isEmpty ? 'Untitled' : name.trim(),
      folder: cleanFolder,
      updatedAt: DateTime.now(),
      data: data,
    );

    final index = all.indexWhere((p) => p.id == id);
    if (index >= 0) {
      all[index] = project;
    } else {
      all.add(project);
    }
    await _persist(all);
    return project;
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((p) => p.id == id);
    await _persist(all);
  }

  /// Optional: rename every project that lives in [oldFolder] to [newFolder].
  Future<void> renameFolder(String oldFolder, String newFolder) async {
    final cleanNew = newFolder.trim().isEmpty ? 'General' : newFolder.trim();
    final all = await loadAll();
    var changed = false;
    for (var i = 0; i < all.length; i++) {
      if (all[i].folder == oldFolder) {
        all[i] = SavedProject(
          id: all[i].id,
          name: all[i].name,
          folder: cleanNew,
          updatedAt: all[i].updatedAt,
          data: all[i].data,
        );
        changed = true;
      }
    }
    if (changed) await _persist(all);
  }
}

class _SavedFilesSheet extends StatefulWidget {
  final DiagramController controller;
  final ValueChanged<SavedProject> onOpen;
  final Future<void> Function(SavedProject) onDelete;

  const _SavedFilesSheet({
    required this.controller,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  State<_SavedFilesSheet> createState() => _SavedFilesSheetState();
}

class _SavedFilesSheetState extends State<_SavedFilesSheet> {
  Map<String, List<SavedProject>> _byFolder = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final map = await DiagramStorage().byFolder();
    if (!mounted) return;
    setState(() {
      _byFolder = map;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final folderNames = _byFolder.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saved diagrams',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Your folders — create any name when you save',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (folderNames.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No saved files yet.\nTap Save to create your first diagram.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: folderNames.map((folder) {
                      final files = _byFolder[folder] ?? [];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          leading: const Icon(
                            Icons.folder_rounded,
                            color: Color(0xFFF0C75C),
                          ),
                          title: Text(
                            folder,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text('${files.length} file(s)'),
                          children: files.map((p) {
                            return ListTile(
                              title: Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                'Updated ${p.updatedAt.toLocal()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await widget.onDelete(p);
                                  await _reload();
                                },
                              ),
                              onTap: () => widget.onOpen(p),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
