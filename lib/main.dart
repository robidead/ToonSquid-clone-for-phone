import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const ToonSquidApp());
}

class ToonSquidApp extends StatelessWidget {
  const ToonSquidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Flow Studio',
      theme: ThemeData.dark(),
      home: const AnimationEditorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DrawingPath {
  final List<Offset> points;
  String tool;
  bool isFinished;

  DrawingPath({
    required this.points,
    required this.tool,
    this.isFinished = false,
  });
}

class Bone {
  String name;
  Offset position;
  double length;
  double angle;

  Bone({
    required this.name,
    required this.position,
    required this.length,
    this.angle = 0.0,
  });
}

class AnimationEditorScreen extends StatefulWidget {
  const AnimationEditorScreen({super.key});

  @override
  State<AnimationEditorScreen> createState() => _AnimationEditorScreenState();
}

class _AnimationEditorScreenState extends State<AnimationEditorScreen> {
  int currentFrame = 0;
  final int totalFrames = 12;
  String activeTool = 'brush'; // brush, eraser, fill, bone
  
  final Map<int, List<DrawingPath>> framesData = {};
  final Map<int, Color> frameBackgrounds = {};

  final List<Bone> skeleton = [
    Bone(name: 'Плечо', position: const Offset(200, 300), length: 120, angle: -0.5),
    Bone(name: 'Предплечье', position: const Offset(0, 0), length: 100, angle: 0.5),
  ];

  int? selectedBoneIndex;

  List<DrawingPath> get currentPaths {
    return framesData.putIfAbsent(currentFrame, () => []);
  }

  @override
  Widget build(BuildContext context) {
    Color currentBgColor = frameBackgrounds[currentFrame] ?? Colors.grey[900]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Кадр: ${currentFrame + 1} / $totalFrames'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentBgColor,
                border: Border.all(color: Colors.blueGrey, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRect(
                child: GestureDetector(
                  onTapDown: (details) {
                    if (activeTool == 'fill') {
                      setState(() {
                        if (currentBgColor == Colors.grey[900]) {
                          frameBackgrounds[currentFrame] = Colors.indigo[900]!;
                        } else if (currentBgColor == Colors.indigo[900]) {
                          frameBackgrounds[currentFrame] = Colors.brown[900]!;
                        } else {
                          frameBackgrounds[currentFrame] = Colors.grey[900]!;
                        }
                      });
                    } else if (activeTool == 'bone') {
                      setState(() {
                        selectedBoneIndex = 0;
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      if (activeTool == 'bone' && selectedBoneIndex != null) {
                        final bone = skeleton[selectedBoneIndex!];
                        bone.angle += details.delta.dx * 0.02;
                      } else if (activeTool == 'brush' || activeTool == 'eraser') {
                        final localOffset = details.localPosition;
                        if (currentPaths.isEmpty || currentPaths.last.isFinished) {
                          currentPaths.add(
                            DrawingPath(
                              points: [localOffset],
                              tool: activeTool,
                            ),
                          );
                        } else {
                          currentPaths.last.points.add(localOffset);
                        }
                      }
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      if (currentPaths.isNotEmpty) {
                        currentPaths.last.isFinished = true;
                      }
                    });
                  },
                  child: CustomPaint(
                    painter: AnimationPainter(
                      currentPaths: currentPaths,
                      onionSkinPaths: currentFrame > 0 ? framesData[currentFrame - 1] : null,
                      skeleton: skeleton,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),

          // Панель инструментов
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey[850],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.brush, color: activeTool == 'brush' ? Colors.blueAccent : Colors.white),
                  onPressed: () => setState(() => activeTool = 'brush'),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.cleaning_services, color: activeTool == 'eraser' ? Colors.blueAccent : Colors.white),
                  onPressed: () => setState(() => activeTool = 'eraser'),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.format_color_fill, color: activeTool == 'fill' ? Colors.amberAccent : Colors.white),
                  onPressed: () => setState(() => activeTool = 'fill'),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.timeline, color: activeTool == 'bone' ? Colors.cyanAccent : Colors.white),
                  onPressed: () => setState(() => activeTool = 'bone'),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      currentPaths.clear();
                      frameBackgrounds.remove(currentFrame);
                    });
                  },
                ),
              ],
            ),
          ),

          // Таймлайн
          Container(
            height: 90,
            color: Colors.black87,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalFrames,
              itemBuilder: (context, index) {
                bool isSelected = index == currentFrame;
                bool hasContent = (framesData[index]?.isNotEmpty ?? false) || frameBackgrounds.containsKey(index);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentFrame = index;
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[900] : Colors.grey[800],
                      border: Border.all(
                        color: isSelected ? Colors.cyanAccent : (hasContent ? Colors.white54 : Colors.transparent),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (hasContent)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.amberAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnimationPainter extends CustomPainter {
  final List<DrawingPath> currentPaths;
  final List<DrawingPath>? onionSkinPaths;
  final List<Bone> skeleton;

  AnimationPainter({
    required this.currentPaths,
    this.onionSkinPaths,
    required this.skeleton,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Калька
    if (onionSkinPaths != null) {
      final onionPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.2)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;

      for (var path in onionSkinPaths!) {
        for (int i = 0; i < path.points.length - 1; i++) {
          canvas.drawLine(path.points[i], path.points[i + 1], onionPaint);
        }
      }
    }

    // 2. Линии
    for (var path in currentPaths) {
      final paint = Paint()
        ..color = path.tool == 'eraser' ? Colors.transparent : Colors.white
        ..strokeCap = StrokeCap.round
        ..strokeWidth = path.tool == 'eraser' ? 26.0 : 4.5
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < path.points.length - 1; i++) {
        canvas.drawLine(path.points[i], path.points[i + 1], paint);
      }
    }

    // 3. Кости
    final bonePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.fill;

    Offset startPoint = skeleton[0].position;
    for (int i = 0; i < skeleton.length; i++) {
      var bone = skeleton[i];
      double endX = startPoint.dx + bone.length * math.cos(bone.angle);
      double endY = startPoint.dy + bone.length * math.sin(bone.angle);
      Offset endPoint = Offset(endX, endY);

      canvas.drawLine(startPoint, endPoint, bonePaint);
      canvas.drawCircle(startPoint, 6, jointPaint);
      startPoint = endPoint;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
