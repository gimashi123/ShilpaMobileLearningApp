import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

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
    with SingleTickerProviderStateMixin {
  final _rng = Random();

  final List<NumberItem> _items = const [
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

  late NumberItem _current;
  late List<NumberItem> _choices;

  String _feedback = "අංකයට ගැලපෙන වචනය තෝරන්න";
  Color _feedbackColor = Colors.black87;
  bool _locked = false;
  int _hintBlinkIndex = -1;
  Timer? _hintTimer;
  Timer? _blinkTimer;

  late final ConfettiController _confettiController;
  late final AnimationController _starController;
  late final Animation<double> _starScale;

  bool _showStar = false;
  int _rewardIndex = -1;

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
    _cancelHintTimers();
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
      if (!mounted) return;
      if (_locked) return;
      _startBlinkHint();
    });
  }

  void _startBlinkHint() {
    _blinkTimer?.cancel();

    final correctIndex =
        _choices.indexWhere((it) => it.value == _current.value);
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

  void _startNewRound() {
    _cancelHintTimers();
    _current = _items[_rng.nextInt(_items.length)];
    final pool = _items.where((e) => e.value != _current.value).toList()
      ..shuffle(_rng);
    _choices = [_current, ...pool.take(3)]..shuffle(_rng);

    setState(() {
      _feedback = "අංකයට ගැලපෙන වචනය තෝරන්න";
      _feedbackColor = Colors.black87;
      _locked = false;
      _showStar = false;
      _rewardIndex = -1;
    });

    _startHintTimer();
  }

  Future<void> _goDashboard() async {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      '/home_cognitive',
      (route) => false,
    );
  }

  Future<void> _playRewardAnimation() async {
    setState(() => _showStar = true);

    _confettiController.play();
    await _starController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    setState(() => _showStar = false);
  }

  Future<void> _onPick(NumberItem picked, int index) async {
    if (_locked) return;
    _cancelHintTimers();
    setState(() => _locked = true);

    final correct = picked.value == _current.value;

    if (correct) {
      setState(() {
        _feedback = "හරි! හොඳ වැඩයි.";
        _feedbackColor = Colors.green;
        _rewardIndex = index;
      });

      await _playRewardAnimation();
      if (!mounted) return;
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
    final titleFontSize = (isNarrow ? 18.0 : 22.0) * scale;
    final numberFontSize = (isNarrow ? 52.0 : 66.0) * scale;
    final feedbackFontSize = (isNarrow ? 15.0 : 18.0) * scale;
    final gridSpacing = (isWide ? 16.0 : (isNarrow ? 8.0 : 12.0)) * scale;
    final cardPadding = (isNarrow ? 9.0 : 12.0) * scale;
    final cardRadius = (isNarrow ? 14.0 : 18.0) * scale;

    final crossAxisCount = width >= 900
        ? 4
        : width >= 720
            ? 3
            : 2;
    final childAspectRatio = isPortrait ? 1.15 : 1.25;

    return Scaffold(
      appBar: AppBar(
        title: const Text("අංකය ගැලපීම"),
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
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14 * scale),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14 * scale),
                      color: Colors.black.withOpacity(0.05),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${_current.value}",
                          style: TextStyle(
                            fontSize: numberFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        color: _feedbackColor,
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
                        final rewardGlow = index == _rewardIndex;
                        final hintGlow = index == _hintBlinkIndex;

                        return _WordCard(
                          word: item.word,
                          onTap: () => _onPick(item, index),
                          disabled: _locked,
                          highlightGreen: rewardGlow || hintGlow,
                          padding: cardPadding,
                          radius: cardRadius,
                          titleFontSize: titleFontSize,
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
                      label: const Text("මුල් පිටුව"),
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _startNewRound,
                          icon: const Icon(Icons.restart_alt),
                      label: const Text("නැවත ආරම්භ කරන්න"),
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

class _WordCard extends StatelessWidget {
  final String word;
  final VoidCallback onTap;
  final bool disabled;
  final bool highlightGreen;
  final double padding;
  final double radius;
  final double titleFontSize;

  const _WordCard({
    required this.word,
    required this.onTap,
    required this.disabled,
    required this.highlightGreen,
    required this.padding,
    required this.radius,
    required this.titleFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: highlightGreen ? Colors.green.withOpacity(0.3) : Colors.white,
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
          child: Center(
            child: Text(
              word.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
