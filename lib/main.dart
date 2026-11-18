import 'package:flutter/material.dart';

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

class AnimationEditorScreen extends StatefulWidget {
  const AnimationEditorScreen({super.key});

  @override
  State<AnimationEditorScreen> createState() => _AnimationEditorScreenState();
}

class _AnimationEditorScreenState extends State<AnimationEditorScreen> {
  int currentFrame = 0;
  final int totalFrames = 10;
  String activeTool = 'brush'; // brush, eraser, move
  
  // Хранилище рисунков для каждого кадра
  final Map<int, List<DrawingPath>> frameDrawings = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Frame: ${currentFrame + 1} / $totalFrames'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              // Заглушка для воспроизведения анимации
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Воспроизведение анимации...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Область холста для рисования
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRect(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final localOffset = details.localPosition;
                      
                      frameDrawings.putIfAbsent(currentFrame, () => []);
                      
                      if (frameDrawings[currentFrame]!.isEmpty || 
                          frameDrawings[currentFrame]!.last.isFinished) {
                        frameDrawings[currentFrame]!.add(
                          DrawingPath(
                            points: [localOffset],
                            tool: activeTool,
                          ),
                        );
                      } else {
                        frameDrawings[currentFrame]!.last.points.add(localOffset);
                      }
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      if (frameDrawings[currentFrame]?.isNotEmpty ?? false) {
                        frameDrawings[currentFrame]!.last.isFinished = true;
                      }
                    });
                  },
                  child: CustomPaint(
                    painter: AnimationPainter(
                      paths: frameDrawings[currentFrame] ?? [],
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),

          // Панель инструментов (Кисть / Ластик)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey[850],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.brush, color: activeTool == 'brush' ? Colors.blue : Colors.white),
                  onPressed: () => setState(() => activeTool = 'brush'),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(Icons.cleaning_services, color: activeTool == 'eraser' ? Colors.blue : Colors.white),
                  onPressed: () => setState(() => activeTool = 'eraser'),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      frameDrawings[currentFrame]?.clear();
                    });
                  },
                ),
              ],
            ),
          ),

          // Таймлайн кадров внизу
          Container(
            height: 100,
            color: Colors.black54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalFrames,
              itemBuilder: (context, index) {
                bool isSelected = index == currentFrame;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentFrame = index;
                    });
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[800] : Colors.grey[800],
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
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

class DrawingPath {
  final List<Offset> points;
  final String tool;
  bool isFinished;

  DrawingPath({
    required this.points,
    required this.tool,
    this.isFinished = false,
  });
}

class AnimationPainter extends CustomPainter {
  final List<DrawingPath> paths;

  AnimationPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    for (var path in paths) {
      final paint = Paint()
        ..color = path.tool == 'eraser' ? Colors.grey[900]! : Colors.white
        ..strokeCap = StrokeCap.round
        ..strokeWidth = path.tool == 'eraser' ? 24.0 : 4.0
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < path.points.length - 1; i++) {
        canvas.drawLine(path.points[i], path.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
