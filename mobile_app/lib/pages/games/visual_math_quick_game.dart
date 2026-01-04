import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NumberMatchLevelsSound(),
    );
  }
}

class NumberMatchLevelsSound extends StatefulWidget {
  const NumberMatchLevelsSound({super.key});

  @override
  State<NumberMatchLevelsSound> createState() => _NumberMatchLevelsSoundState();
}

class PairItem {
  final String id;
  final String quiz;
  final String answer;
  final String soundAsset; // full asset path

  const PairItem({
    required this.id,
    required this.quiz,
    required this.answer,
    required this.soundAsset,
  });
}

class _NumberMatchLevelsSoundState extends State<NumberMatchLevelsSound> {
  final Random _rng = Random();

  final AudioPlayer _pairPlayer = AudioPlayer();
  final AudioPlayer _feedbackPlayer = AudioPlayer();

  int round = 1;
  int score = 0;
  bool _busy = false;

  // ✅ USE assets/ prefix
  final List<PairItem> allPairs = const [
    PairItem(
      id: 'p1',
      quiz: '6 ÷ 2',
      answer: '3',
      soundAsset: 'assets/sounds/pairs/p1.mp3',
    ),
    PairItem(
      id: 'p2',
      quiz: '4 + 5',
      answer: '9',
      soundAsset: 'assets/sounds/pairs/p2.mp3',
    ),
    PairItem(
      id: 'p3',
      quiz: '3 × 2',
      answer: '6',
      soundAsset: 'assets/sounds/pairs/p3.mp3',
    ),
    PairItem(
      id: 'p4',
      quiz: '8 − 3',
      answer: '5',
      soundAsset: 'assets/sounds/pairs/p4.mp3',
    ),
    PairItem(
      id: 'p5',
      quiz: '7 + 1',
      answer: '8',
      soundAsset: 'assets/sounds/pairs/p5.mp3',
    ),
  ];

  List<PairItem> left = [];
  List<PairItem> right = [];

  String? selectedQuizId;
  String? selectedAnswerId;

  final Set<String> matched = {};

  @override
  void initState() {
    super.initState();
    loadRound();
  }

  @override
  void dispose() {
    _pairPlayer.dispose();
    _feedbackPlayer.dispose();
    super.dispose();
  }

  void loadRound() {
    final pairCount = min(round + 1, 5);
    final current = allPairs.take(pairCount).toList();

    left = [...current]..shuffle(_rng);
    right = [...current]..shuffle(_rng);

    selectedQuizId = null;
    selectedAnswerId = null;
    matched.clear();
    _busy = false;

    if (mounted) setState(() {});
  }

  Future<void> playAsset(AudioPlayer player, String fullAssetPath) async {
    try {
      // AssetSource expects path WITHOUT "assets/" in some versions,
      // but safest approach is: remove "assets/" prefix.
      final fixed = fullAssetPath.startsWith('assets/')
          ? fullAssetPath.substring(7)
          : fullAssetPath;

      debugPrint("▶ Playing: $fixed");
      await player.stop();
      await player.play(AssetSource(fixed));
    } catch (e) {
      debugPrint("❌ Audio error: $e");
    }
  }

  Future<void> playPair(PairItem item) async {
    await playAsset(_pairPlayer, item.soundAsset);
  }

  Future<void> playFeedback(bool correct) async {
    final path = correct
        ? 'assets/sounds/feedback/correct.mp3'
        : 'assets/sounds/feedback/wrong.mp3';
    await playAsset(_feedbackPlayer, path);
  }

  Future<void> tapQuiz(PairItem item) async {
    if (_busy || matched.contains(item.id)) return;

    setState(() => selectedQuizId = item.id);
    await playPair(item);
    await _tryMatch();
  }

  Future<void> tapAnswer(PairItem item) async {
    if (_busy || matched.contains(item.id)) return;

    setState(() => selectedAnswerId = item.id);
    await playPair(item);
    await _tryMatch();
  }

  Future<void> _tryMatch() async {
    if (selectedQuizId == null || selectedAnswerId == null) return;

    _busy = true;

    final correct = selectedQuizId == selectedAnswerId;
    debugPrint(
      "MATCH? quiz=$selectedQuizId answer=$selectedAnswerId => $correct",
    );

    if (correct) {
      matched.add(selectedQuizId!);
      score++;
      await playFeedback(true);
    } else {
      await playFeedback(false);
    }

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    setState(() {
      selectedQuizId = null;
      selectedAnswerId = null;
    });

    _busy = false;

    if (matched.length == left.length) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      if (round < 5) {
        setState(() => round++);
        loadRound();
      } else {
        _showCompletedDialog();
      }
    }
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Completed'),
        content: Text('Score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                round = 1;
                score = 0;
              });
              loadRound();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  Color cardColor(bool isMatched, bool isSelected, bool leftSide) {
    if (isMatched) return Colors.green;
    if (isSelected)
      return leftSide ? Colors.blue.shade200 : Colors.orange.shade200;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔢 Number Match Board'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              'Round $round / 5   |   Score: $score',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Checking...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      children: left.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            onTap: () => tapQuiz(e),
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: cardColor(
                                  matched.contains(e.id),
                                  selectedQuizId == e.id,
                                  true,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Center(
                                child: Text(
                                  e.quiz,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ListView(
                      children: right.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            onTap: () => tapAnswer(e),
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: cardColor(
                                  matched.contains(e.id),
                                  selectedAnswerId == e.id,
                                  false,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Center(
                                child: Text(
                                  e.answer,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}
