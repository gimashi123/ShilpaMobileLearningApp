import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:mobile_app/pages/games_cognitive/cognitive_game_loading_screen.dart';
import 'package:mobile_app/services/cognitive.dart';
import 'hand_hint_overlay.dart';
import 'idle_dino_overlay.dart';

class PatternGameApp extends StatelessWidget {
  const PatternGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const PatternGamePage();
  }
}

class PatternGamePage extends StatefulWidget {
  const PatternGamePage({super.key});

  @override
  State<PatternGamePage> createState() => _PatternGamePageState();
}

class _PatternGamePageState extends State<PatternGamePage>
    with SingleTickerProviderStateMixin {
  final _rng = Random();

  // Animation & Hint State
  final List<GlobalKey> _optionKeys = List.generate(4, (index) => GlobalKey());
  bool _showHandHint = false;

  // TTS & Audio
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // Confetti & Star
  late final ConfettiController _confettiController;
  late final AnimationController _starController;
  late final Animation<double> _starScale;

  // Levels & Pattern State
  int level = 1;
  int score = 0;
  String type = 'colors';
  late List<String> pattern;
  late String answer;
  late List<String> options;
  bool _isLoadingPatternTypes = true;

  static const Map<String, List<String>> _fallbackPatternTypes = {
    'colors': ["🔵", "🔴", "🟡", "🟢"],
    'shapes': ["⬛", "⬜", "🔺", "⭐"],
    'numbers': ["1", "2", "3", "4", "5"],
  };
  Map<String, List<String>> _patternTypes = Map<String, List<String>>.from(
    _fallbackPatternTypes,
  );
  List<String> _typeOrder = List<String>.from(_fallbackPatternTypes.keys);

  // UI feedback
  String feedback = "නිවැරදි ඊළඟ අංගය තට්ටු කරන්න";
  Color feedbackColor = Colors.black;

  int _hintBlinkIndex = -1;
  Timer? _hintTimer;
  Timer? _blinkTimer;
  bool _showStar = false;

  // Stats
  int _questionsPlayed = 0;
  int _correctAnswers = 0;
  Duration _totalReactionTime = Duration.zero;
  int _reactionSamples = 0;
  DateTime? _roundStartedAt;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 900),
    );
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _starScale = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _starController, curve: Curves.elasticOut),
    );

    _setupTts();
    _loadDynamicPatternTypes();
  }

  Future<void> _setupTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    try {
      await _tts.setLanguage("si-LK");
    } catch (_) {}
  }

  @override
  void dispose() {
    _cancelHintTimers();
    _sfxPlayer.dispose();
    _confettiController.dispose();
    _starController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadDynamicPatternTypes() async {
    setState(() => _isLoadingPatternTypes = true);
    final fetched = await _fetchPatternTypesFromApi();
    if (!mounted) return;

    if (fetched.isNotEmpty) {
      _patternTypes = fetched;
      _typeOrder = fetched.keys.toList();
    } else {
      _patternTypes = Map<String, List<String>>.from(_fallbackPatternTypes);
      _typeOrder = List<String>.from(_fallbackPatternTypes.keys);
    }

    _newRound(speak: true);
    if (!mounted) return;
    setState(() => _isLoadingPatternTypes = false);
  }

  Future<Map<String, List<String>>> _fetchPatternTypesFromApi() async {
    try {
      final items = await fetchMatchPatternTypeItems();
      final data = <String, List<String>>{};
      for (final item in items) {
        final cleaned = item.bank.where((e) => e.trim().isNotEmpty).toList();
        if (item.type.trim().isNotEmpty && cleaned.length >= 3) {
          data[item.type.trim()] = cleaned;
        }
      }
      return data;
    } catch (_) {
      return {};
    }
  }

  void _newRound({bool speak = false}) {
    if (_typeOrder.isEmpty) return;
    type = _typeOrder[(level - 1) % _typeOrder.length];

    if (level <= 2) {
      _makeABAB();
    } else if (level <= 4) {
      _makeABCABC();
    } else {
      _makeAABAAB();
    }

    setState(() {
      _showHandHint = false;
      feedback = "නිවැරදි ඊළඟ අංගය තෝරන්න";
      feedbackColor = Colors.black;
    });

    _roundStartedAt = DateTime.now();
    _startHintTimer();
    if (speak) {
      _speakPrompt();
    }
  }

  // --- Pattern Logic (Unchanged) ---
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

  List<String> _bankForType(String t) {
    final bank = _patternTypes[t];
    if (bank == null || bank.isEmpty) {
      return const ["1", "2", "3", "4", "5"];
    }
    return bank;
  }

  List<String> _buildOptions(String correct, List<String> bank, int count) {
    final set = <String>{correct};
    while (set.length < count) {
      set.add(bank[_rng.nextInt(bank.length)]);
    }
    final list = set.toList()..shuffle(_rng);
    return list;
  }

  // --- Hint & Animation Logic ---

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
      _startBlinkHint(); // Triggers both blinking and hand overlay
    });
  }

  void _startBlinkHint() {
    _blinkTimer?.cancel();
    final correctIndex = options.indexOf(answer);
    if (correctIndex == -1) return;

    // Show Hand Hint
    setState(() {
      _showHandHint = true;
      _hintBlinkIndex = correctIndex;
    });

    // Blink Logic (runs 3 times)
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

  void _onPick(String pick) async {
    final pickedAt = DateTime.now();
    _cancelHintTimers();
    setState(() => _showHandHint = false); // Hide hand immediately on tap

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
      _speakPrompt();
      _startHintTimer();
    }
  }

  // --- UI Helpers ---

  Future<void> _speakPrompt() async {
    await _tts.stop();
    await _tts.speak("ඊළඟට එන්නේ මොකක්ද?");
  }

  Future<void> _playRewardAnimation() async {
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource("sounds/cognitive/cheers.mp3"));
    setState(() => _showStar = true);
    _confettiController.play();
    await _starController.forward(from: 0);
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
    if (!mounted) return;
  }

  Future<void> _goDashboard() async {
    await _sfxPlayer.stop();
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/home_cognitive', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPatternTypes) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.sizeOf(context);
    final scale = (size.shortestSide / 360).clamp(0.85, 1.2);
    final questionRow = [...pattern, "?"];
return IdleDinoOverlay(
    gifPath: 'assets/images/cognitive/dinosaur_2.gif',
    child: Scaffold(
      appBar: AppBar(title: const Text("රටා හඳුනාගැනීම"), centerTitle: true),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                          .map(
                            (e) => _TokenChip(
                              text: e,
                              big: true,
                              isQuestionMark: e == "?",
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                        final hintGlow = index == _hintBlinkIndex;
                        return ElevatedButton(
                          key: _optionKeys[index], // KEY ASSIGNED HERE
                          onPressed: () => _onPick(entry.value),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hintGlow
                                ? Colors.green.withOpacity(0.3)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.all(12),
                            textStyle: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(entry.value),
                        );
                      }).toList(),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _goDashboard,
                          icon: const Icon(Icons.dashboard),
                          label: const Text("Home"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _newRound(speak: true),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text("Restart"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
              ),
            ),
            // Star Overlay
            if (_showStar)
              Center(
                child: ScaleTransition(
                  scale: _starScale,
                  child: _StarRewardBox(),
                ),
              ),

            // HAND HINT OVERLAY (Placed inside the stack list)
            if (_showHandHint && options.contains(answer))
              HandHintOverlay(
                targetKey: _optionKeys[options.indexOf(answer)],
                onFinished: () => setState(() => _showHandHint = false),
              ),
          ],
        ),
      ),
    ),
    );
  }
}

// Sub-widgets to keep build clean
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
          fontSize: big ? 34.0 : 22.0,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StarRewardBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(blurRadius: 18, color: Colors.black.withOpacity(0.12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text("⭐", style: TextStyle(fontSize: 72)),
          SizedBox(height: 6),
          Text(
            "හරි! නිවැරදියි.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
