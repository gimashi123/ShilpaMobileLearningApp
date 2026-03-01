import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:mobile_app/pages/games_cognitive/cognitive_game_loading_screen.dart';
import 'find_image_hand_hint_overlay.dart';

/* =========================
   APP ROOT
   ========================= */
class PuzzleApp extends StatelessWidget {
  const PuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const PuzzleScreen();
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
  late final ConfettiController _confettiController;
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _rewardPlayed = false;
  bool _autoAdvancing = false;
  Timer? _inactivityTimer;
  Timer? _hintVisibleTimer;
  bool _showHandHint = false;

  // Attempt metrics
  DateTime? _attemptStartedAt;
  DateTime? _attemptCompletedAt;
  DateTime? _lastTapAt;
  int _totalTaps = 0;
  int _piecesRemovedCount = 0;
  Duration _sumInterTapTime = Duration.zero;
  int _interTapCount = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 900),
    );
    _reshuffle();
    _resetHintInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _hintVisibleTimer?.cancel();
    _sfxPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _reshuffle() {
    _playlist = List<String>.from(imagePool)..shuffle();
    _index = 0;
  }

  void _resetHintInactivityTimer() {
    _inactivityTimer?.cancel();
    _hintVisibleTimer?.cancel();
    if (_showHandHint) {
      setState(() => _showHandHint = false);
    }
    _inactivityTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || _autoAdvancing) return;
      setState(() => _showHandHint = true);
      _hintVisibleTimer = Timer(const Duration(seconds: 15), () {
        if (!mounted) return;
        setState(() => _showHandHint = false);
      });
    });
  }

  void _buildPieces(Size size) {
    final paths = Voronoi.generate(
      rect: Offset.zero & size,
      count: 16,
      seed: DateTime.now().millisecondsSinceEpoch,
    );
    pieces = paths.map((p) => _Piece(path: p)).toList();
    _resetAttemptMetrics();
  }

  void _resetAttemptMetrics() {
    _attemptStartedAt = DateTime.now();
    _attemptCompletedAt = null;
    _lastTapAt = null;
    _totalTaps = 0;
    _piecesRemovedCount = 0;
    _sumInterTapTime = Duration.zero;
    _interTapCount = 0;
  }

  void _printAttemptStatsToTerminal({required String event}) {
    final completionMs =
        (_attemptStartedAt != null && _attemptCompletedAt != null)
        ? _attemptCompletedAt!.difference(_attemptStartedAt!).inMilliseconds
        : -1;
    final usefulTapRate = _totalTaps == 0
        ? 0.0
        : _piecesRemovedCount / _totalTaps;
    final avgInterTapMs = _interTapCount == 0
        ? 0
        : (_sumInterTapTime.inMilliseconds / _interTapCount).round();

    debugPrint(
      "[FIND_IMAGE_SCORE] event=$event completion_ms=$completionMs total_taps=$_totalTaps pieces_removed=$_piecesRemovedCount useful_tap_rate=${usefulTapRate.toStringAsFixed(3)} avg_inter_tap_ms=$avgInterTapMs",
    );
  }

  void _nextImage() {
    _printAttemptStatsToTerminal(event: 'next_image_before_reset');
    unawaited(_sfxPlayer.stop());
    setState(() {
      _index++;
      if (_index >= _playlist.length) {
        _reshuffle();
      }
      pieces.clear();
      _rewardPlayed = false;
      _autoAdvancing = false;
    });
    _confettiController.stop();
    _resetHintInactivityTimer();
  }

  void _onTap(Offset pos) {
    _resetHintInactivityTimer();
    final tapTime = DateTime.now();
    _totalTaps++;
    if (_lastTapAt != null) {
      _sumInterTapTime += tapTime.difference(_lastTapAt!);
      _interTapCount++;
    }
    _lastTapAt = tapTime;

    for (int i = pieces.length - 1; i >= 0; i--) {
      if (!pieces[i].removed && pieces[i].path.contains(pos)) {
        setState(() {
          pieces[i].removed = true;
          _piecesRemovedCount++;
        });
        if (completed) {
          _attemptCompletedAt = tapTime;
          _printAttemptStatsToTerminal(event: 'attempt_completed');
          _playRewardAnimation();
        }
        break;
      }
    }
  }

  bool get completed => pieces.isNotEmpty && pieces.every((p) => p.removed);

  Offset? get _hintTargetPosition {
    for (final piece in pieces) {
      if (!piece.removed) {
        return piece.path.getBounds().center;
      }
    }
    return null;
  }

  Future<void> _goDashboard() async {
    _inactivityTimer?.cancel();
    _hintVisibleTimer?.cancel();
    _printAttemptStatsToTerminal(event: 'back_to_home');
    await _sfxPlayer.stop();
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/home_cognitive', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2EAA3A);

    return Listener(
      onPointerDown: (_) => _resetHintInactivityTimer(),
      onPointerMove: (_) => _resetHintInactivityTimer(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: green,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: _goDashboard,
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
          // actions: [
          //   IconButton(
          //     onPressed: () => _printAttemptStatsToTerminal(event: 'manual_view'),
          //     icon: const Icon(Icons.terminal, color: Colors.black),
          //     tooltip: "Terminal score",
          //   ),
          // ],
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
                        onTapDown: _autoAdvancing
                            ? null
                            : (d) => _onTap(d.localPosition),
                        child: CustomPaint(painter: PiecePainter(pieces)),
                      ),
                      FindImageHandHintOverlay(
                        isVisible: _showHandHint,
                        targetPosition: _hintTargetPosition,
                      ),
                      if (completed) ...[
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
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
                              "⭐\n🎉 නියමයි! 🎉",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: ConfettiWidget(
                            confettiController: _confettiController,
                            blastDirectionality: BlastDirectionality.explosive,
                            numberOfParticles: 16,
                            emissionFrequency: 0.12,
                            maxBlastForce: 18,
                            minBlastForce: 10,
                            gravity: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  color: green,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // _btn("අලුත්", _autoAdvancing ? null : () {
                      //   _printAttemptStatsToTerminal(
                      //     event: 'new_round_before_reset',
                      //   );
                      //   unawaited(_sfxPlayer.stop());
                      //   setState(() {
                      //     pieces.clear();
                      //     _rewardPlayed = false;
                      //     _autoAdvancing = false;
                      //   });
                      //   _confettiController.stop();
                      // }),
                      _btn("Home", _goDashboard),
                      _btn("ඉදිරියට", _autoAdvancing ? null : _nextImage),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _btn(String text, VoidCallback? onTap) {
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

  Future<void> _playRewardAnimation() async {
    if (_rewardPlayed || _autoAdvancing) return;
    _rewardPlayed = true;
    _autoAdvancing = true;
    _inactivityTimer?.cancel();
    _hintVisibleTimer?.cancel();
    if (_showHandHint) {
      setState(() => _showHandHint = false);
    }
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource("sounds/cognitive/cheers.mp3"));
    _confettiController.play();
    await Future.delayed(const Duration(milliseconds: 4500));
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CognitiveGameLoadingScreen(
          gameTitle: 'රූප හොයමු',
          autoNavigate: false,
          duration: Duration(seconds: 4),
        ),
      ),
    );
    if (!mounted) return;
    _nextImage();
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
