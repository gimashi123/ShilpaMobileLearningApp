import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:mobile_app/pages/games_cognitive/cognitive_game_loading_screen.dart';
import 'package:mobile_app/services/cognitive.dart';
import 'idle_dino_overlay.dart';
// --- HAND HINT OVERLAY WIDGET ---
class HandHintOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final VoidCallback onFinished;

  const HandHintOverlay({
    super.key,
    required this.targetKey,
    required this.onFinished,
  });

  @override
  State<HandHintOverlay> createState() => _HandHintOverlayState();
}

class _HandHintOverlayState extends State<HandHintOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;
  Offset? _targetOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) => _calculatePosition());
    _controller.forward().then((_) => widget.onFinished());
  }

  void _calculatePosition() {
    final renderBox = widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      final position = renderBox.localToGlobal(Offset.zero);
      final center = Offset(
        position.dx + renderBox.size.width / 2,
        position.dy + renderBox.size.height / 2,
      );

      setState(() {
        _targetOffset = center;
        _positionAnimation = Tween<Offset>(
          begin: center + const Offset(80, 120),
          end: center,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targetOffset == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx - 30,
          top: _positionAnimation.value.dy - 30,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: const Icon(
              Icons.front_hand,
              size: 70,
              color: Colors.orangeAccent,
              shadows: [Shadow(blurRadius: 15, color: Colors.black45)],
            ),
          ),
        );
      },
    );
  }
}

// --- MAIN GAME CLASSES ---

class NumberMatchingGameApp extends StatelessWidget {
  const NumberMatchingGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const NumberMatchingGamePage();
  }
}

class NumberItem {
  final int value;
  final String word;
  const NumberItem({required this.value, required this.word});
}

class NumberMatchingGamePage extends StatefulWidget {
  const NumberMatchingGamePage({super.key});

  @override
  State<NumberMatchingGamePage> createState() => _NumberMatchingGamePageState();
}

class _NumberMatchingGamePageState extends State<NumberMatchingGamePage>
    with TickerProviderStateMixin {
  final _rng = Random();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final GlobalKey _correctKey = GlobalKey(); // Key to track correct answer position

  static const List<NumberItem> _fallbackItems = [
    NumberItem(value: 1, word: "එක"),
    NumberItem(value: 2, word: "දෙක"),
    NumberItem(value: 3, word: "තුන"),
    NumberItem(value: 4, word: "හතර"),
    NumberItem(value: 5, word: "පහ"),
    NumberItem(value: 6, word: "හය"),
    NumberItem(value: 7, word: "හත"),
    NumberItem(value: 8, word: "අට"),
    NumberItem(value: 9, word: "නවය"),
  ];
  List<NumberItem> _items = List<NumberItem>.from(_fallbackItems);
  bool _isLoadingItems = true;

  late NumberItem _current;
  late List<NumberItem> _choices;

  String _feedback = "අංකයට ගැලපෙන වචනය තෝරන්න";
  Color _feedbackColor = Colors.black87;
  bool _locked = false;
  int _hintBlinkIndex = -1;
  bool _showHandHint = false; 
  Timer? _hintTimer;
  Timer? _blinkTimer;

  late final ConfettiController _confettiController;
  late final AnimationController _starController;
  late final Animation<double> _starScale;

  bool _showStar = false;
  int _rewardIndex = -1;

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
    _loadDynamicItems();
  }

  @override
  void dispose() {
    _cancelHintTimers();
    _sfxPlayer.dispose();
    _confettiController.dispose();
    _starController.dispose();
    super.dispose();
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
      if (!mounted || _locked) return;
      _startBlinkHint();
    });
  }

  void _startBlinkHint() {
    _blinkTimer?.cancel();
    final correctIndex = _choices.indexWhere((it) => it.value == _current.value);
    if (correctIndex == -1) return;

    setState(() {
      _showHandHint = true; // Trigger Hand Animation
    });

    int toggles = 0;
    bool on = false;

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) { t.cancel(); return; }
      on = !on;
      setState(() => _hintBlinkIndex = on ? correctIndex : -1);
      toggles++;
      if (toggles >= 6) {
        t.cancel();
        setState(() => _hintBlinkIndex = -1);
      }
    });
  }

  void _startNewRound() {
    if (_items.length < 4) {
      _items = List<NumberItem>.from(_fallbackItems);
    }
    _cancelHintTimers();
    _current = _items[_rng.nextInt(_items.length)];
    final pool = _items.where((e) => e.value != _current.value).toList()..shuffle(_rng);
    _choices = [_current, ...pool.take(3)]..shuffle(_rng);

    setState(() {
      _feedback = "අංකයට ගැලපෙන වචනය තෝරන්න";
      _feedbackColor = Colors.black87;
      _locked = false;
      _showStar = false;
      _rewardIndex = -1;
      _showHandHint = false;
    });
    _roundStartedAt = DateTime.now();
    _startHintTimer();
  }

  Future<void> _loadDynamicItems() async {
    setState(() => _isLoadingItems = true);
    final fetched = await _fetchItemsFromApi();
    if (!mounted) return;

    _items = fetched.length >= 4
        ? fetched
        : List<NumberItem>.from(_fallbackItems);
    _startNewRound();

    if (!mounted) return;
    setState(() => _isLoadingItems = false);
  }

  Future<List<NumberItem>> _fetchItemsFromApi() async {
    try {
      final items = await fetchMatchNumberItems();
      return items
          .map((e) => NumberItem(value: e.value, word: e.word))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _onPick(NumberItem picked, int index) async {
    if (_locked) return;
    _cancelHintTimers();
    setState(() {
      _locked = true;
      _showHandHint = false; // Hide hand if user interacts
    });

    final correct = picked.value == _current.value;
    _questionsPlayed++;
    if (correct) {
      _correctAnswers++;
      if (_roundStartedAt != null) {
        _totalReactionTime += DateTime.now().difference(_roundStartedAt!);
        _reactionSamples++;
      }
      setState(() {
        _feedback = "";
        _rewardIndex = index;
      });
      await _playRewardAnimation();
      _startNewRound();
    } else {
      setState(() {
        _feedback = "වැරදියි. නැවත උත්සාහ කරන්න.";
        _feedbackColor = Colors.red;
      });
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() {
        _locked = false;
        _feedback = "අංකයට ගැලපෙන වචනය තෝරන්න";
        _feedbackColor = Colors.black87;
      });
      _startHintTimer();
    }
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
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const CognitiveGameLoadingScreen(gameTitle: 'අංකය ගැලපීම', autoNavigate: false, duration: Duration(seconds: 4)),
    ));
  }

  Future<void> _goDashboard() async {
    await _sfxPlayer.stop();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/home_cognitive', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = (size.shortestSide / 360).clamp(0.85, 1.2);
    if (_isLoadingItems) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    return IdleDinoOverlay(
    gifPath: 'assets/images/cognitive/dinosaur_2.gif',

    child: Scaffold(
      appBar: AppBar(title: const Text("අංකය ගැලපීම"), centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goDashboard)),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0 * scale),
              child: Column(
                children: [
                  // Number Display
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20 * scale),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.black.withOpacity(0.05)),
                    child: Center(child: Text("${_current.value}", style: TextStyle(fontSize: 70 * scale, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(height: 15),
                  // Feedback
                  Text(_feedback, textAlign: TextAlign.center, style: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.w600, color: _feedbackColor)),
                  const SizedBox(height: 15),
                  // Choices Grid
                  Expanded(
                    child: GridView.builder(
                      itemCount: _choices.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2),
                      itemBuilder: (context, index) {
                        final item = _choices[index];
                        final isCorrect = item.value == _current.value;
                        return _WordCard(
                          key: isCorrect ? _correctKey : null, // Attach key to correct choice
                          word: item.word,
                          onTap: () => _onPick(item, index),
                          disabled: _locked,
                          highlightGreen: (index == _rewardIndex || index == _hintBlinkIndex),
                        );
                      },
                    ),
                  ),
                  // Controls
                  Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(onPressed: _goDashboard, icon: const Icon(Icons.dashboard), label: const Text("Home"))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(onPressed: _startNewRound, icon: const Icon(Icons.restart_alt), label: const Text("නැවත ආරම්භ කරන්න"))),
                    ],
                  ),
                ],
              ),
            ),
            // Hand Hint Overlay (Above game content)
            if (_showHandHint)
              HandHintOverlay(
                targetKey: _correctKey,
                onFinished: () => setState(() => _showHandHint = false),
              ),
            // Confetti
            Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive)),
            // Star Success View
            if (_showStar)
              Center(
                child: ScaleTransition(
                  scale: _starScale,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black12)]),
                    child: Column(mainAxisSize: MainAxisSize.min, children: const [Text("⭐", style: TextStyle(fontSize: 80)), Text("හරි! ගැලපුණා.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),);
  }
}

class _WordCard extends StatelessWidget {
  final String word;
  final VoidCallback onTap;
  final bool disabled;
  final bool highlightGreen;

  const _WordCard({
    super.key,
    required this.word,
    required this.onTap,
    required this.disabled,
    required this.highlightGreen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: highlightGreen ? Colors.green.withOpacity(0.3) : Colors.white,
          border: Border.all(color: Colors.black12),
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.05), offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(word, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
