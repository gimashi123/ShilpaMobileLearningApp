import 'package:flutter/material.dart';
import 'dart:math' as Math;

class ActivityDraw extends StatefulWidget {
  const ActivityDraw({Key? key}) : super(key: key);

  @override
  State<ActivityDraw> createState() => _ActivityDrawState();
}

class _ActivityDrawState extends State<ActivityDraw> {
  late PageController _pageController;
  int _currentTraceIndex = 0;
  final Map<int, GlobalKey<_TracingCanvasState>> _canvasKeys = {};
  bool _showNotification = false;
  String _notificationTitle = '';
  String _notificationEmoji = '';
  Color _notificationColor = Colors.green;

  final List<TracePath> tracePaths = [
    TracePath(name: 'Straight Line', type: PathType.straight),
    TracePath(name: 'Wave', type: PathType.wave),
    TracePath(name: 'Curve', type: PathType.curve),
    TracePath(name: 'Zigzag', type: PathType.zigzag),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    for (int i = 0; i < tracePaths.length; i++) {
      _canvasKeys[i] = GlobalKey<_TracingCanvasState>();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextTrace() {
    if (_currentTraceIndex < tracePaths.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousTrace() {
    if (_currentTraceIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resetCurrentTrace() {
    _canvasKeys[_currentTraceIndex]?.currentState?.clearCanvas();
  }

  void _onLevelCompleted(int index) {
    setState(() {
      _showNotification = true;
      _notificationTitle = 'Amazing! You did it!';
      _notificationEmoji = '🌟';
      _notificationColor = Colors.green.shade400;
    });

    // Hide notification and move to next level after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showNotification = false;
      });

      // Auto-go to next level (if not last level)
      if (index < tracePaths.length - 1) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          // make sure user is still on the same level
          if (_currentTraceIndex == index) {
            _nextTrace();
          }
        });
      }
    });
  }

  void _onLevelFailed(int index) {
    setState(() {
      _showNotification = true;
      _notificationTitle = 'Nice try! Let\'s practice again!';
      _notificationEmoji = '💪';
      _notificationColor = Colors.orange.shade400;
    });

    // Hide notification after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showNotification = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '✨ කෙලින් ඉරි අදිමු ✨',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.purple.shade300],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // disable swipe
                  onPageChanged: (index) {
                    setState(() {
                      _currentTraceIndex = index;
                    });
                  },
                  itemCount: tracePaths.length,
                  itemBuilder: (context, index) {
                    return TracingCanvas(
                      key: _canvasKeys[index],
                      tracePath: tracePaths[index],
                      onCompleted: () => _onLevelCompleted(index),
                      onFailed: () => _onLevelFailed(index),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Level ${_currentTraceIndex + 1} of ${tracePaths.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _currentTraceIndex > 0
                              ? _previousTrace
                              : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('පෙර'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _resetCurrentTrace,
                          icon: const Icon(Icons.refresh),
                          label: const Text('මකන්න'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _currentTraceIndex < tracePaths.length - 1
                              ? _nextTrace
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('ඉදිරියට'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Large notification card overlay
          if (_showNotification)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Card(
                  elevation: 20,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _notificationColor,
                          _notificationColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _notificationEmoji,
                          style: const TextStyle(fontSize: 80),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _notificationTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- MODELS ----------------

class DotPoint {
  final Offset position;
  bool isTraced;

  DotPoint({required this.position, this.isTraced = false});
}

class SamplePoint {
  final Offset position;
  bool isCovered;

  SamplePoint({required this.position, this.isCovered = false});
}

enum PathType { straight, wave, curve, zigzag }

class TracePath {
  final String name;
  final PathType type;

  final List<DotPoint> dots; // visible big dots
  final List<SamplePoint> samples; // hidden dense samples
  double pathLength;

  TracePath({required this.name, required this.type})
    : dots = [],
      samples = [],
      pathLength = 0.0;
}

// ---------------- TRACING CANVAS ----------------

class TracingCanvas extends StatefulWidget {
  final TracePath tracePath;
  final VoidCallback? onCompleted;
  final VoidCallback? onFailed;

  const TracingCanvas({
    Key? key,
    required this.tracePath,
    this.onCompleted,
    this.onFailed,
  }) : super(key: key);

  @override
  State<TracingCanvas> createState() => _TracingCanvasState();
}

class _TracingCanvasState extends State<TracingCanvas> {
  final List<List<Offset>> strokes = [];
  List<Offset> currentStroke = [];
  bool _alreadyCompleted = false;

  void clearCanvas() {
    setState(() {
      strokes.clear();
      currentStroke.clear();
      _alreadyCompleted = false;
      for (final d in widget.tracePath.dots) {
        d.isTraced = false;
      }
      for (final s in widget.tracePath.samples) {
        s.isCovered = false;
      }
    });
  }

  void _updateDotTracing(Offset point) {
    const dotRadiusThreshold = 25.0; // slightly larger than visual radius
    for (final dot in widget.tracePath.dots) {
      if (!dot.isTraced &&
          (dot.position - point).distance <= dotRadiusThreshold) {
        dot.isTraced = true;
      }
    }
  }

  void _updateSampleCoverage(Offset point) {
    const sampleCoverRadius = 12.0; // small hidden dot radius
    for (final sample in widget.tracePath.samples) {
      if (!sample.isCovered &&
          (sample.position - point).distance <= sampleCoverRadius) {
        sample.isCovered = true;
      }
    }
  }

  double _totalStrokeLength() {
    double total = 0.0;
    final allStrokes = <List<Offset>>[
      ...strokes,
      if (currentStroke.isNotEmpty) currentStroke,
    ];

    for (final stroke in allStrokes) {
      for (int i = 1; i < stroke.length; i++) {
        total += (stroke[i] - stroke[i - 1]).distance;
      }
    }
    return total;
  }

  bool _isTraceComplete() {
    final samples = widget.tracePath.samples;
    if (samples.isEmpty || widget.tracePath.pathLength <= 0) {
      return false;
    }

    // 1) Coverage of ideal path
    final coveredCount = samples.where((s) => s.isCovered).length;
    final coverage = coveredCount / samples.length;

    const coverageThreshold = 0.8; // 80% of samples must be covered

    // 2) Off-path ratio
    final allPoints = <Offset>[];
    for (final stroke in strokes) {
      allPoints.addAll(stroke);
    }
    allPoints.addAll(currentStroke);

    if (allPoints.isEmpty) return false;

    const offPathLimit = 25.0; // px from nearest sample
    int offPathCount = 0;

    for (final p in allPoints) {
      double minDist = double.infinity;
      for (final s in samples) {
        final d = (p - s.position).distance;
        if (d < minDist) minDist = d;
      }
      if (minDist > offPathLimit) {
        offPathCount++;
      }
    }

    final offPathRatio = offPathCount / allPoints.length;
    const maxOffPathRatio = 0.25; // at most 25% points far away

    // 3) Stroke length vs path length
    final strokeLength = _totalStrokeLength();
    const minStrokeFraction = 0.6; // must draw at least 60% of path
    const maxStrokeFraction = 1.1; // must NOT exceed 110% of path

    final longEnough =
        strokeLength >= widget.tracePath.pathLength * minStrokeFraction;
    final notTooLong =
        strokeLength <= widget.tracePath.pathLength * maxStrokeFraction;

    final enoughCoverage = coverage >= coverageThreshold;
    final fewOffPath = offPathRatio <= maxOffPathRatio;

    return enoughCoverage && fewOffPath && longEnough && notTooLong;
  }

  void _handlePoint(Offset point) {
    _updateDotTracing(point); // for visual feedback
    _updateSampleCoverage(point); // for accuracy
  }

  void _evaluateAttempt() {
    if (_alreadyCompleted) return;

    if (_isTraceComplete()) {
      _alreadyCompleted = true;
      widget.onCompleted?.call();
    } else {
      // Treat as real attempt only if stroke is not tiny
      final strokeLength = _totalStrokeLength();
      if (strokeLength >= widget.tracePath.pathLength * 0.3) {
        widget.onFailed?.call();
        clearCanvas(); // reset level (dots + trace lines)
      }
    }
  }

  @override
  void didUpdateWidget(TracingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tracePath.type != widget.tracePath.type) {
      strokes.clear();
      currentStroke.clear();
      _alreadyCompleted = false;
      widget.tracePath.dots.clear();
      widget.tracePath.samples.clear();
      widget.tracePath.pathLength = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
            Colors.pink.shade50,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Bottom: guide line + visible dots + arrows
          CustomPaint(
            painter: GuideLinePainter(tracePath: widget.tracePath),
            child: Container(),
          ),
          // Top: user drawing
          GestureDetector(
            onPanStart: (details) {
              final p = details.localPosition;
              setState(() {
                currentStroke = [p];
                _handlePoint(p);
              });
            },
            onPanUpdate: (details) {
              final p = details.localPosition;
              setState(() {
                currentStroke.add(p);
                _handlePoint(p);
              });
            },
            onPanEnd: (details) {
              setState(() {
                if (currentStroke.isNotEmpty) {
                  strokes.add(List.from(currentStroke));
                  currentStroke.clear();
                }
              });
              _evaluateAttempt(); // check pass/fail after stroke ends
            },
            child: CustomPaint(
              painter: UserDrawingPainter(
                strokes: strokes,
                currentStroke: currentStroke,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- GUIDE LINE PAINTER (arrows between dots) ----------------

class GuideLinePainter extends CustomPainter {
  final TracePath tracePath;

  GuideLinePainter({required this.tracePath});

  @override
  void paint(Canvas canvas, Size size) {
    final dashedLinePaint = Paint()
      ..color = Colors.blue.shade200
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = _generatePath(size);

    // 1) Dashed path
    _drawDashedPath(canvas, path, dashedLinePaint);

    // 2) Prepare dots, samples, path length (if not already)
    _ensurePathData(path);

    // 3) Draw visible guide dots
    _drawDots(canvas);

    // 4) Draw arrows between dots (direction from dot[i] -> dot[i+1])
    _drawArrowsBetweenDots(canvas);
  }

  Path _generatePath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    switch (tracePath.type) {
      case PathType.straight:
        path.moveTo(centerX, 100);
        path.lineTo(centerX, size.height - 100);
        break;

      case PathType.wave:
        // centered, 2 cycles
        final startY = 100.0;
        final endY = size.height - 100;
        final baseX = centerX;
        final waveAmplitude = 60.0;

        path.moveTo(baseX, startY);

        for (double y = startY; y <= endY; y += 5) {
          final progress = (y - startY) / (endY - startY);
          final x = baseX + waveAmplitude * Math.sin(progress * 4 * Math.pi);
          path.lineTo(x, y);
        }
        break;

      case PathType.curve:
        path.moveTo(80, centerY);
        path.quadraticBezierTo(centerX, 100, size.width - 80, centerY);
        break;

      case PathType.zigzag:
        final stepHeight = (size.height - 200) / 5;
        path.moveTo(80, 100);
        for (int i = 0; i < 5; i++) {
          final x = (i % 2 == 0) ? size.width - 80 : 80.0;
          final y = 100 + (i + 1) * stepHeight;
          path.lineTo(x, y);
        }
        break;
    }

    return path;
  }

  void _ensurePathData(Path path) {
    if (tracePath.pathLength > 0 &&
        tracePath.samples.isNotEmpty &&
        tracePath.dots.isNotEmpty) {
      return;
    }

    tracePath.pathLength = 0.0;
    tracePath.dots.clear();
    tracePath.samples.clear();

    int dotCount;
    switch (tracePath.type) {
      case PathType.straight:
        dotCount = 5;
        break;
      case PathType.wave:
        dotCount = 6;
        break;
      case PathType.curve:
        dotCount = 5;
        break;
      case PathType.zigzag:
        dotCount = 11;
        break;
    }

    const double sampleSpacing = 8.0; // dense hidden samples

    final metrics = path.computeMetrics();
    for (var metric in metrics) {
      tracePath.pathLength += metric.length;

      // visible dots – evenly spaced along the metric
      final pathLength = metric.length;
      final spacing = pathLength / (dotCount - 1);

      for (int i = 0; i < dotCount; i++) {
        final distance = i * spacing;
        final pos = metric.getTangentForOffset(distance);
        if (pos != null) {
          tracePath.dots.add(DotPoint(position: pos.position));
        }
      }

      // hidden samples – dense
      for (double d = 0; d <= metric.length; d += sampleSpacing) {
        final pos = metric.getTangentForOffset(d);
        if (pos != null) {
          tracePath.samples.add(SamplePoint(position: pos.position));
        }
      }
    }
  }

  void _drawDots(Canvas canvas) {
    for (final dot in tracePath.dots) {
      final paint = Paint()
        ..color = dot.isTraced ? Colors.green : Colors.grey.shade400
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dot.position, 20, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 8.0;
    final metrics = path.computeMetrics();

    for (var metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final start = metric.getTangentForOffset(distance)?.position;
        final end = metric
            .getTangentForOffset(
              (distance + dashWidth).clamp(0.0, metric.length),
            )
            ?.position;

        if (start != null && end != null) {
          canvas.drawLine(start, end, paint);
        }

        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawArrowsBetweenDots(Canvas canvas) {
    if (tracePath.dots.length < 2) return;

    final arrowPaint = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.fill;

    const double arrowLength = 18.0;
    const double arrowWidth = 10.0;

    for (int i = 0; i < tracePath.dots.length - 1; i++) {
      final from = tracePath.dots[i].position;
      final to = tracePath.dots[i + 1].position;

      final dir = to - from;
      final angle = Math.atan2(dir.dy, dir.dx);

      final tip = to;

      final back =
          tip -
          Offset(Math.cos(angle) * arrowLength, Math.sin(angle) * arrowLength);

      final ortho = Offset(-Math.sin(angle), Math.cos(angle));
      final p1 = back + ortho * (arrowWidth / 2);
      final p2 = back - ortho * (arrowWidth / 2);

      final arrowPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(GuideLinePainter oldDelegate) => true;
}

// ---------------- USER DRAWING PAINTER ----------------

class UserDrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  UserDrawingPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawCircle(points[0], 5, paint);
      return;
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(UserDrawingPainter oldDelegate) => true;
}
