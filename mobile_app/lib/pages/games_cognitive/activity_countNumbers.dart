import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../dashboard/cognitive_dashboard_screen.dart';

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

  /// Teaching chunks that Sinhala TTS pronounces more reliably than single letters.
  /// (This also solves the “some letters are not spelled” issue.)
  /// Last item is the FULL WORD.
  final Map<int, List<String>> _teachChunks = const {
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

  /// What we show as “slots” on screen (aligned boxes).
  /// For words like "හතර" we show 3 slots and reveal: හ / ත / ර (then full word spoken).
  /// For 1..3,5..8 we show 2 slots.
  /// For 9,10 we show 3 slots.
  final Map<int, int> _slots = const {
    1: 2,
    2: 2,
    3: 2,
    4: 3,
    5: 2,
    6: 2,
    7: 2,
    8: 2,
    9: 3,
    10: 3,
  };

  int _index = 0;
  int _revealed = 0; // how many chunks are revealed on screen (NOT counting full word)

  bool _highlight = false;
  late final AnimationController _pulse;

  int _runToken = 0;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _setupTts().then((_) => _startAuto());
  }

  Future<void> _setupTts() async {
    await _tts.awaitSpeakCompletion(true);

    try {
      await _tts.setLanguage("si-LK");
    } catch (_) {}

    // Clearer output for many devices:
    await _tts.setSpeechRate(0.38);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    // If device has multiple voices, try to pick a Sinhala one
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        for (final v in voices) {
          if (v is Map && (v["locale"]?.toString() == "si-LK")) {
            await _tts.setVoice(Map<String, String>.from({
              "name": v["name"].toString(),
              "locale": v["locale"].toString(),
            }));
            break;
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _runToken++;
    _pulse.dispose();
    _tts.stop();
    super.dispose();
  }

  int get currentNumber => _numbers[_index];
  String get currentWord => _siWords[_index];

  void _setHighlight(bool on) {
    if (!mounted) return;
    setState(() => _highlight = on);
    if (on) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      if (_pulse.isAnimating) _pulse.stop();
      _pulse.value = 0;
    }
  }

  List<String> _currentVisibleChunks() {
    // We use the chunks except the last one (full word)
    final chunks = _teachChunks[currentNumber] ?? const [];
    if (chunks.isEmpty) return const [];

    // Everything except last item is “step chunks”
    final stepChunks = chunks.sublist(0, chunks.length - 1);

    final neededSlots = _slots[currentNumber] ?? stepChunks.length;

    // Ensure we have exactly neededSlots for display
    if (stepChunks.length == neededSlots) return stepChunks;

    // If mismatch, trim or pad (safe)
    if (stepChunks.length > neededSlots) {
      return stepChunks.sublist(0, neededSlots);
    } else {
      return [
        ...stepChunks,
        ...List.filled(neededSlots - stepChunks.length, ""),
      ];
    }
  }

  Future<void> _teachStepByStep(int number) async {
    final chunks = _teachChunks[number];
    if (chunks == null || chunks.isEmpty) return;

    final stepChunks = chunks.sublist(0, chunks.length - 1);
    final fullWord = chunks.last;

    // Reset UI reveal
    if (!mounted) return;
    setState(() => _revealed = 0);

    // Speak each chunk and reveal one slot
    for (int i = 0; i < stepChunks.length; i++) {
      if (!mounted) return;

      // reveal on UI (do not reveal more than slot count)
      final maxSlots = _slots[number] ?? stepChunks.length;
      final revealCount = (i + 1) > maxSlots ? maxSlots : (i + 1);
      setState(() => _revealed = revealCount);

      _setHighlight(true);
      await _tts.stop();
      await _tts.speak(stepChunks[i]);
      _setHighlight(false);

      // Longer pause so letters don’t get cut
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // Speak full word at the end
    _setHighlight(true);
    await _tts.speak(fullWord);
    _setHighlight(false);

    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _startAuto() async {
    final myToken = ++_runToken;

    while (mounted && myToken == _runToken) {
      // repeat 5 times per number
      for (int r = 0; r < 5; r++) {
        if (!mounted || myToken != _runToken) return;
        await _teachStepByStep(currentNumber);
        await Future.delayed(const Duration(seconds: 2));
      }

      if (!mounted || myToken != _runToken) return;

      // move to next number
      if (_index < _numbers.length - 1) {
        setState(() {
          _index++;
          _revealed = 0;
        });
      } else {
        return;
      }
    }
  }

  void _restartFromIndex(int newIndex) {
    if (newIndex < 0 || newIndex >= _numbers.length) return;

    _runToken++;
    _tts.stop();
    _setHighlight(false);

    setState(() {
      _index = newIndex;
      _revealed = 0;
    });

    _startAuto();
  }

  @override
  Widget build(BuildContext context) {
    final visibleChunks = _currentVisibleChunks();
    final slotCount = visibleChunks.isEmpty ? 2 : visibleChunks.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
          

            // Green header
            Container(
              height: 56,
              color: const Color(0xFF2E8B34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const CognitiveDashboardScreen()),  // Assuming the class name is CognitiveDashboardScreen
                    ),
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

            // Main area
            Expanded(
              child: Container(
                color: const Color(0xFF6D49A6),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    final glow = _highlight ? (0.25 + 0.75 * _pulse.value) : 0.0;

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SlotsCard(
                            slotCount: slotCount,
                            revealed: _revealed,
                            items: visibleChunks,
                            glow: glow,
                            highlighted: _highlight,
                          ),
                          const SizedBox(height: 80),
                          _CardBox(
                            text: "$currentNumber",
                            big: true,
                            glow: glow,
                            highlighted: _highlight,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom bar
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

class _SlotsCard extends StatelessWidget {
  final int slotCount;
  final int revealed;
  final List<String> items;
  final bool highlighted;
  final double glow;

  const _SlotsCard({
    required this.slotCount,
    required this.revealed,
    required this.items,
    required this.highlighted,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted ? const Color(0xFFFFD54F) : Colors.transparent;
    final borderWidth = highlighted ? (2.5 + 3.0 * glow) : 2.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withOpacity(0.35 + 0.35 * glow),
                  blurRadius: 12 + 18 * glow,
                  spreadRadius: 1 + 3 * glow,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(slotCount, (i) {
          final bool show = i < revealed;
          final String v = (i < items.length) ? items[i] : "";
          return Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12, width: 2),
            ),
            child: Text(
              show ? v : "_",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          );
        }),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withOpacity(0.35 + 0.35 * glow),
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
