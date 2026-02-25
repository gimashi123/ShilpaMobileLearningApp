import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:mobile_app/pages/games_cognitive/cognitive_game_loading_screen.dart';

class PatternGameApp extends StatelessWidget {
  const PatternGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const PatternGamePage();
  }
}

enum PatternType { colors, shapes, numbers }

class PatternGamePage extends StatefulWidget {
  const PatternGamePage({super.key});

  @override
  State<PatternGamePage> createState() => _PatternGamePageState();
}

class _PatternGamePageState extends State<PatternGamePage>
    with SingleTickerProviderStateMixin {
  final _rng = Random();

  // TTS
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // Confetti
  late final ConfettiController _confettiController;

  // Star pop animation
  late final AnimationController _starController;
  late final Animation<double> _starScale;

  // Levels
  int level = 1;
  int score = 0;

  // Current pattern
  PatternType type = PatternType.colors;
  late List<String> pattern;
  late String answer;
  late List<String> options;

  // UI feedback
  String feedback = "නිවැරදි ඊළඟ අංගය තට්ටු කරන්න";
  Color feedbackColor = Colors.black;

  int _hintBlinkIndex = -1;
  Timer? _hintTimer;
  Timer? _blinkTimer;

  bool _showStar = false;

  // Attempt stats
  int _questionsPlayed = 0;
  int _correctAnswers = 0;
  Duration _totalReactionTime = Duration.zero;
  int _reactionSamples = 0;
  DateTime? _roundStartedAt;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 900));

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _starScale = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _starController, curve: Curves.elasticOut),
    );

    _setupTts();
    _newRound(speak: true);
  }

  Future<void> _setupTts() async {
    // Basic safe defaults (works on Android/iOS if TTS engine is available)
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    // If your device supports Sinhala voice, this helps.
    // If it fails, it will just use default voice.
    try {
      await _tts.setLanguage("si-LK");
    } catch (_) {}
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _cancelHintTimers();
    _sfxPlayer.dispose();
    _confettiController.dispose();
    _starController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakPrompt() async {
    // short + clear for kids
    await _tts.stop();
    await _tts.speak("ඊළඟට එන්නේ මොකක්ද?");
  }

  void _newRound({bool speak = false}) {
    // Rotate pattern types by level
    type = PatternType.values[(level - 1) % PatternType.values.length];

    if (level <= 2) {
      _makeABAB();
    } else if (level <= 4) {
      _makeABCABC();
    } else {
      _makeAABAAB();
    }

    setState(() {
      feedback = "නිවැරදි ඊළඟ අංගය තෝරන්න";
      feedbackColor = Colors.black;
    });
    _roundStartedAt = DateTime.now();

    _startHintTimer();

    if (speak) {
      _speakPrompt();
    }
  }

  void _makeABAB() {
    final bank = _bankForType(type);
    final a = bank[_rng.nextInt(bank.length)];
    String b = bank[_rng.nextInt(bank.length)];
    while (b == a) {
      b = bank[_rng.nextInt(bank.length)];
    }

    pattern = [a, b, a, b];
    answer = a;
    options = _buildOptions(answer, bank, 3);
  }

  void _makeABCABC() {
    final bank = _bankForType(type);
    final a = bank[_rng.nextInt(bank.length)];
    String b = bank[_rng.nextInt(bank.length)];
    while (b == a) {
      b = bank[_rng.nextInt(bank.length)];
    }
    String c = bank[_rng.nextInt(bank.length)];
    while (c == a || c == b) {
      c = bank[_rng.nextInt(bank.length)];
    }

    pattern = [a, b, c, a, b, c];
    answer = a;
    options = _buildOptions(answer, bank, 4);
  }

  void _makeAABAAB() {
    final bank = _bankForType(type);
    final a = bank[_rng.nextInt(bank.length)];
    String b = bank[_rng.nextInt(bank.length)];
    while (b == a) {
      b = bank[_rng.nextInt(bank.length)];
    }

    pattern = [a, a, b, a, a, b];
    answer = a;
    options = _buildOptions(answer, bank, 4);
  }

  List<String> _bankForType(PatternType t) {
    switch (t) {
      case PatternType.colors:
        return const ["🔵", "🔴", "🟡", "🟢"];
      case PatternType.shapes:
        return const ["⬛", "⬜", "🔺", "⭐"];
      case PatternType.numbers:
        return const ["1", "2", "3", "4", "5"];
    }
  }

  List<String> _buildOptions(String correct, List<String> bank, int count) {
    final set = <String>{correct};
    while (set.length < count) {
      set.add(bank[_rng.nextInt(bank.length)]);
    }
    final list = set.toList()..shuffle(_rng);
    return list;
  }

  Future<void> _playRewardAnimation() async {
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource("sounds/cognitive/cheers.mp3"));

    setState(() => _showStar = true);

    _confettiController.play();
    await _starController.forward(from: 0);

    // Keep star visible before next pattern
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;
    setState(() => _showStar = false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CognitiveGameLoadingScreen(
          gameTitle: 'රටා හඳුනාගැනීම',
          autoNavigate: false,
          duration: Duration(seconds: 3),
        ),
      ),
    );
  }

  void _cancelHintTimers() {
    _hintTimer?.cancel();
    _blinkTimer?.cancel();
    _hintTimer = null;
    _blinkTimer = null;
    _hintBlinkIndex = -1;
  }

  void _startHintTimer() {
    _cancelHintTimers();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      _startBlinkHint();
    });
  }

  void _startBlinkHint() {
    _blinkTimer?.cancel();

    final correctIndex = options.indexOf(answer);
    if (correctIndex == -1) return;

    _hintBlinkIndex = correctIndex;

    int toggles = 0;
    bool on = false;

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      on = !on;
      setState(() {
        _hintBlinkIndex = on ? correctIndex : -1;
      });

      toggles++;
      if (toggles >= 6) {
        t.cancel();
        setState(() => _hintBlinkIndex = -1);
      }
    });
  }

  void _printAttemptStatsToTerminal({required String event}) {
    final accuracy = _questionsPlayed == 0
        ? 0.0
        : (_correctAnswers / _questionsPlayed) * 100;
    final avgReactionMs = _reactionSamples == 0
        ? 0
        : (_totalReactionTime.inMilliseconds / _reactionSamples).round();

    debugPrint(
      "[MATCH_PATTERN_SCORE] event=$event questions=$_questionsPlayed correct=$_correctAnswers accuracy=${accuracy.toStringAsFixed(1)} avg_reaction_ms=$avgReactionMs samples=$_reactionSamples",
    );
  }

  void _onPick(String pick) async {
    final pickedAt = DateTime.now();
    _cancelHintTimers();
    final ok = pick == answer;

    setState(() {
      _questionsPlayed++;
      if (ok) {
        _correctAnswers++;
      }
      if (_roundStartedAt != null) {
        _totalReactionTime += pickedAt.difference(_roundStartedAt!);
        _reactionSamples++;
      }
    });
    _printAttemptStatsToTerminal(event: ok ? "answer_correct" : "answer_wrong");

    if (ok) {
      setState(() {
        score += 1;
        level += 1;
        feedback = "";
        feedbackColor = Colors.green;
      });

      await _playRewardAnimation();

      if (!mounted) return;
      _newRound(speak: true);
    } else {
      setState(() {
        feedback = "❌ නැවත උත්සාහ කරන්න";
        feedbackColor = Colors.red;
      });
      // Optional: re-speak prompt after wrong answer (gentle)
      _speakPrompt();
      _startHintTimer();
    }
  }

  void _resetGame() {
    _printAttemptStatsToTerminal(event: "restart_before_reset");
    unawaited(_sfxPlayer.stop());
    setState(() {
      level = 1;
      score = 0;
      _questionsPlayed = 0;
      _correctAnswers = 0;
      _totalReactionTime = Duration.zero;
      _reactionSamples = 0;
      _roundStartedAt = null;
      feedback = "නිවැරදි ඊළඟ අංගය තෝරන්න";
      feedbackColor = Colors.black;
      _showStar = false;
    });
    _newRound(speak: true);
  }

  Future<void> _goDashboard() async {
    _printAttemptStatsToTerminal(event: "home_exit");
    await _sfxPlayer.stop();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      '/home_cognitive',
      (route) => false,
    );
  }

  String _titleForType(PatternType t) {
    switch (t) {
      case PatternType.colors:
        return "වර්ණ රටා";
      case PatternType.shapes:
        return "ආකෘති රටා";
      case PatternType.numbers:
        return "අංක රටා";
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = (size.shortestSide / 360).clamp(0.85, 1.2);
    final questionRow = [...pattern, "?"];
    final accuracy = _questionsPlayed == 0
        ? 0.0
        : (_correctAnswers / _questionsPlayed) * 100;
    final avgReactionMs = _reactionSamples == 0
        ? 0
        : (_totalReactionTime.inMilliseconds / _reactionSamples).round();
    final avgReactionSeconds = avgReactionMs / 1000.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("රටා හඳුනාගැනීම"),
        centerTitle: true,
        actions: [
          // IconButton(
          //   tooltip: "Terminal score",
          //   onPressed: () => _printAttemptStatsToTerminal(event: "manual_view"),
          //   icon: const Icon(Icons.terminal),
          // ),
          // IconButton(
          //   tooltip: "කථනය",
          //   onPressed: _speakPrompt,
          //   icon: const Icon(Icons.volume_up),
          // ),
          // IconButton(
          //   tooltip: "නැවත සැකසන්න",
          //   onPressed: _resetGame,
          //   icon: const Icon(Icons.refresh),
          // ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Status
                  // Container(
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.all(14),
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(16),
                  //     border: Border.all(color: Colors.black12),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         _titleForType(type),
                  //         style: const TextStyle(
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.w700,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 8),
                  //       Text("මට්ටම: $level    ලකුණු: $score",
                  //           style: const TextStyle(fontSize: 16)),
                  //       const SizedBox(height: 8),
                  //       Text(
                  //         "Questions: $_questionsPlayed  Correct: $_correctAnswers  Accuracy: ${accuracy.toStringAsFixed(1)}%  Avg reaction: ${avgReactionSeconds.toStringAsFixed(2)}s",
                  //         style: const TextStyle(fontSize: 14),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // const SizedBox(height: 18),

                  // Pattern display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withOpacity(0.03),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: questionRow
                          .map((e) => _TokenChip(
                                text: e,
                                big: true,
                                isQuestionMark: e == "?",
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Feedback
                  Text(
                    feedback,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: feedbackColor,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Options buttons
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.4,
                      children: options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final opt = entry.value;
                        final hintGlow = index == _hintBlinkIndex;
                        return ElevatedButton(
                          onPressed: () => _onPick(opt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                hintGlow ? Colors.green.withOpacity(0.25) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.all(12),
                            textStyle: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(opt),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _goDashboard(),
                          icon: const Icon(Icons.dashboard),
                          label: const Text("Home"),
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            _printAttemptStatsToTerminal(
                              event: "restart_before_reset",
                            );
                            await _sfxPlayer.stop();
                            setState(() {
                              _questionsPlayed = 0;
                              _correctAnswers = 0;
                              _totalReactionTime = Duration.zero;
                              _reactionSamples = 0;
                              _roundStartedAt = null;
                            });
                            _newRound(speak: true);
                          },
                          icon: const Icon(Icons.restart_alt),
                          label: const Text("නැවත ආරම්භ කරන්න"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Confetti (top center)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.06,
                numberOfParticles: 18,
                gravity: 0.25,
              ),
            ),

            // Star pop overlay (center)
            if (_showStar)
              Center(
                child: ScaleTransition(
                  scale: _starScale,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          color: Colors.black.withOpacity(0.12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "⭐",
                          style: TextStyle(fontSize: 72),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "හරි! නිවැරදියි.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

class _TokenChip extends StatelessWidget {
  final String text;
  final bool big;
  final bool isQuestionMark;

  const _TokenChip({
    required this.text,
    this.big = false,
    this.isQuestionMark = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = big ? 34.0 : 22.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        color: isQuestionMark ? Colors.amber.withOpacity(0.25) : Colors.white,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
