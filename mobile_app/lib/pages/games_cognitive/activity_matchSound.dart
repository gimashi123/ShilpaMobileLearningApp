import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:mobile_app/pages/games_cognitive/cognitive_game_loading_screen.dart';
import 'hand_hint_overlay.dart';

class SoundPictureMatchApp extends StatelessWidget {
  const SoundPictureMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SoundPictureMatchGame();
  }
}

class SoundItem {
  final String id;
  final String soundAsset;
  final String imageAsset;

  const SoundItem({
    required this.id,
    required this.soundAsset,
    required this.imageAsset,
  });
}

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

  // Keys for hint tracking
  final List<GlobalKey> _cardKeys = List.generate(4, (index) => GlobalKey());
  bool _showHandHint = false;

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

  Timer? _autoPlayTimer;
  Timer? _hintTimer;
  Timer? _blinkTimer;
  bool _soundPlayedThisRound = false;
  int _hintBlinkIndex = -1;

  int _questionsPlayed = 0;
  int _correctAnswers = 0;
  Duration _totalReactionTime = Duration.zero;
  int _reactionSamples = 0;
  DateTime? _roundSoundPlayedAt;

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
    if (mounted) setState(() => _hintBlinkIndex = -1);
  }

  void _startNewRound() {
    _cancelAllTimers();
    _current = _items[_rng.nextInt(_items.length)];
    final pool = _items.where((e) => e.id != _current.id).toList()
      ..shuffle(_rng);
    _choices = [_current, ...pool.take(3)]..shuffle(_rng);

    _soundPlayedThisRound = false;
    _roundSoundPlayedAt = null;

    setState(() {
      _showHandHint = false; // Reset hand hint
      _feedback = "🔊 ශබ්දය ඇසීමට තට්ටු කරන්න";
      _locked = false;
      _showStar = false;
    });

    _autoPlayTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _locked || _soundPlayedThisRound) return;
      _playSound(startedByAuto: true);
    });
  }

  Future<void> _playSound({bool startedByAuto = false}) async {
    _soundPlayedThisRound = true;
    _roundSoundPlayedAt = DateTime.now();
    _autoPlayTimer?.cancel();
    _stopHintBlink();

    await _player.stop();
    await _player.play(AssetSource(_current.soundAsset));

    if (!mounted) return;
    setState(() => _feedback = "දැන් නිවැරදි රූපය තට්ටු කරන්න");

    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _locked) return;
      _startBlinkHint();
    });
  }

  void _startBlinkHint() {
    _blinkTimer?.cancel();
    final correctIndex = _choices.indexWhere((it) => it.id == _current.id);
    if (correctIndex == -1) return;

    // Trigger both Blinking and Hand Animation
    setState(() {
      _showHandHint = true;
      _hintBlinkIndex = correctIndex;
    });

    int toggles = 0;
    bool on = false;
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      on = !on;
      setState(() => _hintBlinkIndex = on ? correctIndex : -1);
      toggles++;
      if (toggles >= 6) {
        t.cancel();
        setState(() => _hintBlinkIndex = -1);
      }
    });
  }

  void _onPick(SoundItem picked) async {
    if (_locked) return;
    final pickedAt = DateTime.now();

    _hintTimer?.cancel();
    _stopHintBlink();

    setState(() {
      _locked = true;
      _showHandHint = false; // Remove hand hint on selection
    });

    final correct = picked.id == _current.id;
    setState(() {
      _questionsPlayed++;
      if (correct) _correctAnswers++;
      if (_roundSoundPlayedAt != null) {
        _totalReactionTime += pickedAt.difference(_roundSoundPlayedAt!);
        _reactionSamples++;
      }
    });

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

      if (_soundPlayedThisRound) {
        _hintTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && !_locked) _startBlinkHint();
        });
      }
    }
  }

  Future<void> _goDashboard() async {
    _cancelAllTimers();
    await _player.stop();
    await _sfxPlayer.stop();
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/home_cognitive', (route) => false);
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
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = (size.shortestSide / 360).clamp(0.85, 1.2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ශබ්දය – රූපය ගැලපීම"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goDashboard,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16 * scale),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _locked ? null : () => _playSound(),
                    icon: const Icon(Icons.volume_up, size: 28),
                    label: const Text("ශබ්දය ප්‍රසංගය කරන්න"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(0.05),
                    ),
                    child: Text(
                      _feedback,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: GridView.builder(
                      itemCount: _choices.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemBuilder: (context, index) {
                        return _PictureCard(
                          key: _cardKeys[index], // KEY ASSIGNED HERE
                          imageAsset: _choices[index].imageAsset,
                          onTap: () => _onPick(_choices[index]),
                          disabled: _locked,
                          blinkGreen: index == _hintBlinkIndex,
                        );
                      },
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
                          onPressed: _startNewRound,
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
              ),
            ),
            if (_showStar)
              Center(
                child: ScaleTransition(scale: _starScale, child: _RewardBox()),
              ),

            // HAND HINT OVERLAY
            if (_showHandHint)
              HandHintOverlay(
                targetKey:
                    _cardKeys[_choices.indexWhere(
                      (it) => it.id == _current.id,
                    )],
                onFinished: () => setState(() => _showHandHint = false),
              ),
          ],
        ),
      ),
    );
  }
}

class _PictureCard extends StatelessWidget {
  final String imageAsset;
  final VoidCallback onTap;
  final bool disabled;
  final bool blinkGreen;

  const _PictureCard({
    super.key,
    required this.imageAsset,
    required this.onTap,
    required this.disabled,
    required this.blinkGreen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
          padding: const EdgeInsets.all(12),
          child: Image.asset(imageAsset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _RewardBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text("⭐", style: TextStyle(fontSize: 72)),
          SizedBox(height: 6),
          Text(
            "හරි! හොඳ වැඩයි.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
