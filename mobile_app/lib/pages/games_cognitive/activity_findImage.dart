import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
// Add this import assuming the dashboard screen is in the same lib directory
import '../dashboard/cognative_dashboard_screen.dart';

/* =========================
   APP ROOT
   ========================= */
class PuzzleApp extends StatelessWidget {
  const PuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PuzzleScreen(),
    );
  }
}

/* =========================
   GAME SCREEN
   ========================= */
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  /* ---- IMAGE PLAYLIST ---- */
  final List<String> imagePool = [
    "assets/images/cognitive/monkey.png",
    "assets/images/cognitive/panda.png",
    "assets/images/cognitive/dog.png",
    "assets/images/cognitive/cat.png",
  ];

  late List<String> _playlist;
  int _index = 0;

  String get currentImage => _playlist[_index];

  /* ---- PIECES ---- */
  List<_Piece> pieces = [];

  @override
  void initState() {
    super.initState();
    _reshuffle();
  }

  void _reshuffle() {
    _playlist = List<String>.from(imagePool)..shuffle();
    _index = 0;
  }

  void _buildPieces(Size size) {
    final paths = Voronoi.generate(
      rect: Offset.zero & size,
      count: 16,
      seed: DateTime.now().millisecondsSinceEpoch,
    );
    pieces = paths.map((p) => _Piece(path: p)).toList();
  }

  void _nextImage() {
    setState(() {
      _index++;
      if (_index >= _playlist.length) {
        _reshuffle();
      }
      pieces.clear();
    });
  }

  void _onTap(Offset pos) {
    for (int i = pieces.length - 1; i >= 0; i--) {
      if (!pieces[i].removed && pieces[i].path.contains(pos)) {
        setState(() {
          pieces[i].removed = true;
        });
        break;
      }
    }
  }

  bool get completed => pieces.isNotEmpty && pieces.every((p) => p.removed);

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2EAA3A);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CognitiveDashboardScreen()),  // Assuming the class name is CognitiveDashboardScreen
          ),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          tooltip: "Back",
        ),
        title: const Text(
          "රූපය හොයමු",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        // same right-side spacing like your first code (SizedBox width 48)
        actions: const [SizedBox(width: 48)],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);

          if (pieces.isEmpty) {
            _buildPieces(size);
          }

          return Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(currentImage, fit: BoxFit.cover),
                    GestureDetector(
                      onTapDown: (d) => _onTap(d.localPosition),
                      child: CustomPaint(painter: PiecePainter(pieces)),
                    ),
                    if (completed)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 12,
                                offset: Offset(0, 6),
                                color: Colors.black26,
                              ),
                            ],
                          ),
                          child: const Text(
                            "🎉 නියමයි! 🎉 ",
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                color: green,
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _btn("අලුත්", () {
                      setState(() => pieces.clear());
                    }),
                    _btn("ඉදිරියට", _nextImage),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const StadiumBorder(),
      ),
      child: Text(text),
    );
  }
}

/* =========================
   PIECE MODEL
   ========================= */
class _Piece {
  final Path path;
  bool removed = false;
  _Piece({required this.path});
}

/* =========================
   PAINTER
   ========================= */
class PiecePainter extends CustomPainter {
  final List<_Piece> pieces;
  PiecePainter(this.pieces);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = const Color(0xFFDDE4DD)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final p in pieces) {
      if (!p.removed) {
        canvas.drawPath(p.path, fill);
        canvas.drawPath(p.path, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

/* =========================
   PERFECT VORONOI TILING
   ========================= */
class Voronoi {
  static List<Path> generate({
    required Rect rect,
    required int count,
    required int seed,
  }) {
    final rnd = Random(seed);

    List<Offset> sites = List.generate(
      count,
      (_) => Offset(
        rect.left + rnd.nextDouble() * rect.width,
        rect.top + rnd.nextDouble() * rect.height,
      ),
    );

    final cells = _cells(rect, sites);
    return cells
        .where((c) => c.length >= 3)
        .map((c) => Path()..addPolygon(c, true))
        .toList();
  }

  static List<List<Offset>> _cells(Rect rect, List<Offset> sites) {
    final box = [
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
    ];

    return List.generate(sites.length, (i) {
      var poly = List<Offset>.from(box);
      for (int j = 0; j < sites.length; j++) {
        if (i == j) continue;
        poly = _clip(poly, sites[i], sites[j]);
        if (poly.isEmpty) break;
      }
      return poly;
    });
  }

  static List<Offset> _clip(List<Offset> poly, Offset a, Offset b) {
    final n = b - a;
    final c = (b.dx * b.dx + b.dy * b.dy - a.dx * a.dx - a.dy * a.dy) / 2;

    bool inside(Offset p) => n.dx * p.dx + n.dy * p.dy <= c;

    Offset intersect(Offset p1, Offset p2) {
      final d = p2 - p1;
      final t =
          (c - (n.dx * p1.dx + n.dy * p1.dy)) / (n.dx * d.dx + n.dy * d.dy);
      return p1 + d * t;
    }

    final out = <Offset>[];
    for (int i = 0; i < poly.length; i++) {
      final curr = poly[i];
      final prev = poly[(i - 1 + poly.length) % poly.length];
      final currIn = inside(curr);
      final prevIn = inside(prev);

      if (currIn && prevIn) out.add(curr);
      if (prevIn && !currIn) out.add(intersect(prev, curr));
      if (!prevIn && currIn) {
        out.add(intersect(prev, curr));
        out.add(curr);
      }
    }
    return out;
  }
}