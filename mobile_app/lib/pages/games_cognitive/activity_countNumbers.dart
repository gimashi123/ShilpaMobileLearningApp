import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SinhalaNumberGame extends StatefulWidget {
  const SinhalaNumberGame({super.key});

  @override
  State<SinhalaNumberGame> createState() => _SinhalaNumberGameState();
}

class _SinhalaNumberGameState extends State<SinhalaNumberGame>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();

  final List<int> _numbers = List.generate(10, (i) => i + 1);
  final List<String> _siWords = const [
    "එක",
    "දෙක",
    "තුන",
    "හතර",
    "පහ",
    "හය",
    "හත",
    "අට",
    "නවය",
    "දහය",
  ];

  // Teaching-style syllable chunks (last item is full word)
  final Map<int, List<String>> _syllables = const {
    1: ["එ", "ක", "එක"],
    2: ["දෙ", "ක", "දෙක"],
    3: ["තු", "න", "තුන"],
    4: ["හ", "ත", "ර", "හතර"],
    5: ["ප", "හ", "පහ"],
    6: ["හ", "ය", "හය"],
    7: ["හ", "ත", "හත"],
    8: ["අ", "ට", "අට"],
    9: ["න", "ව", "ය", "නවය"],
    10: ["ද", "හ", "ය", "දහය"],
  };

  int _index = 0;

  bool _isSpeakingHighlight = false;
  late final AnimationController _pulse;

  int _runToken = 0;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _setupTts().then((_) {
      _startAutoSequence();
    });
  }

  Future<void> _setupTts() async {
    // Wait for TTS to finish each speak() before continuing
    await _tts.awaitSpeakCompletion(true);

    // Try Sinhala Sri Lanka. If device doesn't support, it may ignore.
    try {
      await _tts.setLanguage("si-LK");
    } catch (_) {}

    // Slower for children
    await _tts.setSpeechRate(0.40);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  @override
  void dispose() {
    _runToken++; // cancel any running loops
    _pulse.dispose();
    _tts.stop();
    super.dispose();
  }

  int get currentNumber => _numbers[_index];
  String get currentWord => _siWords[_index];

  void _setHighlight(bool on) {
    if (!mounted) return;
    setState(() => _isSpeakingHighlight = on);

    if (on) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      if (_pulse.isAnimating) _pulse.stop();
      _pulse.value = 0;
    }
  }

  // Speak in teaching style:
  // "එ..." (pause) "ක..." (pause) "එක"
  Future<void> _speakTeachingStyle(int number, {int partGapMs = 800}) async {
    final parts = _syllables[number];
    if (parts == null) return;

    for (int i = 0; i < parts.length; i++) {
      if (!mounted) return;

      // Shine while speaking each chunk
      _setHighlight(true);

      await _tts.stop();
      await _tts.speak(parts[i]);

      // wait until this chunk finishes
      // (awaitSpeakCompletion is already enabled)
      // Still keep a small delay to ensure UI updates smoothly.
      _setHighlight(false);

      // gap between syllables/chunks
      await Future.delayed(Duration(milliseconds: partGapMs));
    }
  }

  Future<void> _startAutoSequence() async {
    final int myToken = ++_runToken;

    while (mounted && myToken == _runToken) {
      // Repeat 5 times for the current number
      for (int r = 0; r < 5; r++) {
        if (!mounted || myToken != _runToken) return;

        // Speak syllables then full word (child-friendly)
        await _speakTeachingStyle(currentNumber, partGapMs: 800);

        if (!mounted || myToken != _runToken) return;

        // 2 seconds gap between voice commands (your requirement)
        await Future.delayed(const Duration(seconds: 2));
      }

      if (!mounted || myToken != _runToken) return;

      // 2 seconds break after finishing 5 repetitions (your requirement)
      await Future.delayed(const Duration(seconds: 2));

      // Move to next number
      if (_index < _numbers.length - 1) {
        setState(() => _index++);
      } else {
        return; // finished 1..10
      }
    }
  }

  void _restartFromIndex(int newIndex) {
    if (newIndex < 0 || newIndex >= _numbers.length) return;

    _runToken++; // cancel old loop
    _tts.stop();
    _setHighlight(false);

    setState(() => _index = newIndex);

    _startAutoSequence();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            const Text(
              "maths related activities",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),

            // Green header
            Container(
              height: 56,
              color: const Color(0xFF2E8B34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      "ගණන් කරමු",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Purple main area
            Expanded(
              child: Container(
                color: const Color(0xFF6D49A6),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    final double glow = _isSpeakingHighlight
                        ? (0.25 + 0.75 * _pulse.value)
                        : 0;

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CardBox(
                            text: currentWord,
                            big: false,
                            glow: glow,
                            highlighted: _isSpeakingHighlight,
                          ),
                          const SizedBox(height: 80),
                          _CardBox(
                            text: "$currentNumber",
                            big: true,
                            glow: glow,
                            highlighted: _isSpeakingHighlight,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom green bar
            Container(
              height: 70,
              color: const Color(0xFF2E8B34),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BottomButton(
                    label: "අවසාන",
                    onTap: () => _restartFromIndex(_index - 1),
                  ),
                  _BottomButton(
                    label: "ඊළඟ",
                    onTap: () => _restartFromIndex(_index + 1),
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

class _CardBox extends StatelessWidget {
  final String text;
  final bool big;
  final bool highlighted;
  final double glow;

  const _CardBox({
    required this.text,
    required this.big,
    required this.highlighted,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final double size = big ? 120 : 100;

    final Color borderColor = highlighted
        ? const Color(0xFFFFD54F)
        : Colors.transparent;

    final double borderWidth = highlighted ? (2.5 + 3.0 * glow) : 2.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: const Color(
                    0xFFFFD54F,
                  ).withOpacity(0.35 + 0.35 * glow),
                  blurRadius: 12 + 18 * glow,
                  spreadRadius: 1 + 3 * glow,
                ),
              ]
            : [],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: big ? 54 : 34,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BottomButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
