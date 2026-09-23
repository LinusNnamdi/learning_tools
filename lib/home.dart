import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:learn/common/banner_ads.dart';
import 'package:learn/common/common.dart';
import 'package:learn/courses/course.dart';
import 'package:learn/games/games.dart';
import 'package:learn/helps/help.dart';
import 'package:learn/jobs/jobs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

//_copygroup
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

  Color borderColor;
  Color backgroundColor;

  List<String> childShapeIds;
  List<String> childLineIds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'position': {'dx': position.dx, 'dy': position.dy},
    'size': {'width': size.width, 'height': size.height},
    'name': name,
    'borderColor': borderColor.toARGB32(),
    'backgroundColor': backgroundColor.toARGB32(),
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

      // Defaults keep previously saved projects compatible.
      borderColor: Color((json['borderColor'] as num?)?.toInt() ?? 0xFF111827),
      backgroundColor: Color(
        (json['backgroundColor'] as num?)?.toInt() ?? 0x00000000,
      ),

      childShapeIds: List<String>.from(
        json['childShapeIds'] as List? ?? const [],
      ),
      childLineIds: List<String>.from(
        json['childLineIds'] as List? ?? const [],
      ),
    );
  }

  DiagramGroup({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.name,
    this.borderColor = const Color(0xFF111827),
    this.backgroundColor = const Color(0x00000000),
    List<String> childShapeIds = const [],
    List<String> childLineIds = const [],
  }) : childShapeIds = List<String>.from(childShapeIds),
       childLineIds = List<String>.from(childLineIds);
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
  final List<_DiagramSnapshot> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  bool get canDuplicateSelection {
    final onlyOneSelected = totalSelectedComponents == 1;

    if (!onlyOneSelected) {
      return false;
    }

    return _selectedShapeId != null || _selectedGroupId != null;
  }

  void setShapeType(ShapeType type) {
    _activeShapeType = type;
    _activeTool = CanvasTool.component;
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

  void duplicateSelected() {
    if (!canDuplicateSelection) return;

    if (_selectedShapeId != null) {
      _duplicateShape(_selectedShapeId!);
      return;
    }

    if (_selectedGroupId != null) {
      _duplicateGroup(_selectedGroupId!);
    }
  }

  void _duplicateShape(String id) {
    final original = findShape(id);

    if (original == null) return;

    _saveHistory();

    final duplicate = DiagramShape(
      id: 'shape-${DateTime.now().microsecondsSinceEpoch}',
      type: ShapeType.rectangle,
      position: original.position + const Offset(30, 30),
      width: original.width,
      height: original.height,
      text: '${original.text} Copy',
      borderColor: original.borderColor,
      backgroundColor: original.backgroundColor,
      borderWidth: original.borderWidth,

      // Do not automatically attach the duplicate to the
      // original container.
      parentContainerId: null,

      zIndex: _shapes.length,
    );

    _shapes.add(duplicate);

    _selectShapeInternal(duplicate.id);

    notifyListeners();
  }

  void _duplicateGroup(String id) {
    final original = findGroup(id);

    if (original == null) return;

    _saveHistory();

    final duplicate = DiagramGroup(
      id: 'group-${DateTime.now().microsecondsSinceEpoch}',
      type: original.type,
      position: original.position + const Offset(30, 30),
      size: original.size,
      name: '${original.name} Copy',

      // Important:
      // duplicating the container should not steal or share
      // the original container's child IDs.
      childShapeIds: const [],
      childLineIds: const [],
    );

    _groups.add(duplicate);

    _selectGroupInternal(duplicate.id);

    notifyListeners();
  }

  void addContainer(Offset position) {
    _saveHistory();

    final group = DiagramGroup(
      id: 'group-${DateTime.now().microsecondsSinceEpoch}',
      type: ShapeType.rectangle,
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

    final delta = newPosition - group.position;

    group.position = newPosition;

    for (final shapeId in group.childShapeIds) {
      final shape = findShape(shapeId);

      if (shape != null) {
        shape.position += delta;
      }
    }

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

  void finishShapeMove(String shapeId) {
    _updateShapeContainerMembership(shapeId);
    _saveHistory();

    notifyListeners();
  }

  void _updateShapeContainerMembership(String shapeId) {
    final shape = findShape(shapeId);

    if (shape == null) return;

    final shapeCenter = Offset(
      shape.position.dx + shape.width / 2,
      shape.position.dy + shape.height / 2,
    );

    DiagramGroup? containingGroup;

    // Search newest containers first.
    //
    // If containers overlap, the most recently created container
    // containing the shape's center becomes its parent.
    for (final group in _groups.reversed) {
      final bounds = Rect.fromLTWH(
        group.position.dx,
        group.position.dy,
        group.size.width,
        group.size.height,
      );

      if (bounds.contains(shapeCenter)) {
        containingGroup = group;
        break;
      }
    }

    // Remove this shape from any previous container.
    for (final group in _groups) {
      group.childShapeIds.remove(shapeId);
    }

    shape.parentContainerId = containingGroup?.id;

    if (containingGroup != null &&
        !containingGroup.childShapeIds.contains(shapeId)) {
      containingGroup.childShapeIds.add(shapeId);
    }
  }

  void finishGroupMove() {
    _saveHistory();
  }

  /// Returns the id of the nearest line to [point], or null if none within [threshold].
  String? hitTestLine(Offset point, {double threshold = 16}) {
    String? bestId;
    double bestDist = threshold;

    for (final line in _lines) {
      final sourceCenter = centerOfNode(line.sourceShapeId);

      final targetCenter = centerOfNode(line.targetShapeId);

      if (sourceCenter == null || targetCenter == null) {
        continue;
      }

      final start = connectionPointForNode(line.sourceShapeId, targetCenter);

      final end = connectionPointForNode(line.targetShapeId, sourceCenter);

      if (start == null || end == null) {
        continue;
      }

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
        connectNodes(_connectionSourceId!, shapeId);

        _connectionSourceId = null;
      }

      notifyListeners();
      return;
    }

    selectShape(shapeId, addToSelection: multiSelect);
  }

  void handleGroupTap(String groupId, {bool multiSelect = false}) {
    if (_activeTool == CanvasTool.connect) {
      if (_connectionSourceId == null) {
        _connectionSourceId = groupId;
        _selectGroupInternal(groupId);
      } else if (_connectionSourceId != groupId) {
        connectNodes(_connectionSourceId!, groupId);

        _connectionSourceId = null;
      }

      notifyListeners();
      return;
    }

    selectGroup(groupId, addToSelection: multiSelect);
  }

  void connectNodes(String sourceId, String targetId) {
    if (sourceId == targetId) return;

    final sourceCenter = centerOfNode(sourceId);
    final targetCenter = centerOfNode(targetId);

    // Both IDs must represent either a shape or a container.
    if (sourceCenter == null || targetCenter == null) {
      return;
    }

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

  ///original.type Kept for compatibility with existing tests and code.
  void connectShapes(String sourceId, String targetId) {
    connectNodes(sourceId, targetId);
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

  void updateGroupBorderColor(String id, Color color) {
    final group = findGroup(id);

    if (group == null) return;

    _saveHistory();

    group.borderColor = color;

    notifyListeners();
  }

  void updateGroupBackgroundColor(String id, Color color) {
    final group = findGroup(id);

    if (group == null) return;

    _saveHistory();

    group.backgroundColor = color;

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
      // Remove any connection attached to a deleted container.
      _lines.removeWhere(
        (line) =>
            groupIds.contains(line.sourceShapeId) ||
            groupIds.contains(line.targetShapeId),
      );

      // Shapes survive when their container is deleted,
      // but they are no longer members of that container.
      for (final shape in _shapes) {
        if (shape.parentContainerId != null &&
            groupIds.contains(shape.parentContainerId)) {
          shape.parentContainerId = null;
        }
      }

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

    _redoStack.add(_createSnapshot());

    final snapshot = _undoStack.removeLast();

    _restoreSnapshot(snapshot);
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    _undoStack.add(_createSnapshot());

    final snapshot = _redoStack.removeLast();

    _restoreSnapshot(snapshot);
  }

  void _restoreSnapshot(_DiagramSnapshot snapshot) {
    _shapes
      ..clear()
      ..addAll(snapshot.shapes.map(_copyShape));

    _lines
      ..clear()
      ..addAll(snapshot.lines.map(_copyLine));

    _groups
      ..clear()
      ..addAll(snapshot.groups.map(_copyGroup));

    _selectedShapeId = null;
    _selectedLineId = null;
    _selectedGroupId = null;

    _multiSelectedShapeIds.clear();
    _multiSelectedLineIds.clear();
    _multiSelectedGroupIds.clear();

    _connectionSourceId = null;

    notifyListeners();
  }

  _DiagramSnapshot _createSnapshot() {
    return _DiagramSnapshot(
      shapes: _shapes.map(_copyShape).toList(),
      lines: _lines.map(_copyLine).toList(),
      groups: _groups.map(_copyGroup).toList(),
    );
  }

  void _saveHistory() {
    _undoStack.add(_createSnapshot());

    // Once a new edit is made after an undo,
    // the old redo history is no longer valid.
    _redoStack.clear();

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
      borderColor: group.borderColor,
      backgroundColor: group.backgroundColor,
      childShapeIds: group.childShapeIds,
      childLineIds: group.childLineIds,
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

  Offset? centerOfNode(String id) {
    final shape = findShape(id);

    if (shape != null) {
      return centerOf(shape);
    }

    final group = findGroup(id);

    if (group != null) {
      return group.position +
          Offset(group.size.width / 2, group.size.height / 2);
    }

    return null;
  }

  Offset? connectionPointForNode(String id, Offset target) {
    final shape = findShape(id);

    if (shape != null) {
      return connectionPoint(shape, target);
    }

    final group = findGroup(id);

    if (group == null) {
      return null;
    }

    return _groupConnectionPoint(group, target);
  }

  Offset _groupConnectionPoint(DiagramGroup group, Offset target) {
    final center =
        group.position + Offset(group.size.width / 2, group.size.height / 2);

    final dx = target.dx - center.dx;
    final dy = target.dy - center.dy;

    if (dx == 0 && dy == 0) {
      return center;
    }

    final halfWidth = group.size.width / 2;
    final halfHeight = group.size.height / 2;

    final horizontalScale = dx == 0 ? double.infinity : halfWidth / dx.abs();

    final verticalScale = dy == 0 ? double.infinity : halfHeight / dy.abs();

    final scale = math.min(horizontalScale, verticalScale);

    return center + Offset(dx * scale, dy * scale);
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

  void startNewProject() {
    _shapes.clear();
    _lines.clear();
    _groups.clear();

    _selectedShapeId = null;
    _selectedLineId = null;
    _selectedGroupId = null;

    _multiSelectedShapeIds.clear();
    _multiSelectedLineIds.clear();
    _multiSelectedGroupIds.clear();

    _connectionSourceId = null;

    currentProjectId = null;
    currentProjectName = null;
    currentFolder = 'General';

    _animationProgress = 0;
    _isPlaying = false;

    _undoStack.clear();
    _redoStack.clear();

    notifyListeners();
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

              onLongPressStart: (details) {
                // Shapes and containers have their own long-press handlers.
                // This parent handler is therefore useful for painted connections.
                final lineId = controller.hitTestLine(
                  details.localPosition,
                  threshold: 20,
                );

                if (lineId == null) {
                  return;
                }

                _showComponentContextMenu(
                  context: context,
                  controller: controller,
                  kind: _CanvasComponentKind.line,
                  id: lineId,
                );
              },

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
                          controller.handleGroupTap(group.id);
                        },
                        onMove: (pos) {
                          controller.moveGroup(group.id, pos);
                        },
                        onMoveEnd: controller.finishGroupMove,
                        onResize: (size) {
                          controller.resizeGroup(group.id, size);
                        },
                        onLongPress: () {
                          _showComponentContextMenu(
                            context: context,
                            controller: controller,
                            kind: _CanvasComponentKind.group,
                            id: group.id,
                          );
                        },
                      );
                    }),

                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _LinePainter(
                            controller: controller,
                            animationValue: controller.animationProgress,
                          ),
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
                          _showComponentContextMenu(
                            context: context,
                            controller: controller,
                            kind: _CanvasComponentKind.shape,
                            id: shape.id,
                          );
                        },
                        onResize: (size) {
                          controller.resizeShape(shape.id, size);
                        },
                        onMove: (pos) {
                          controller.moveShape(shape.id, pos);
                        },
                        onMoveEnd: () {
                          controller.finishShapeMove(shape.id);
                        },
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

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    final diagramController = context.watch<DiagramController>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.account_tree_rounded, color: Color(0xFFF0C75C)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  diagramController.currentProjectName ?? 'Untitled Project',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
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
                !(themeController.isDarkMode)
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
            ),

  IconButton(
    tooltip: 'Help',
    icon: const Icon(Icons.help_outline_rounded),
    onPressed: () => openEarnDeeAiHelp(
      context,
      pageTitle: 'Workspace',
      faqs: HelpFaqData.workspace,
    ),
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
        body: ResponsiveAdShell(
          showTopOnSmall: true,
          showBottomOnSmall: false,
          child: Column(
            children: [
              const ShapePalette(),
              _ActionToolbar(controller: diagramController),
              const Expanded(child: DiagramCanvas()),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final VoidCallback? onStartWork;

  const HomeScreen({super.key, this.onStartWork});

  static const String _guideVideoUrl =
      'https://www.youtube.com/watch?v=YOUR_VIDEO_ID';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Learning Tech',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Consumer<ThemeController>(
            builder: (context, themeController, child) {
              return IconButton(
                tooltip: themeController.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: themeController.toggleLightDark,
                icon: Icon(
                  themeController.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  Container(
                    width: 78,
                    height: 78,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0C75C),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.account_tree_rounded,
                      size: 40,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Communicate and animate your thoughts easily.',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Create visual systems, connect ideas, and demonstrate how information flows.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 1.5,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.70,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;

                      final startWork = _HomeActionCard(
                        icon: Icons.add_rounded,
                        title: 'Start Work',
                        description: 'Open a completely blank workspace and start building.',
                        primary: true,
                        onTap: () {
                          final controller = context.read<DiagramController>();

                          controller.startNewProject();

                          if (onStartWork != null) {
                            onStartWork!();
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WorkspaceScreen(),
                            ),
                          );
                        },
                      );

                      final guideVideo = _HomeActionCard(
                        icon: Icons.play_circle_outline_rounded,
                        title: 'Guide Video',
                        description:
                            'Watch the Learning Tech guide on YouTube.',
                        onTap: () {
                          _openGuideVideo(context);
                        },
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: startWork),
                            const SizedBox(width: 16),
                            Expanded(child: guideVideo),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          startWork,
                          const SizedBox(height: 16),
                          guideVideo,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  Text(
                    'Your Work',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Open diagrams you have previously saved.',
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () {
                      _showHomeSavedFiles(
                        context,
                        context.read<DiagramController>(),
                      );
                    },
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('View Saved Work'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openGuideVideo(BuildContext context) async {
    final uri = Uri.parse(_guideVideoUrl);

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the guide video.')),
      );
    }
  }

  void _showHomeSavedFiles(BuildContext context, DiagramController controller) {
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

            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WorkspaceScreen()));
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
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool primary;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: primary
          ? const Color(0xFFF0C75C)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: primary
                      ? const Color(0xFF111827)
                      : const Color(0xFFF0C75C).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: primary ? Colors.white : const Color(0xFFF0C75C),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: primary ? const Color(0xFF111827) : null,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: primary
                            ? const Color(0xFF111827).withValues(alpha: 0.75)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Icon(
                Icons.arrow_forward_rounded,
                color: primary ? const Color(0xFF111827) : null,
              ),
            ],
          ),
        ),
      ),
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
              enabled: controller.canUndo,
              onPressed: controller.undo,
            ),

            _ToolButton(
              icon: Icons.redo_rounded,
              label: 'Redo',
              enabled: controller.canRedo,
              onPressed: controller.redo,
            ),

            _ToolButton(
              icon: Icons.copy_rounded,
              label: 'Duplicate',
              enabled: controller.canDuplicateSelection,
              onPressed: controller.duplicateSelected,
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

const List<Color> _diagramColors = [
  Color(0xFF111827),
  Color(0xFF334155),
  Color(0xFF64748B),
  Color(0xFFFFFFFF),
  Color(0xFFF0C75C),
  Color(0xFFFF7A00),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFF3B82F6),
  Color(0xFF06B6D4),
  Color(0xFF008080),
  Color(0xFF10B981),
  Color(0xFF84CC16),
];

class _DiagramColorSelector extends StatelessWidget {
  final String label;
  final Color selectedColor;
  final ValueChanged<Color> onChanged;
  final bool allowTransparent;

  const _DiagramColorSelector({
    required this.label,
    required this.selectedColor,
    required this.onChanged,
    this.allowTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (allowTransparent)
              _DiagramColorSwatch(
                color: Colors.transparent,
                selected:
                    selectedColor.toARGB32() == Colors.transparent.toARGB32(),
                onTap: () => onChanged(Colors.transparent),
                transparent: true,
              ),
            ..._diagramColors.map(
              (color) => _DiagramColorSwatch(
                color: color,
                selected: selectedColor.toARGB32() == color.toARGB32(),
                onTap: () => onChanged(color),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DiagramColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool transparent;

  const _DiagramColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: transparent ? null : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? const Color(0xFFF0C75C)
                : Theme.of(context).dividerColor,
            width: selected ? 3 : 1.5,
          ),
        ),
        child: transparent
            ? const Icon(Icons.block, size: 20, color: Colors.redAccent)
            : selected
            ? Icon(
                Icons.check,
                size: 18,
                color: color.computeLuminance() > 0.55
                    ? const Color(0xFF111827)
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}

void _editShape(BuildContext context, DiagramController controller, String id) {
  final shape = controller.findShape(id);

  if (shape == null) return;

  final textController = TextEditingController(text: shape.text);

  Color selectedBorderColor = shape.borderColor;
  Color selectedBackgroundColor = shape.backgroundColor;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'Edit Component',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Component name',
                        hintText: 'Enter component name',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _DiagramColorSelector(
                      label: 'Fill colour',
                      selectedColor: selectedBackgroundColor,
                      allowTransparent: true,
                      onChanged: (color) {
                        setState(() {
                          selectedBackgroundColor = color;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    _DiagramColorSelector(
                      label: 'Border colour',
                      selectedColor: selectedBorderColor,
                      onChanged: (color) {
                        setState(() {
                          selectedBorderColor = color;
                        });
                      },
                    ),
                  ],
                ),
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

                  controller.updateShapeBackgroundColor(
                    id,
                    selectedBackgroundColor,
                  );

                  controller.updateShapeBorderColor(id, selectedBorderColor);

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

void _editLine(BuildContext context, DiagramController controller, String id) {
  final line = controller.findLine(id);

  if (line == null) return;

  final textController = TextEditingController(text: line.name);

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      LineType selectedType = line.type;
      Color selectedColor = line.color;

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
                const SizedBox(height: 24),

                _DiagramColorSelector(
                  label: 'Line colour',
                  selectedColor: selectedColor,
                  onChanged: (color) {
                    setState(() {
                      selectedColor = color;
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

                  controller.updateLineColor(id, selectedColor);

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

void _editGroup(BuildContext context, DiagramController controller, String id) {
  final group = controller.findGroup(id);

  if (group == null) return;

  final textController = TextEditingController(text: group.name);

  Color selectedBorderColor = group.borderColor;
  Color selectedBackgroundColor = group.backgroundColor;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'Edit Container',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        labelText: 'Container name',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _DiagramColorSelector(
                      label: 'Background colour',
                      selectedColor: selectedBackgroundColor,
                      allowTransparent: true,
                      onChanged: (color) {
                        setState(() {
                          selectedBackgroundColor = color;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    _DiagramColorSelector(
                      label: 'Border colour',
                      selectedColor: selectedBorderColor,
                      onChanged: (color) {
                        setState(() {
                          selectedBorderColor = color;
                        });
                      },
                    ),
                  ],
                ),
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
                  controller.updateGroupName(id, textController.text);

                  controller.updateGroupBackgroundColor(
                    id,
                    selectedBackgroundColor,
                  );

                  controller.updateGroupBorderColor(id, selectedBorderColor);

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

//selectedColor.a
enum _CanvasComponentKind { shape, line, group }

void _showComponentContextMenu({
  required BuildContext context,
  required DiagramController controller,
  required _CanvasComponentKind kind,
  required String id,
}) {
  // First make the long-pressed component the active selection.
  switch (kind) {
    case _CanvasComponentKind.shape:
      controller.selectShape(id);
      break;

    case _CanvasComponentKind.line:
      controller.selectLine(id);
      break;

    case _CanvasComponentKind.group:
      controller.selectGroup(id);
      break;
  }

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final canDuplicate =
          kind == _CanvasComponentKind.shape ||
          kind == _CanvasComponentKind.group;

      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              subtitle: const Text('Edit this component'),
              onTap: () {
                Navigator.pop(sheetContext);

                switch (kind) {
                  case _CanvasComponentKind.shape:
                    _editShape(context, controller, id);
                    break;

                  case _CanvasComponentKind.line:
                    _editLine(context, controller, id);
                    break;

                  case _CanvasComponentKind.group:
                    _editGroup(context, controller, id);
                    break;
                }
              },
            ),

            if (canDuplicate)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Duplicate'),
                subtitle: Text(
                  kind == _CanvasComponentKind.shape
                      ? 'Create a copy of this component'
                      : 'Create a copy of this container',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);

                  controller.duplicateSelected();
                },
              ),

            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: const Text('Remove this item from the workspace'),
              onTap: () {
                Navigator.pop(sheetContext);

                _confirmContextDelete(
                  context: context,
                  controller: controller,
                  kind: kind,
                );
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

void _confirmContextDelete({
  required BuildContext context,
  required DiagramController controller,
  required _CanvasComponentKind kind,
}) {
  String itemName;

  switch (kind) {
    case _CanvasComponentKind.shape:
      itemName = 'component';
      break;

    case _CanvasComponentKind.line:
      itemName = 'connection';
      break;

    case _CanvasComponentKind.group:
      itemName = 'container';
      break;
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Delete $itemName?'),
        content: Text('This $itemName will be removed from the workspace.'),
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
                ? const Color.fromARGB(
                    255,
                    244,
                    178,
                    12,
                  ).withValues(alpha: 0.22)
                : null,
          ),
        ),
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
      final sourceCenter = controller.centerOfNode(line.sourceShapeId);

      final targetCenter = controller.centerOfNode(line.targetShapeId);

      if (sourceCenter == null || targetCenter == null) {
        continue;
      }

      final start = controller.connectionPointForNode(
        line.sourceShapeId,
        targetCenter,
      );

      final end = controller.connectionPointForNode(
        line.targetShapeId,
        sourceCenter,
      );

      if (start == null || end == null) {
        continue;
      }

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
  final VoidCallback onLongPress;
  final ValueChanged<Offset> onMove;
  final VoidCallback onMoveEnd;
  final ValueChanged<Size> onResize;

  const _GroupWidget({
    super.key,
    required this.group,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
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
        onLongPress: widget.onLongPress,
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
                  color: group.backgroundColor,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFF0C75C)
                        : group.borderColor,
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
            child: _ShapeChoice(
              label: 'Container',
              selected: controller.activeTool == CanvasTool.container,
              onTap: () {
                controller.setTool(CanvasTool.container);
              },
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
      body: Column(
        children: [
          // ★ Ad right under AppBar
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Center(child: PlatformBannerAd()),
          ),
          Expanded(
            child: _hasError
                ? _ErrorView(onRetry: _reload)
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _workspaceOpen = false;

  static const double _wideBreakpoint = 900;

  void _openWorkspace() {
    setState(() => _workspaceOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _workspaceOpen
          ? const WorkspaceScreen()
          : HomeScreen(onStartWork: _openWorkspace),
      const CoursesScreen(),
      const GamesScreen(),
      const JobsScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;

        if (isWide) {
          // ─── LARGE SCREEN: left NavigationRail ───
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  indicatorColor: const Color(0xFFF0C75C)
                      .withValues(alpha: 0.3),
                  selectedIconTheme: const IconThemeData(
                    color: Color(0xFF111827),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school),
                      label: Text('Courses'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.sports_esports_outlined),
                      selectedIcon: Icon(Icons.sports_esports),
                      label: Text('Games'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.work_outline_rounded),
                      selectedIcon: Icon(Icons.work_rounded),
                      label: Text('Jobs'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: pages),
                ),
              ],
            ),
          );
        }

        // ─── SMALL SCREEN: classic bottom NavigationBar ───
        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
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
                icon: Icon(Icons.work_outline_rounded),
                selectedIcon: Icon(Icons.work_rounded),
                label: 'Jobs',
              ),
            ],
          ),
        );
      },
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
