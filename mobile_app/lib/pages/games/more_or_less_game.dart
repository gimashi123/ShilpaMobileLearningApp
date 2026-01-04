import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MoreNumberSwipeGame(),
    );
  }
}

class MoreNumberSwipeGame extends StatefulWidget {
  const MoreNumberSwipeGame({super.key});

  @override
  State<MoreNumberSwipeGame> createState() => _MoreNumberSwipeGameState();
}

class _MoreNumberSwipeGameState extends State<MoreNumberSwipeGame> {
  final Random _rng = Random();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _fxPlayer = AudioPlayer();

  int leftNum = 0;
  int rightNum = 0;

  int score = 0;
  int wrongCount = 0;
  int round = 1;

  bool busy = false;
  bool waitingSwipe = false;

  final String _okSound = "assets/sounds/feedback/correct.mp3";
  final String _badSound = "assets/sounds/feedback/wrong.mp3";

  @override
  void initState() {
    super.initState();
    _initTts();
    Future.delayed(const Duration(milliseconds: 400), () async {
      await _playGuide();
      await _startRound();
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _fxPlayer.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("si-LK");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _haptic() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  String _fixAsset(String p) => p.startsWith("assets/") ? p.substring(7) : p;

  Future<void> _playFx(String asset) async {
    try {
      await _fxPlayer.stop();
      await _fxPlayer.play(AssetSource(_fixAsset(asset)));
    } catch (e) {
      debugPrint("Sound error: $e");
    }
  }

  void _pickTwoNumbers() {
    int a = _rng.nextInt(20) + 1;
    int b = _rng.nextInt(20) + 1;
    while (b == a) {
      b = _rng.nextInt(20) + 1;
    }
    leftNum = a;
    rightNum = b;
  }

  Future<void> _playGuide() async {
    await _speak(
      "මෙම ක්‍රීඩාවේ අංක දෙකක් කියනවා. "
      "වම් පැත්තේ අංකයයි, දකුණු පැත්තේ අංකයයි. "
      "වැඩි අංකය තියෙන පැත්ත තෝරන්න. "
      "වැඩි එක වම් පැත්තේ නම් වම් පැත්තට ස්වයිප් කරන්න. "
      "වැඩි එක දකුණු පැත්තේ නම් දකුණු පැත්තට ස්වයිප් කරන්න.",
    );
  }

  Future<void> _startRound() async {
    if (!mounted) return;

    setState(() {
      busy = true;
      waitingSwipe = false;
    });

    _pickTwoNumbers();
    await _haptic();

    await _speak(
      "වම් පැත්තේ $leftNum. දකුණු පැත්තේ $rightNum. වැඩි එක තෝරන්න.",
    );

    if (!mounted) return;

    setState(() {
      busy = false;
      waitingSwipe = true;
    });
  }

  Future<void> _judge({required bool choseLeft}) async {
    if (busy || !waitingSwipe) return;

    setState(() {
      busy = true;
      waitingSwipe = false;
    });

    final bool leftIsMore = leftNum > rightNum;
    final bool correct =
        (choseLeft && leftIsMore) || (!choseLeft && !leftIsMore);

    final String biggerSide = leftIsMore ? "වම් පැත්තේ" : "දකුණු පැත්තේ";
    final int biggerNum = leftIsMore ? leftNum : rightNum;

    await _haptic();

    if (correct) {
      score++;
      await _playFx(_okSound);
      await _speak("ඔබගේ පිළිතුර නිවැරදි. වැඩි අංකය $biggerSide $biggerNum.");
    } else {
      wrongCount++;
      await _playFx(_badSound);
      await _speak("ඔබගේ පිළිතුර වැරදි. වැඩි අංකය $biggerSide $biggerNum.");

      if (wrongCount >= 3) {
        _showGameOver();
        return;
      }
    }

    if (!mounted) return;
    setState(() => round++);
    await _startRound();
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("⛔ Game Over"),
        content: Text("Score: $score\nWrong: $wrongCount / 3"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                score = 0;
                wrongCount = 0;
                round = 1;
              });
              _startRound();
            },
            child: const Text("Restart"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🔊 වැඩි අංකය තෝරන්න"),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 200) return;
          v > 0 ? _judge(choseLeft: false) : _judge(choseLeft: true);
        },
        child: Center(
          child: Text(
            "Swipe LEFT or RIGHT",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
