// ✅ SINGLE FILE (COMPLETE) — fixed lifecycle/setState-after-dispose bugs + fixed syntax errors
// Paste this as: lib/main.dart  (or any single dart file) and run: flutter run
//
// Notes:
// - Make sure you added assets in pubspec.yaml if you want sounds
// - This prints metrics to console AFTER each game AND after all 3 at the end

import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:mobile_app/session/session.dart';
import 'package:mobile_app/services/cognitive.dart';

void main() {
  runApp(const IqGame());
}

enum GameType { shape, color, bubble }

/// =======================
/// Settings (sound default ON)
/// =======================
class AppSettings {
  static const String soundOnKey = 'settings_sound_on';
  static const String hapticsOnKey = 'settings_haptics_on';

  static Future<bool> getSoundOn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(soundOnKey) ?? true;
  }

  static Future<bool> getHapticsOn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(hapticsOnKey) ?? true;
  }
}

/// =======================
/// Sound effects (safe)
/// =======================
class Sfx {
  static final AudioPlayer _p = AudioPlayer();

  static Future<void> _playAsset(String path) async {
    try {
      await _p.stop();
      await _p.play(AssetSource(path));
    } catch (_) {}
  }

  static Future<void> correct(bool enabled) async {
    if (!enabled) return;
    await _playAsset('sounds/cognitive/correct.mp3');
  }

  static Future<void> wrong(bool enabled) async {
    if (!enabled) return;
    await _playAsset('sounds/cognitive/wrong.mp3');
  }
}

/// =======================
/// Haptics (safe)
/// =======================
Future<void> hapticCorrect(bool enabled) async {
  if (!enabled) return;
  try {
    await HapticFeedback.lightImpact();
  } catch (_) {}
}

Future<void> hapticWrong(bool enabled) async {
  if (!enabled) return;
  try {
    await HapticFeedback.vibrate();
  } catch (_) {}
}

/// =======================
/// Metrics (for ML inputs later)
/// =======================
class GameMetrics {
  // general
  int totalTouches = 0;
  int validTaps = 0;
  int hintsUsed = 0;

  // shape/color
  int correct = 0;
  int wrong = 0;
  int wrongStreak = 0;
  int wrongStreakMax = 0;
  DateTime? currentRoundStartedAt;
  DateTime? firstCorrectAt;
  final List<double> reactionTimesSec = [];

  // color post-hint
  bool hintArmed = false;
  int postHintCorrect = 0;

  // bubbles
  // int poppedCount = 0;
  int missedBubbles = 0;
  final List<DateTime> popTimes = [];

  void resetForShapeOrColor() {
    totalTouches = 0;
    validTaps = 0;
    hintsUsed = 0;

    correct = 0;
    wrong = 0;
    wrongStreak = 0;
    wrongStreakMax = 0;

    reactionTimesSec.clear();
    currentRoundStartedAt = null;
    firstCorrectAt = null;

    hintArmed = false;
    postHintCorrect = 0;
  }

  void resetForBubbles() {
    totalTouches = 0;
    validTaps = 0;
    hintsUsed = 0;

    // poppedCount = 0;
    missedBubbles = 0;
    popTimes.clear();
  }

  Map<String, dynamic> toPrefixedJson(GameType type) {
    double avg(List<double> xs) =>
        xs.isEmpty ? 0.0 : xs.reduce((a, b) => a + b) / xs.length;

    double avgTimeBetweenPopsSec() {
      if (popTimes.length < 2) return 0.0;
      double total = 0.0;
      for (int i = 1; i < popTimes.length; i++) {
        total +=
            popTimes[i].difference(popTimes[i - 1]).inMilliseconds / 1000.0;
      }
      return total / (popTimes.length - 1);
    }

    final String prefix = (type == GameType.shape)
        ? 'shape'
        : (type == GameType.color)
        ? 'color'
        : 'bubble';

    final m = <String, dynamic>{
      '${prefix}TotalTouches': totalTouches,
      '${prefix}ValidTaps': validTaps,
      '${prefix}HintsUsed': hintsUsed,
    };

    if (type == GameType.shape || type == GameType.color) {
      m.addAll({
        '${prefix}Correct': correct,
        '${prefix}Wrong': wrong,
        '${prefix}WrongStreakMax': wrongStreakMax,
        '${prefix}AvgReactionTimeSec': avg(reactionTimesSec),
      });
    }

    if (type == GameType.color) {
      m.addAll({'${prefix}PostHintCorrect': postHintCorrect});
    }

    if (type == GameType.bubble) {
      m.addAll({
        // '${prefix}_poppedCount': poppedCount,
        '${prefix}MissedBubbles': missedBubbles,
        '${prefix}AvgTimeBetweenPopsSec': avgTimeBetweenPopsSec(),
      });
    }

    return m;
  }

  void debugPrintMetrics(String label, GameType type) {
    // debugPrint('===== $label METRICS =====');
    toPrefixedJson(type).forEach((k, v) => debugPrint('$k: $v'));
    // debugPrint('==========================');
  }
}

/// =======================================================
/// Option C: BaseTimedGameState
/// =======================================================
abstract class BaseTimedGameState<T extends StatefulWidget> extends State<T> {
  int score = 0;
  int timeLeft = 50;
  bool gameActive = false;
  bool isGameOver = false;

  bool soundOn = true;
  bool hapticsOn = true;

  Timer? countdownTimer;

  GameMetrics get metrics;
  String get firstPlayKey;

  GameType get gameType;

  int get gameDurationSeconds => 50;

  void resetMetrics();
  void startFirstRound();
  void showFirstTimeHint();
  void disposeGameSpecific();
  void onGameComplete(int finalScore);

  String get endDialogTitle;
  String get endDialogWaitingText;

  @override
  void initState() {
    super.initState();
    _loadSettingsThenStart();
  }

  Future<void> _loadSettingsThenStart() async {
    soundOn = await AppSettings.getSoundOn();
    hapticsOn = await AppSettings.getHapticsOn();
    if (!mounted) return;
    await startGameWithFirstPlayHint();
  }

  Future<void> startGameWithFirstPlayHint() async {
    final prefs = await SharedPreferences.getInstance();
    final firstDone = prefs.getBool(firstPlayKey) ?? false;

    startGame();

    if (!firstDone) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted && gameActive && !isGameOver) {
          showFirstTimeHint();
        }
      });
      await prefs.setBool(firstPlayKey, true);
    }
  }

  void startGame() {
    setState(() {
      score = 0;
      timeLeft = gameDurationSeconds;
      gameActive = true;
      isGameOver = false;
    });

    resetMetrics();
    startFirstRound();
    _startCountdown();
  }

  void _startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (!gameActive || isGameOver) return;

      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          t.cancel();
          endGame();
        }
      });
    });
  }

  @mustCallSuper
  void endGame() {
    countdownTimer?.cancel();

    if (!mounted) return;
    setState(() {
      gameActive = false;
      isGameOver = true;
    });

    _showEndDialogThenNext();
  }

  Future<void> _showEndDialogThenNext() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(endDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('මගේ ලකුණු:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(
              endDialogWaitingText,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    // ✅ close dialog first (avoids using a dead context later)
    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {}

    // ✅ print metrics AFTER dialog close
    metrics.debugPrintMetrics(firstPlayKey, gameType);

    if (!mounted) return;
    onGameComplete(score);
  }

  Widget wrapWithTouchCounter({
    required Gradient gradient,
    required Widget child,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (gameActive && !isGameOver) {
          metrics.totalTouches += 1;
        }
      },
      child: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    disposeGameSpecific();
    super.dispose();
  }
}

/// =======================================================
/// App root
/// =======================================================
class IqGame extends StatelessWidget {
  const IqGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Menu();
  }
}

/// =====================================
/// Menu
/// =====================================
class Menu extends StatelessWidget {
  const Menu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade300, Colors.blue.shade300],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;

                final contentMaxW = w < 600 ? w * 0.88 : 520.0;
                final btnH = (h * 0.11).clamp(64.0, 90.0);

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxW),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GameButton(
                            title: '🚀 පටන් ගමු',
                            color: Colors.orange,
                            height: btnH,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SequentialGameFlow(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GameButton(
                            title: '📊 ලකුණු බලමු',
                            color: Colors.pink,
                            height: btnH,
                            onTap: () {
                              Navigator.pushNamed(context, '/activity_iqScore');
                            },
                          ),
                          const SizedBox(height: 16),

                          GameButton(
                            title: 'Dashboard',
                            color: Colors.blue,
                            height: btnH,
                            onTap: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamedAndRemoveUntil(
                                '/home_cognitive',
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ScoreHistoryScreen extends StatelessWidget {
  const ScoreHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score History'),
        backgroundColor: Colors.pink,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink.shade100, Colors.purple.shade100],
          ),
        ),
        child: const Center(
          child: Text(
            'ලකුණු ඉතිහාස විශේෂාංගය ළඟදීම එනවා!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// =====================================
/// Sequential Flow
/// =====================================
class SequentialGameFlow extends StatefulWidget {
  const SequentialGameFlow({Key? key}) : super(key: key);

  @override
  State<SequentialGameFlow> createState() => _SequentialGameFlowState();
}

class _SequentialGameFlowState extends State<SequentialGameFlow> {
  // Backend base URL (PC IP + port). Do NOT use localhost on a phone.
  // final String apiBaseUrl = 'http://127.0.0.1:3000';
  late final String studentId;

  int currentGameIndex = 0;
  int shapeGameScore = 0;
  int colorGameScore = 0;
  int popGameScore = 0;
  int totalScore = 0;
  bool isGameSequenceComplete = false;

  final shapeMetrics = GameMetrics();
  final colorMetrics = GameMetrics();
  final popMetrics = GameMetrics();

  Interpreter? _interpreter;
  double _safeDiv(num a, num b) {
    const eps = 1e-6;
    return a.toDouble() / (b.toDouble() + eps);
  }

  Map<String, dynamic> addDerivedFields(Map<String, dynamic> p) {
    // read ints/doubles safely
    double g(String k) {
      final v = p[k];
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return 0.0;
    }

    // ---------- SHAPE ----------
    final sTotal = g('shapeTotalTouches');
    final sValid = g('shapeValidTaps');
    final sCorrect = g('shapeCorrect');
    // final sWrong = g('shapeWrong');
    final sHints = g('shapeHintsUsed');

    final shapeAccuracy = _safeDiv(sCorrect, sValid);
    final shapeIneff = _safeDiv((sTotal - sValid), sTotal);
    final shapeHintRate = _safeDiv(sHints, sCorrect);

    // ---------- COLOR ----------
    final cTotal = g('colorTotalTouches');
    final cValid = g('colorValidTaps');
    final cCorrect = g('colorCorrect');
    // final cWrong = g('colorWrong');
    final cHints = g('colorHintsUsed');
    final cPostHintCorrect = g('colorPostHintCorrect');

    final colorAccuracy = _safeDiv(cCorrect, cValid);
    final colorIneff = _safeDiv((cTotal - cValid), cTotal);
    final colorHintRate = _safeDiv(cHints, cCorrect);
    final colorPostHintRate = _safeDiv(cPostHintCorrect, cCorrect);

    // ---------- BUBBLE ----------
    final bTotal = g('bubbleTotalTouches');
    final bValid = g('bubbleValidTaps');
    final bMiss = g('bubbleMissedBubbles');

    final bubbleValidRate = _safeDiv(bValid, bTotal);
    final bubbleMissRate = _safeDiv(bMiss, (bValid + bMiss));

    // return merged payload
    return {
      ...p,

      // shape derived
      'shapeAccuracy': shapeAccuracy,
      'shapeInefficiency': shapeIneff,
      'shapeHintRate': shapeHintRate,

      // color derived
      'colorAccuracy': colorAccuracy,
      'colorInefficiency': colorIneff,
      'colorHintRate': colorHintRate,
      'colorPostHintRate': colorPostHintRate,

      // bubble derived
      'bubbleValidRate': bubbleValidRate,
      'bubbleMissRate': bubbleMissRate,
    };
  }

  // IMPORTANT: This order must match your training CSV column order.
  final List<String> featureOrder = [
    // ---- your existing 20 raw fields (unchanged) ----
    'shapeTotalTouches',
    'shapeValidTaps',
    'shapeCorrect',
    'shapeWrong',
    'shapeWrongStreakMax',
    'shapeHintsUsed',

    'colorTotalTouches',
    'colorValidTaps',
    'colorCorrect',
    'colorWrong',
    'colorHintsUsed',
    'colorWrongStreakMax',
    'bubbleTotalTouches',
    'bubbleValidTaps',
    'bubbleMissedBubbles',
    'bubbleHintsUsed',
    // 'colorPostHintCorrect',
    'shapeAvgReactionTimeSec',
    'colorAvgReactionTimeSec',

    'bubbleAvgTimeBetweenPopsSec',

    // ---- NEW derived fields (9) ----
    'shapeAccuracy',
    'shapeInefficiency',
    'shapeHintRate',

    'colorAccuracy',
    'colorInefficiency',
    'colorHintRate',
    'colorPostHintRate',

    'bubbleValidRate',
    'bubbleMissRate',
  ];

  Map<String, dynamic> buildModelRowPayload() {
    return {
      ...shapeMetrics.toPrefixedJson(GameType.shape),
      ...colorMetrics.toPrefixedJson(GameType.color),
      ...popMetrics.toPrefixedJson(GameType.bubble),
    };
  }

  // ✅ TFLITE ADDED
  Future<void> _loadTflite() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/lq_model.tflite',
      );
      _interpreter!.allocateTensors(); // ✅ MUST

      debugPrint('✅ TFLite model loaded');

      // Optional: print input/output shapes
      debugPrint(
        'Input shape: ${_interpreter!.getInputTensor(0).shape.toString()}',
      );
      debugPrint(
        'Output shape: ${_interpreter!.getOutputTensor(0).shape.toString()}',
      );
    } catch (e) {
      debugPrint('❌ Failed to load TFLite model: $e');
      _interpreter = null;
    }
  }

  // ✅ TFLITE ADDED
  List<double> _payloadToInput(Map<String, dynamic> payload) {
    return featureOrder.map((k) {
      final v = payload[k];
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return 0.0;
    }).toList();
  }

  // ✅ TFLITE ADDED (assumes 3-class softmax output [1,3])
  Map<String, dynamic> predictFromPayload(Map<String, dynamic> payload) {
    if (_interpreter == null) {
      return {'ok': false, 'error': 'TFLite not loaded'};
    }

    // IMPORTANT: make sure you did this once after loading the model:
    // _interpreter!.allocateTensors();

    final inTensor = _interpreter!.getInputTensor(0);
    final outTensor = _interpreter!.getOutputTensor(0);

    final inShape = inTensor.shape; // expected [1, 28]
    final outShape = outTensor.shape; // expected [1, 3]

    final inputList = _payloadToInput(payload);
    final featureCount = (inShape.length >= 2) ? inShape[1] : inputList.length;

    if (inputList.length != featureCount) {
      return {
        'ok': false,
        'error':
            'Feature count mismatch. Model expects $featureCount but you provide ${inputList.length}. Fix featureOrder.',
      };
    }

    // ✅ typed input
    final inputBuffer = Float32List.fromList(
      inputList.map((e) => e.toDouble()).toList(),
    );

    // ✅ shape input to [1, N]
    final inputTensor = inputBuffer.reshape([1, featureCount]);

    // ✅ run with a standard Dart nested-list output holder
    // (even if this doesn’t fill, we will read using copyTo())
    final outputHolder = List.generate(
      outShape[0],
      (_) => List.filled(outShape[1], 0.0),
    );

    _interpreter!.run(inputTensor, outputHolder);

    // ✅ IMPORTANT: read output directly from tensor memory
    final outRead = List.generate(
      outShape[0],
      (_) => List.filled(outShape[1], 0.0),
    );
    outTensor.copyTo(outRead);

    final probs = List<double>.from(outRead[0]);
    final probsSum = probs.fold<double>(0.0, (a, b) => a + b);

    // argmax
    int best = 0;
    double bestVal = probs.isNotEmpty ? probs[0] : 0.0;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > bestVal) {
        bestVal = probs[i];
        best = i;
      }
    }

    const labels = ['below', 'average', 'above'];
    final predLabel = (best >= 0 && best < labels.length)
        ? labels[best]
        : 'unknown';

    return {
      'ok': true,
      'type': 'multiclass',
      'inType': inTensor.type.toString(),
      'outType': outTensor.type.toString(),
      'inShape': inShape,
      'outShape': outShape,
      'probs': probs,
      'probsSum': probsSum,
      'predIndex': best,
      'predLabel': predLabel,
      'predScore': bestVal,
    };
  }

  late final List<Widget> games;

  @override
  void initState() {
    super.initState();
    studentId = Session.userId ?? 'Student';
    _loadTflite(); // ✅ TFLITE ADDED
    games = [
      ShapeMatchGame(
        metrics: shapeMetrics,
        onGameComplete: (score) {
          if (!mounted) return;
          setState(() {
            shapeGameScore = score;
            currentGameIndex = 1;
          });
        },
      ),
      ColorMatchGame(
        metrics: colorMetrics,
        onGameComplete: (score) {
          if (!mounted) return;
          setState(() {
            colorGameScore = score;
            currentGameIndex = 2;
          });
        },
      ),
      PopBubblesGame(
        metrics: popMetrics,
        onGameComplete: (score) {
          if (!mounted) return;

          // ✅ update UI first
          setState(() {
            popGameScore = score;
            totalScore = shapeGameScore + colorGameScore + score;
            isGameSequenceComplete = true;
          });

          // ✅ print OUTSIDE setState (prevents weird lifecycle timing)
          shapeMetrics.debugPrintMetrics('shape', GameType.shape);
          colorMetrics.debugPrintMetrics('color', GameType.color);
          popMetrics.debugPrintMetrics('bubble', GameType.bubble);
          final rawPayload = buildModelRowPayload();
          final payload = addDerivedFields(rawPayload);
          debugPrint('===== MODEL PAYLOAD (ONE ROW) =====');
          payload.forEach((k, v) => debugPrint('$k: $v'));
          debugPrint('===================================');

          // ✅ TFLITE ADDED: run model here
          final result = predictFromPayload(payload);

          if (result['ok'] == true) {
            // Fire-and-forget (can't await inside this callback safely)
            unawaited(_saveResultToBackend(payload, result));
          }

          debugPrint('===== MODEL RESULT =====');
          debugPrint(result.toString());
          debugPrint('========================');
        },
      ),
    ];
  }

  @override
  void dispose() {
    // ✅ TFLITE ADDED
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _saveResultToBackend(
    Map<String, dynamic> payload,
    Map<String, dynamic> result,
  ) async {
    await saveLdResultToBackend(
      // baseUrl: apiBaseUrl,
      studentId: studentId,
      features: payload, // ✅ Pass your model payload map here
      shapeGameScore:
          shapeGameScore, // Fixed: Removed quotes, used correct syntax
      colorGameScore: colorGameScore,
      bubbleGameScore:
          popGameScore, // Note: Using popGameScore as the value (assuming it's the variable name in iq.dart)
      totalScore: totalScore,
      probs: List<double>.from(result['probs']),
      predLabel: result['predLabel'] as String,
      predScore: (result['predScore'] as num).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGameSequenceComplete) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade300, Colors.blue.shade300],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '🎉  ඉදිරියට යමු 🎉',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            ScoreCard(
                              title: 'හැඩ ගැලපීමෙන් ලකුණු',
                              score: shapeGameScore,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 14),
                            ScoreCard(
                              title: 'පාට ගැලපීමෙන් ලකුණු',
                              score: colorGameScore,
                              color: Colors.pink,
                            ),
                            const SizedBox(height: 14),
                            ScoreCard(
                              title: 'බෝල පිපිරීමෙන් ලකුණු',
                              score: popGameScore,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 26),
                            Container(
                              width: 320,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    '🏆 මුළු ලකුණු',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$totalScore',
                                    style: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: GameButton(
                                title: '🏠 ආපසු මුලට',
                                color: Colors.purple,
                                onTap: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return games[currentGameIndex];
  }
}

class ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final Color color;

  const ScoreCard({
    Key? key,
    required this.title,
    required this.score,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameButton extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;
  final double? height;

  const GameButton({
    Key? key,
    required this.title,
    required this.color,
    required this.onTap,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final btnH = height ?? 80.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: btnH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =====================================
/// Shape Match Game
/// =====================================
class ShapeMatchGame extends StatefulWidget {
  final GameMetrics metrics;
  final Function(int score) onGameComplete;

  const ShapeMatchGame({
    Key? key,
    required this.metrics,
    required this.onGameComplete,
  }) : super(key: key);

  @override
  State<ShapeMatchGame> createState() => _ShapeMatchGameState();
}

class _ShapeMatchGameState extends BaseTimedGameState<ShapeMatchGame> {
  @override
  GameMetrics get metrics => widget.metrics;

  @override
  String get firstPlayKey => 'shape_first_play_done';

  @override
  GameType get gameType => GameType.shape; // ✅ ADDED

  @override
  String get endDialogTitle => '🎉 හැඩ ගැළපීම සම්පූර්ණයි!';

  @override
  String get endDialogWaitingText => 'පොඩ්ඩක් ඉන්න...';

  @override
  void onGameComplete(int finalScore) => widget.onGameComplete(finalScore);

  String? selectedShape;
  final List<String> shapes = ['circle', 'square', 'triangle', 'rectangle'];

  String targetShape = '';
  String? lastTargetShape;

  int roundKey = 0;
  Color targetCardBg = const Color(0xFFFFF3E0);

  final List<Color> pastelColors = [
    const Color(0xFFFFF3E0),
    const Color(0xFFE3F2FD),
    const Color(0xFFE8F5E9),
    const Color(0xFFFCE4EC),
    const Color(0xFFF3E5F5),
    const Color(0xFFFFFDE7),
  ];

  bool showHint = false;
  Timer? hintBlinkTimer;
  bool hintBlinkOn = false;
  int hintBlinkTicks = 0;

  int wrongStreakLocal = 0;

  @override
  void resetMetrics() {
    metrics.resetForShapeOrColor();
    wrongStreakLocal = 0;
    targetCardBg = pastelColors[0];
  }

  @override
  void startFirstRound() {
    generateNewTarget();
  }

  @override
  void showFirstTimeHint() {
    startHintBlink();
  }

  @override
  void disposeGameSpecific() {
    hintBlinkTimer?.cancel();
  }

  @override
  void endGame() {
    hintBlinkTimer?.cancel();
    super.endGame();
  }

  void toggleHint() {
    if (gameActive && !isGameOver) {
      metrics.hintsUsed += 1;
    }
    startHintBlink();
  }

  void startHintBlink() {
    hintBlinkTimer?.cancel();

    if (!mounted || isGameOver || !gameActive) return;

    setState(() {
      selectedShape = null;
      showHint = true;
      hintBlinkOn = true;
      hintBlinkTicks = 0;
    });

    hintBlinkTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted || isGameOver || !gameActive) {
        t.cancel();
        return;
      }

      setState(() {
        hintBlinkOn = !hintBlinkOn;
        hintBlinkTicks++;
      });

      if (hintBlinkTicks >= 10) {
        t.cancel();
        if (!mounted || isGameOver || !gameActive) return;
        setState(() {
          showHint = false;
          hintBlinkOn = false;
        });
      }
    });
  }

  void generateNewTarget() {
    if (!mounted || isGameOver || !gameActive) return;

    final rnd = Random();
    String next = shapes[rnd.nextInt(shapes.length)];

    if (lastTargetShape != null && shapes.length > 1) {
      while (next == lastTargetShape) {
        next = shapes[rnd.nextInt(shapes.length)];
      }
    }

    hintBlinkTimer?.cancel();
    showHint = false;
    hintBlinkOn = false;

    setState(() {
      lastTargetShape = next;
      targetShape = next;
      selectedShape = null;

      roundKey++;
      targetCardBg = pastelColors[rnd.nextInt(pastelColors.length)];
    });

    metrics.currentRoundStartedAt = DateTime.now();
    HapticFeedback.selectionClick();
  }

  Future<void> checkMatch(String shape) async {
    if (!gameActive || isGameOver) return;

    metrics.validTaps += 1;

    final now = DateTime.now();
    final rs = metrics.currentRoundStartedAt;
    if (rs != null) {
      metrics.reactionTimesSec.add(now.difference(rs).inMilliseconds / 1000.0);
    }

    setState(() {
      selectedShape = shape;
      showHint = false;
      hintBlinkTimer?.cancel();
      hintBlinkOn = false;
    });

    final correct = shape == targetShape;

    if (correct) {
      metrics.correct += 1;
      metrics.firstCorrectAt ??= DateTime.now();

      wrongStreakLocal = 0;
      metrics.wrongStreak = 0;

      await Sfx.correct(soundOn);
      await hapticCorrect(hapticsOn);

      if (!mounted || isGameOver || !gameActive) return;
      setState(() => score += 10);

      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && gameActive && !isGameOver) generateNewTarget();
      });
    } else {
      metrics.wrong += 1;

      wrongStreakLocal++;
      metrics.wrongStreak += 1;
      if (metrics.wrongStreak > metrics.wrongStreakMax) {
        metrics.wrongStreakMax = metrics.wrongStreak;
      }

      await Sfx.wrong(soundOn);
      await hapticWrong(hapticsOn);

      if (wrongStreakLocal >= 3) {
        wrongStreakLocal = 0;
        metrics.wrongStreak = 0;
        startHintBlink();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('හැඩ ගලපමු'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(showHint ? Icons.lightbulb : Icons.lightbulb_outline),
            onPressed: toggleHint,
          ),
        ],
      ),
      body: wrapWithTouchCounter(
        gradient: LinearGradient(
          colors: [Colors.orange.shade100, Colors.yellow.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text('මගේ ලකුණු:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('ඉතිරි කාලය:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$timeLeft',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: timeLeft <= 10 ? Colors.red : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'මේ හැඩය ගලපමු:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 550),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: Container(
                key: ValueKey(roundKey),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: targetCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(100, 100),
                    painter: ShapePainter(targetShape, Colors.blue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final tileW = (c.maxWidth - 20) / 2;
                  final tileH = (c.maxHeight - 20) / 2;
                  final ratio = tileW / tileH;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: ratio,
                    ),
                    itemCount: shapes.length,
                    itemBuilder: (context, index) {
                      final shape = shapes[index];

                      final isSelected = selectedShape == shape;
                      final isCorrect = isSelected && shape == targetShape;
                      final isWrong = isSelected && shape != targetShape;

                      final isHintTarget = showHint && (shape == targetShape);
                      final blinkGreen = isHintTarget && hintBlinkOn;

                      return GestureDetector(
                        onTap: () => checkMatch(shape),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.shade300
                                : isWrong
                                ? Colors.red.shade300
                                : (blinkGreen
                                      ? Colors.green.shade300
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: CustomPaint(
                              size: const Size(80, 80),
                              painter: ShapePainter(
                                shape,
                                (isCorrect || isWrong || blinkGreen)
                                    ? Colors.white
                                    : Colors.purple,
                              ),
                            ),
                          ),
                        ),
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
}

class ShapePainter extends CustomPainter {
  final String shape;
  final Color color;

  ShapePainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    switch (shape) {
      case 'circle':
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          size.width / 2,
          paint,
        );
        break;
      case 'square':
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
      case 'triangle':
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'rectangle':
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.2, 0, size.width * 0.6, size.height),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// =====================================
/// Color Match Game
/// =====================================
class ColorMatchGame extends StatefulWidget {
  final GameMetrics metrics;
  final Function(int score) onGameComplete;

  const ColorMatchGame({
    Key? key,
    required this.metrics,
    required this.onGameComplete,
  }) : super(key: key);

  @override
  State<ColorMatchGame> createState() => _ColorMatchGameState();
}

class _ColorMatchGameState extends BaseTimedGameState<ColorMatchGame> {
  @override
  GameMetrics get metrics => widget.metrics;

  @override
  String get firstPlayKey => 'color_first_play_done';

  @override
  GameType get gameType => GameType.color; // ✅ ADDED

  @override
  String get endDialogTitle => '🎉 පාට ගැලපීම සම්පුර්ණයි!';

  @override
  String get endDialogWaitingText => 'පොඩ්ඩක් ඉන්න...';

  @override
  void onGameComplete(int finalScore) => widget.onGameComplete(finalScore);

  Color? selectedColor;

  final Map<String, Color> colorOptions = {
    'රතු': const Color(0xFFDC143C),
    'ලා නිල්': const Color(0xFF87CEEB),
    'කොල': const Color(0xFF00FF00),
    'කහ': const Color(0xFFFFFF00),
  };

  String targetColorName = '';
  Color targetColor = Colors.white;
  Color? lastTargetColor;

  int roundKey = 0;
  Color targetCardBg = const Color(0xFFE3F2FD);

  final List<Color> pastelColors = [
    const Color(0xFFFFF3E0),
    const Color(0xFFE3F2FD),
    const Color(0xFFE8F5E9),
    const Color(0xFFFCE4EC),
    const Color(0xFFF3E5F5),
    const Color(0xFFFFFDE7),
  ];

  bool showHint = false;
  Timer? hintBlinkTimer;
  bool hintBlinkOn = false;
  int hintBlinkTicks = 0;

  int wrongStreakLocal = 0;

  @override
  void resetMetrics() {
    metrics.resetForShapeOrColor();
    targetCardBg = pastelColors[1];
    wrongStreakLocal = 0;
  }

  @override
  void startFirstRound() {
    generateNewTarget();
  }

  @override
  void showFirstTimeHint() {
    startHintBlink();
  }

  @override
  void disposeGameSpecific() {
    hintBlinkTimer?.cancel();
  }

  @override
  void endGame() {
    hintBlinkTimer?.cancel();
    super.endGame();
  }

  void toggleHint() {
    if (gameActive && !isGameOver) {
      metrics.hintsUsed += 1;
      metrics.hintArmed = true;
    }
    startHintBlink();
  }

  void startHintBlink() {
    hintBlinkTimer?.cancel();

    if (!mounted || isGameOver || !gameActive) return;

    setState(() {
      selectedColor = null;
      showHint = true;
      hintBlinkOn = true;
      hintBlinkTicks = 0;
    });

    hintBlinkTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted || isGameOver || !gameActive) {
        t.cancel();
        return;
      }

      setState(() {
        hintBlinkOn = !hintBlinkOn;
        hintBlinkTicks++;
      });

      if (hintBlinkTicks >= 10) {
        t.cancel();
        if (!mounted || isGameOver || !gameActive) return;
        setState(() {
          showHint = false;
          hintBlinkOn = false;
        });
      }
    });
  }

  void generateNewTarget() {
    if (!mounted || isGameOver || !gameActive) return;

    final rnd = Random();
    final entries = colorOptions.entries.toList();
    MapEntry<String, Color> next = entries[rnd.nextInt(entries.length)];

    if (lastTargetColor != null && entries.length > 1) {
      while (next.value == lastTargetColor) {
        next = entries[rnd.nextInt(entries.length)];
      }
    }

    hintBlinkTimer?.cancel();
    showHint = false;
    hintBlinkOn = false;

    setState(() {
      lastTargetColor = next.value;
      targetColorName = next.key;
      targetColor = next.value;
      selectedColor = null;

      roundKey++;
      targetCardBg = pastelColors[rnd.nextInt(pastelColors.length)];
    });

    metrics.currentRoundStartedAt = DateTime.now();
    HapticFeedback.selectionClick();
  }

  Future<void> checkMatch(String colorName, Color color) async {
    if (!gameActive || isGameOver) return;

    metrics.validTaps += 1;

    final now = DateTime.now();
    final rs = metrics.currentRoundStartedAt;
    if (rs != null) {
      metrics.reactionTimesSec.add(now.difference(rs).inMilliseconds / 1000.0);
    }

    setState(() {
      selectedColor = color;
      showHint = false;
      hintBlinkTimer?.cancel();
      hintBlinkOn = false;
    });

    final isCorrect = color == targetColor;

    if (isCorrect) {
      metrics.correct += 1;
      metrics.firstCorrectAt ??= DateTime.now();

      wrongStreakLocal = 0;
      metrics.wrongStreak = 0;

      await Sfx.correct(soundOn);
      await hapticCorrect(hapticsOn);

      if (!mounted || isGameOver || !gameActive) return;
      setState(() => score += 10);

      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && gameActive && !isGameOver) generateNewTarget();
      });
    } else {
      metrics.wrong += 1;

      wrongStreakLocal++;
      metrics.wrongStreak += 1;
      if (metrics.wrongStreak > metrics.wrongStreakMax) {
        metrics.wrongStreakMax = metrics.wrongStreak;
      }

      await Sfx.wrong(soundOn);
      await hapticWrong(hapticsOn);

      if (wrongStreakLocal >= 3) {
        wrongStreakLocal = 0;
        metrics.wrongStreak = 0;
        startHintBlink();
      }
    }

    if (metrics.hintArmed) {
      if (isCorrect) metrics.postHintCorrect += 1;
      metrics.hintArmed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('පාට ගලපමු'),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: Icon(showHint ? Icons.lightbulb : Icons.lightbulb_outline),
            onPressed: toggleHint,
          ),
        ],
      ),
      body: wrapWithTouchCounter(
        gradient: LinearGradient(
          colors: [Colors.pink.shade100, Colors.purple.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text('මගේ ලකුණු:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('ඉතිරි කාලය:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$timeLeft',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: timeLeft <= 10 ? Colors.red : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'මේ පාට ගලපමු:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              targetColorName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 550),
              child: Container(
                key: ValueKey(roundKey),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: targetCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 5),
                ),
                child: Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: targetColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final tileW = (c.maxWidth - 20) / 2;
                  final tileH = (c.maxHeight - 20) / 2;
                  final ratio = tileW / tileH;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: ratio,
                    ),
                    itemCount: colorOptions.length,
                    itemBuilder: (context, index) {
                      final entry = colorOptions.entries.elementAt(index);
                      final isSelected = selectedColor == entry.value;
                      final isCorrect =
                          isSelected && entry.value == targetColor;
                      final isWrong = isSelected && entry.value != targetColor;

                      final isHintTarget =
                          showHint && (entry.value == targetColor);
                      final blinkGreen = isHintTarget && hintBlinkOn;

                      return GestureDetector(
                        onTap: () => checkMatch(entry.key, entry.value),
                        child: Container(
                          decoration: BoxDecoration(
                            color: blinkGreen ? Colors.white : entry.value,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: blinkGreen
                                  ? Colors.green
                                  : (isCorrect
                                        ? Colors.green
                                        : (isWrong
                                              ? Colors.red
                                              : Colors.white)),
                              width: blinkGreen ? 6 : (isSelected ? 5 : 3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              entry.key,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: blinkGreen
                                    ? Colors.green.shade900
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
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
}

/// =====================================
/// Pop Bubbles Game (keeps AnimationController)
/// =====================================
class PopBubblesGame extends StatefulWidget {
  final GameMetrics metrics;
  final Function(int score) onGameComplete;

  const PopBubblesGame({
    Key? key,
    required this.metrics,
    required this.onGameComplete,
  }) : super(key: key);

  @override
  State<PopBubblesGame> createState() => _PopBubblesGameState();
}

class Bubble {
  double x;
  double y;
  Color color;
  String id;

  Bubble({
    required this.x,
    required this.y,
    required this.color,
    required this.id,
  });
}

class _PopBubblesGameState extends BaseTimedGameState<PopBubblesGame>
    with SingleTickerProviderStateMixin {
  @override
  GameMetrics get metrics => widget.metrics;

  @override
  String get firstPlayKey => 'pop_first_play_done';

  @override
  GameType get gameType => GameType.bubble; // ✅ ADDED

  @override
  String get endDialogTitle => '🎉 බෝල පිපිරවීම සම්පුර්ණයි!';

  @override
  String get endDialogWaitingText => 'මුළු ලකුණු ගණනය කරමින්...';

  @override
  void onGameComplete(int finalScore) => widget.onGameComplete(finalScore);

  Timer? spawnTimer;
  List<Bubble> bubbles = [];

  late AnimationController anim;

  Bubble? hintBubble;
  bool hintBlinkOn = false;
  Timer? hintBlinkTimer;
  int hintBlinkTicks = 0;

  final List<Color> bubbleColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void initState() {
    anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 32),
    )..addListener(updateBubbles);

    super.initState();
  }

  @override
  void resetMetrics() {
    metrics.resetForBubbles();
    bubbles.clear();
    hintBubble = null;
    hintBlinkOn = false;
    hintBlinkTicks = 0;
  }

  @override
  void startFirstRound() {
    anim.repeat();

    spawnTimer?.cancel();
    spawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (t) {
      if (!mounted || isGameOver || !gameActive) return;
      spawnBubble();
    });
  }

  @override
  void showFirstTimeHint() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || bubbles.isEmpty || isGameOver || !gameActive) return;
      _startBlinkOnBubble(bubbles.first);
    });
  }

  @override
  void disposeGameSpecific() {
    spawnTimer?.cancel();
    hintBlinkTimer?.cancel();
    anim.removeListener(updateBubbles);
    anim.dispose();
  }

  @override
  void endGame() {
    spawnTimer?.cancel();
    hintBlinkTimer?.cancel();
    anim.stop();
    super.endGame();
  }

  void spawnBubble() {
    if (!mounted || isGameOver || !gameActive) return;
    final r = Random();
    setState(() {
      bubbles.add(
        Bubble(
          x: r.nextDouble() * 0.8 + 0.1,
          y: 1.2,
          color: bubbleColors[r.nextInt(bubbleColors.length)],
          id: DateTime.now().microsecondsSinceEpoch.toString(),
        ),
      );
    });
  }

  void updateBubbles() {
    if (!mounted || isGameOver || !gameActive) return;

    setState(() {
      final updated = <Bubble>[];
      for (final b in bubbles) {
        b.y -= 0.003;
        if (b.y <= -0.1) {
          metrics.missedBubbles += 1;
          continue;
        }
        updated.add(b);
      }
      bubbles = updated;
    });
  }

  void onHintPressed() {
    if (!mounted || bubbles.isEmpty || isGameOver || !gameActive) return;
    metrics.hintsUsed += 1;
    final size = MediaQuery.of(context).size;
    final centerBubble = _pickCenterBubble(size);
    _startBlinkOnBubble(centerBubble);
  }

  Bubble _pickCenterBubble(Size size) {
    Bubble best = bubbles.first;
    double bestDist = double.infinity;

    for (final b in bubbles) {
      final px = b.x * size.width;
      final py = b.y * size.height;
      final dx = px - size.width / 2;
      final dy = py - size.height / 2;
      final d = dx * dx + dy * dy;
      if (d < bestDist) {
        bestDist = d;
        best = b;
      }
    }
    return best;
  }

  void _startBlinkOnBubble(Bubble b) {
    hintBlinkTimer?.cancel();

    if (!mounted || isGameOver || !gameActive) return;

    setState(() {
      hintBubble = b;
      hintBlinkOn = true;
      hintBlinkTicks = 0;
    });

    hintBlinkTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted || isGameOver || !gameActive) {
        t.cancel();
        return;
      }

      setState(() {
        hintBlinkOn = !hintBlinkOn;
        hintBlinkTicks++;
      });

      if (hintBlinkTicks >= 10) {
        t.cancel();
        if (!mounted || isGameOver || !gameActive) return;
        setState(() {
          hintBlinkOn = false;
          hintBubble = null;
        });
      }
    });
  }

  Future<void> popBubble(Bubble b) async {
    if (!gameActive || isGameOver) return;

    metrics.validTaps += 1;
    // metrics.poppedCount += 1;
    metrics.popTimes.add(DateTime.now());

    setState(() {
      bubbles.removeWhere((x) => x.id == b.id);
      score += 5;
      if (hintBubble?.id == b.id) {
        hintBubble = null;
        hintBlinkOn = false;
      }
    });

    await Sfx.correct(soundOn);
    await hapticCorrect(hapticsOn);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('බෝල පුපුරවමු'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, size: 30),
            onPressed: onHintPressed,
          ),
        ],
      ),
      body: wrapWithTouchCounter(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.blue.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text('මගේ ලකුණු:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('ඉතිරි කාලය:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$timeLeft',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: timeLeft <= 10 ? Colors.red : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: bubbles.map((b) {
                  final isHint = hintBubble?.id == b.id && hintBlinkOn;

                  return Positioned(
                    left: b.x * size.width - 30,
                    top: b.y * size.height - 30,
                    child: GestureDetector(
                      onTap: () => popBubble(b),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHint ? Colors.green : b.color,
                          border: Border.all(
                            color: isHint ? Colors.white : Colors.transparent,
                            width: isHint ? 4 : 0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Future<void> saveLdResultToBackend({
//   required String baseUrl,
//   required String studentId,
//   required Map<String, dynamic> features,
//   required List<double> probs,
//   required String predLabel,
//   required double predScore,
// }) async {
//   final uri = Uri.parse('$baseUrl/api/cognitive/ld-predictions');

//   final body = <String, dynamic>{
//     'studentId': studentId,
//     'probs': probs,
//     'predLabel': predLabel,
//     'predScore': predScore,
//     ...features,
//   };

//   final res = await http.post(
//     uri,
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode(body),
//   );

//   if (res.statusCode < 200 || res.statusCode >= 300) {
//     throw Exception('Save failed ${res.statusCode}: ${res.body}');
//   }
// }
