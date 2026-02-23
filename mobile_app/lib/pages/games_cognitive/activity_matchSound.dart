import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:mobile_app/pages/games_cognitive/cognitive_game_loading_screen.dart';

class SoundPictureMatchApp extends StatelessWidget {
  const SoundPictureMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SoundPictureMatchGame();
  }
}

// =====================
// GAME MODELS
// =====================
class SoundItem {
  final String id;
  final String soundAsset; // e.g. sounds/cognitive/dog.mp3 (under assets/)
  final String imageAsset; // e.g. assets/images/cognitive/dog.png

  const SoundItem({
    required this.id,
    required this.soundAsset,
    required this.imageAsset,
  });
}

// =====================
// GAME SCREEN
// =====================
class SoundPictureMatchGame extends StatefulWidget {
  const SoundPictureMatchGame({super.key});

  @override
  State<SoundPictureMatchGame> createState() => _SoundPictureMatchGameState();
}

class _SoundPictureMatchGameState extends State<SoundPictureMatchGame>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // ✅ Make sure these paths match your pubspec.yaml assets
  final List<SoundItem> _items = const [
    SoundItem(
      id: "dog",
      soundAsset: "sounds/cognitive/dog.mp3",
      imageAsset: "assets/images/cognitive/dog.png",
    ),
    SoundItem(
      id: "bell",
      soundAsset: "sounds/cognitive/bell.mp3",
      imageAsset: "assets/images/cognitive/bell.png",
    ),
    SoundItem(
      id: "cat",
      soundAsset: "sounds/cognitive/cat.mp3",
      imageAsset: "assets/images/cognitive/cat.png",
    ),
    SoundItem(
      id: "car",
      soundAsset: "sounds/cognitive/car.mp3",
      imageAsset: "assets/images/cognitive/car.png",
    ),
  ];

  late SoundItem _current;
  late List<SoundItem> _choices;

  String _feedback = "🔊 ශබ්දය ඇසීමට තට්ටු කරන්න";
  bool _locked = false;
  late final ConfettiController _confettiController;
  late final AnimationController _starController;
  late final Animation<double> _starScale;
  bool _showStar = false;

  // Timers
  Timer? _autoPlayTimer; // 3s autoplay if user doesn't press Play Sound
  Timer? _hintTimer; // 4s hint after sound is played
  Timer? _blinkTimer; // blink correct option background
  bool _soundPlayedThisRound = false;

  // Hint blink
  int _hintBlinkIndex = -1;

  // Attempt stats
  int _questionsPlayed = 0;
  int _correctAnswers = 0;
  Duration _totalReactionTime = Duration.zero;
  int _reactionSamples = 0;
  DateTime? _roundSoundPlayedAt;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 900));
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _starScale = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _starController, curve: Curves.elasticOut),
    );
    _startNewRound();
  }

  @override
  void dispose() {
    _cancelAllTimers();
    _player.dispose();
    _sfxPlayer.dispose();
    _confettiController.dispose();
    _starController.dispose();
    super.dispose();
  }

  void _cancelAllTimers() {
    _autoPlayTimer?.cancel();
    _hintTimer?.cancel();
    _blinkTimer?.cancel();
    _autoPlayTimer = null;
    _hintTimer = null;
    _blinkTimer = null;
    _hintBlinkIndex = -1;
  }

  void _stopHintBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    if (mounted) {
      setState(() => _hintBlinkIndex = -1);
    } else {
      _hintBlinkIndex = -1;
    }
  }

  void _startNewRound() {
    _cancelAllTimers();

    _current = _items[_rng.nextInt(_items.length)];
    final pool = _items.where((e) => e.id != _current.id).toList()..shuffle(_rng);
    _choices = [_current, ...pool.take(3)]..shuffle(_rng);

    _soundPlayedThisRound = false;
    _roundSoundPlayedAt = null;

    setState(() {
      _feedback = "🔊 ශබ්දය ඇසීමට තට්ටු කරන්න";
      _locked = false;
      _showStar = false;
    });

    // ✅ Auto-play sound after 3 seconds if user doesn't press play
    _autoPlayTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_locked) return;
      if (_soundPlayedThisRound) return;
      _playSound(startedByAuto: true);
    });
  }

  Future<void> _playSound({bool startedByAuto = false}) async {
    _soundPlayedThisRound = true;
    _roundSoundPlayedAt = DateTime.now();

    // Stop autoplay timer once sound is played (manual or auto)
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;

    // Stop any previous hint blink
    _stopHintBlink();

    await _player.stop();
    await _player.play(AssetSource(_current.soundAsset));

    if (!mounted) return;
    setState(() {
      _feedback = "දැන් නිවැරදි රූපය තට්ටු කරන්න";
    });

    // ✅ Start hint timer (4 seconds after sound played)
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_locked) return; // user already tapped something
      _startBlinkHint();
    });
  }

  void _startBlinkHint() {
    _blinkTimer?.cancel();

    // find correct index
    final correctIndex = _choices.indexWhere((it) => it.id == _current.id);
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
      // 6 toggles = 3 blinks
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
      "[MATCH_SOUND_SCORE] event=$event questions=$_questionsPlayed correct=$_correctAnswers accuracy=${accuracy.toStringAsFixed(1)} avg_reaction_ms=$avgReactionMs samples=$_reactionSamples",
    );
  }

  Future<void> _goDashboard() async {
    _printAttemptStatsToTerminal(event: "home_exit");
    _cancelAllTimers();
    await _player.stop();
    await _sfxPlayer.stop();
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      '/home_cognitive',
      (route) => false,
    );
  }

  Future<void> _playRewardAnimation() async {
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource("sounds/cognitive/cheers.mp3"));

    setState(() => _showStar = true);

    _confettiController.play();
    await _starController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    setState(() => _showStar = false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CognitiveGameLoadingScreen(
          gameTitle: 'ශබ්දය අහලා රූපය තෝරමු',
          autoNavigate: false,
          duration: Duration(seconds: 4),
        ),
      ),
    );
  }

  void _onPick(SoundItem picked) async {
    if (_locked) return;

    final pickedAt = DateTime.now();

    // stop hint timer + blink immediately when user taps
    _hintTimer?.cancel();
    _hintTimer = null;
    _stopHintBlink();

    setState(() => _locked = true);

    final correct = picked.id == _current.id;

    setState(() {
      _questionsPlayed++;
      if (correct) {
        _correctAnswers++;
      }
      if (_roundSoundPlayedAt != null) {
        _totalReactionTime += pickedAt.difference(_roundSoundPlayedAt!);
        _reactionSamples++;
      }
    });
    _printAttemptStatsToTerminal(event: correct ? "answer_correct" : "answer_wrong");

    if (correct) {
      setState(() => _feedback = "හරි! හොඳ වැඩයි.");
      await _playRewardAnimation();
      if (!mounted) return;
      _startNewRound();
    } else {
      setState(() => _feedback = "❌ නැවත උත්සාහ කරන්න");
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _locked = false);

      // If sound was already played, restart hint timer for another 4 seconds
      if (_soundPlayedThisRound) {
        _hintTimer?.cancel();
        _hintTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          if (_locked) return;
          _startBlinkHint();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    final shortestSide = size.shortestSide;
    final isPortrait = height >= width;

    final scale = (shortestSide / 360).clamp(0.85, 1.2);
    final isNarrow = width < 340;
    final isWide = width >= 720;

    final horizontalPadding = (isWide ? 24.0 : 14.0) * scale;
    final verticalPadding = (isWide ? 20.0 : 14.0) * scale;
    final buttonHeight = (isNarrow ? 50.0 : 58.0) * scale;
    final titleFontSize = (isNarrow ? 17.0 : 20.0) * scale;
    final feedbackFontSize = (isNarrow ? 15.0 : 18.0) * scale;
    final gridSpacing = (isWide ? 16.0 : (isNarrow ? 8.0 : 12.0)) * scale;
    final cardPadding = (isNarrow ? 9.0 : 12.0) * scale;
    final cardRadius = (isNarrow ? 14.0 : 18.0) * scale;

    final crossAxisCount = width >= 900
        ? 4
        : width >= 720
            ? 3
            : 2;
    final childAspectRatio = isPortrait ? 1.0 : 1.15;
    final accuracy = _questionsPlayed == 0
        ? 0.0
        : (_correctAnswers / _questionsPlayed) * 100;
    final avgReaction = _reactionSamples == 0
        ? Duration.zero
        : Duration(
            milliseconds:
                (_totalReactionTime.inMilliseconds / _reactionSamples).round(),
          );
    final avgReactionSeconds = avgReaction.inMilliseconds / 1000.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ශබ්දය – රූපය ගැලපීම"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goDashboard,
        ),
        // actions: [
        //   IconButton(
        //     tooltip: "Print score to terminal",
        //     icon: const Icon(Icons.terminal),
        //     onPressed: () => _printAttemptStatsToTerminal(event: "manual_view"),
        //   ),
        // ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _locked ? null : () => _playSound(startedByAuto: false),
                    icon: const Icon(Icons.volume_up, size: 28),
                    label: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Text(
                        "ශබ්දය ප්‍රසංගය කරන්න",
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, buttonHeight),
                    ),
                  ),
                  // SizedBox(height: 10 * scale),
                  // Container(
                  //   width: double.infinity,
                  //   padding: EdgeInsets.all(12 * scale),
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(12 * scale),
                  //     color: Colors.blue.withOpacity(0.08),
                  //     border: Border.all(color: Colors.blue.withOpacity(0.16)),
                  //   ),
                    // child: Text(
                    //   "Questions: $_questionsPlayed   Correct: $_correctAnswers   Accuracy: ${accuracy.toStringAsFixed(1)}%   Avg reaction: ${avgReactionSeconds.toStringAsFixed(2)}s",
                    //   textAlign: TextAlign.center,
                    //   style: TextStyle(
                    //     fontSize: (isNarrow ? 13.0 : 14.0) * scale,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),
                  // ),
                  SizedBox(height: 10 * scale),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12 * scale),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12 * scale),
                      color: Colors.black.withOpacity(0.05),
                    ),
                    child: Text(
                      _feedback,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: feedbackFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 14 * scale),
                  Expanded(
                    child: GridView.builder(
                      itemCount: _choices.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: gridSpacing,
                        crossAxisSpacing: gridSpacing,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final item = _choices[index];
                        final blinkGreen = index == _hintBlinkIndex;

                        return _PictureCard(
                          imageAsset: item.imageAsset,
                          onTap: () => _onPick(item),
                          disabled: _locked,
                          blinkGreen: blinkGreen,
                          padding: cardPadding,
                          radius: cardRadius,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _goDashboard,
                          icon: const Icon(Icons.dashboard),
                          label: const Text("Home"),
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            _printAttemptStatsToTerminal(event: "restart_before_reset");
                            _cancelAllTimers();
                            await _player.stop();
                            await _sfxPlayer.stop();
                            if (!mounted) return;
                            setState(() {
                              _questionsPlayed = 0;
                              _correctAnswers = 0;
                              _totalReactionTime = Duration.zero;
                              _reactionSamples = 0;
                              _roundSoundPlayedAt = null;
                            });
                            _startNewRound();
                          },
                          icon: const Icon(Icons.restart_alt),
                          label: const Text("Restart"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                          "හරි! හොඳ වැඩයි.",
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

// =====================
// UI CARD
// =====================
class _PictureCard extends StatelessWidget {
  final String imageAsset;
  final VoidCallback onTap;
  final bool disabled;
  final bool blinkGreen;
  final double padding;
  final double radius;

  const _PictureCard({
    required this.imageAsset,
    required this.onTap,
    required this.disabled,
    required this.blinkGreen,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: blinkGreen ? Colors.green.withOpacity(0.35) : Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Image.asset(imageAsset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
