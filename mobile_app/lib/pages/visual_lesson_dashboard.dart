import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_app/widgets/top_nav_bar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VisualLessonDashboard extends StatefulWidget {
  const VisualLessonDashboard({super.key});

  @override
  State<VisualLessonDashboard> createState() => _VisualLessonDashboardState();
}

class _VisualLessonDashboardState extends State<VisualLessonDashboard> {
  final FlutterTts _tts = FlutterTts();

  // ✅ Native vibration channel (Android)
  static const MethodChannel _vibChannel = MethodChannel('app.vibration/native');

  // ✅ Speech-to-text
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  String _lastHeard = "";

  // ✅ double-tap confirm state
  String? _armedKey;
  DateTime? _armedAt;
  static const Duration _doubleTapWindow = Duration(seconds: 2);

  static const String _swipeHint = "නැවත Home පිටුවට යාමට වමට swap කරන්න";
  static const String _voiceHint =
      "ඔබට ගණිතය, සිංහල, පාඩම්, Games, ප්‍රශ්න, Profile කියලා කියලාත් පිටුවට යන්න පුළුවන්";

  @override
  void initState() {
    super.initState();
    _setupTts();
    _initSpeech();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _tts.stop();
        await _tts.speak("$_swipeHint. $_voiceHint");
      } catch (_) {}
    });
  }

  Future<void> _setupTts() async {
    try {
      await _tts.setLanguage("si-LK");
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> _initSpeech() async {
    try {
      _speechReady = await _stt.initialize(
        onStatus: (s) {
          if (s == "notListening" && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() {});
    } catch (_) {
      _speechReady = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _vibrate([int ms = 60]) async {
    try {
      await _vibChannel.invokeMethod('vibrate', {"ms": ms});
    } catch (_) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  bool _isArmed(String key) {
    if (_armedKey != key || _armedAt == null) return false;
    return DateTime.now().difference(_armedAt!) <= _doubleTapWindow;
  }

  Future<void> _confirmTap({
    required String key,
    required String voiceText,
    required VoidCallback navigate,
  }) async {
    await _vibrate(60);

    if (_isArmed(key)) {
      setState(() {
        _armedKey = null;
        _armedAt = null;
      });
      try {
        await _tts.stop();
      } catch (_) {}
      navigate();
      return;
    }

    setState(() {
      _armedKey = key;
      _armedAt = DateTime.now();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(voiceText),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      await _tts.stop();
      await _tts.speak(voiceText);
    } catch (_) {}
  }

  Future<void> _goHomeBySwipe() async {
    await _vibrate(60);
    try {
      await _tts.stop();
      await _tts.speak("Home පිටුවට යනවා");
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home_visual');
  }

  Future<void> _handleVoiceCommand(String text) async {
    final t = text.trim().toLowerCase();
    bool has(String w) => t.contains(w);

    String? route;
    String? spoken;

    if (has("ගණිත") || has("math")) {
      route = "/math_lessons";
      spoken = "ගණිතය පිටුවට යනවා";
    } else if (has("සිංහල") || has("sinhala")) {
      route = "/quiz";
      spoken = "සිංහල පිටුවට යනවා";
    } else if (has("පාඩම්") || has("lesson")) {
      route = "/lessons";
      spoken = "පාඩම් පිටුවට යනවා";
    } else if (has("ගේම්") || has("games") || has("game")) {
      route = "/games";
      spoken = "Games පිටුවට යනවා";
    } else if (has("ප්‍රශ්න") || has("quiz")) {
      route = "/quiz";
      spoken = "ප්‍රශ්න පිටුවට යනවා";
    } else if (has("ප්‍රොෆයිල්") || has("profile")) {
      route = "/profile";
      spoken = "Profile පිටුවට යනවා";
    } else if (has("හෝම්") || has("home")) {
      route = "/home_visual";
      spoken = "Home පිටුවට යනවා";
    }

    if (route == null) return;

    await _stopListening();

    await _vibrate(70);
    try {
      await _tts.stop();
      await _tts.speak(spoken!);
    } catch (_) {}

    if (!mounted) return;

    if (route == "/math_lessons") {
      Navigator.pushNamed(context, route);
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Future<void> _startListening() async {
    if (!_speechReady) {
      await _initSpeech();
      if (!_speechReady) {
        try {
          await _tts.stop();
          await _tts.speak("Voice පහසුකම ලබාගත නොහැක");
        } catch (_) {}
        return;
      }
    }

    await _vibrate(50);

    setState(() {
      _isListening = true;
      _lastHeard = "";
    });

    await _stt.listen(
      localeId: "si_LK",
      listenFor: const Duration(seconds: 6),
      pauseFor: const Duration(seconds: 2),
      onResult: (res) {
        final words = res.recognizedWords;
        if (words.isEmpty) return;

        setState(() => _lastHeard = words);

        if (res.finalResult) {
          _handleVoiceCommand(words);
        }
      },
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    try {
      await _stt.stop();
    } catch (_) {}
    if (mounted) setState(() => _isListening = false);
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  void dispose() {
    _stopListening();
    _tts.stop();
    super.dispose();
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        _confirmTap(
          key: "nav_home",
          voiceText: "Home පිටුවට යාමට නැවත tap කරන්න",
          navigate: () => Navigator.pushReplacementNamed(context, '/home_visual'),
        );
        break;
      case 1:
        _confirmTap(
          key: "nav_lessons",
          voiceText: "පාඩම් පිටුවට යාමට නැවත tap කරන්න",
          navigate: () => Navigator.pushReplacementNamed(context, '/lessons'),
        );
        break;
      case 2:
        _confirmTap(
          key: "nav_games",
          voiceText: "Games පිටුවට යාමට නැවත tap කරන්න",
          navigate: () => Navigator.pushReplacementNamed(context, '/games'),
        );
        break;
      case 3:
        _confirmTap(
          key: "nav_quiz",
          voiceText: "ප්‍රශ්න පිටුවට යාමට නැවත tap කරන්න",
          navigate: () => Navigator.pushReplacementNamed(context, '/quiz'),
        );
        break;
      case 4:
        _confirmTap(
          key: "nav_profile",
          voiceText: "Profile පිටුවට යාමට නැවත tap කරන්න",
          navigate: () => Navigator.pushReplacementNamed(context, '/profile'),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool mathArmed = _isArmed("card_math");
    final bool sinhalaArmed = _isArmed("card_sinhala");

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -200) {
              _goHomeBySwipe();
            }
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),

                // ✅ FIXED NAVBAR CALL: add required args
                child: TopNavBar(
                  selectedTab: 1,
                  onTapTab: _onNavTap,
                  highContrast: false,
                  fontSize: 18,
                  title: "පාඩම්",
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Choose a Section",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_isListening || _lastHeard.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isListening ? "Listening...  $_lastHeard" : "Heard: $_lastHeard",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _CardItem(
                        title: "ගණිතය",
                        icon: Icons.calculate,
                        isArmed: mathArmed,
                        onTap: () {
                          _confirmTap(
                            key: "card_math",
                            voiceText: "ගණිතය පිටුවට යාමට නැවත tap කරන්න",
                            navigate: () => Navigator.pushNamed(context, '/math_lessons'),
                          );
                        },
                      ),
                      _CardItem(
                        title: "සිංහල",
                        icon: Icons.book,
                        isArmed: sinhalaArmed,
                        onTap: () {
                          _confirmTap(
                            key: "card_sinhala",
                            voiceText: "සිංහල පිටුවට යාමට නැවත tap කරන්න",
                            navigate: () => Navigator.pushNamed(context, '/quiz'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isArmed;

  const _CardItem({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.isArmed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isArmed ? Border.all(color: Colors.deepPurple, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.deepPurple),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (isArmed)
              const Text(
                "Tap again",
                style: TextStyle(fontSize: 12, color: Colors.deepPurple),
              ),
          ],
        ),
      ),
    );
  }
}
