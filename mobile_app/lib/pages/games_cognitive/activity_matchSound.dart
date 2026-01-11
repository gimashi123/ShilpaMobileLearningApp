import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../dashboard/cognitive_dashboard_screen.dart';

void main() {
  runApp(const SoundPictureMatchApp());
}

class SoundPictureMatchApp extends StatelessWidget {
  const SoundPictureMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ශබ්දය – රූපය ගැලපීම',
      theme: ThemeData(useMaterial3: true),
      home: const SoundPictureMatchGame(),
    );
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

class _SoundPictureMatchGameState extends State<SoundPictureMatchGame> {
  final _rng = Random();
  final AudioPlayer _player = AudioPlayer();

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

  // Timers
  Timer? _autoPlayTimer; // 3s autoplay if user doesn't press Play Sound
  Timer? _hintTimer; // 4s hint after sound is played
  Timer? _blinkTimer; // blink correct option background
  bool _soundPlayedThisRound = false;

  // Hint blink
  int _hintBlinkIndex = -1;

  @override
  void initState() {
    super.initState();
    _startNewRound();
  }

  @override
  void dispose() {
    _cancelAllTimers();
    _player.dispose();
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

    setState(() {
      _feedback = "🔊 ශබ්දය ඇසීමට තට්ටු කරන්න";
      _locked = false;
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

  Future<void> _goDashboard() async {
    _cancelAllTimers();
    await _player.stop();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CognitiveDashboardScreen()),
    );
  }

  void _onPick(SoundItem picked) async {
    if (_locked) return;

    // stop hint timer + blink immediately when user taps
    _hintTimer?.cancel();
    _hintTimer = null;
    _stopHintBlink();

    setState(() => _locked = true);

    final correct = picked.id == _current.id;

    if (correct) {
      setState(() => _feedback = "✅ Correct!");
      await Future.delayed(const Duration(milliseconds: 900));
      _startNewRound();
    } else {
      setState(() => _feedback = "❌ Try again");
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _locked = false);

      // If sound was already played, restart hint timer for another 4 seconds
      if (_soundPlayedThisRound) {
        _hintTimer?.cancel();
        _hintTimer = Timer(const Duration(seconds: 4), () {
          if (!mounted) return;
          if (_locked) return;
          _startBlinkHint();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ශබ්දය – රූපය ගැලපීම"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goDashboard,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _locked ? null : () => _playSound(startedByAuto: false),
              icon: const Icon(Icons.volume_up, size: 28),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Text(
                  "ශබ්දය ප්‍රසංගය කරන්න",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                itemCount: _choices.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final item = _choices[index];
                  final blinkGreen = index == _hintBlinkIndex;

                  return _PictureCard(
                    imageAsset: item.imageAsset,
                    onTap: () => _onPick(item),
                    disabled: _locked,
                    blinkGreen: blinkGreen,
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
                    onPressed: () async {
                      _cancelAllTimers();
                      await _player.stop();
                      if (!mounted) return;
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

  const _PictureCard({
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
