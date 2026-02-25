import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_app/session/session.dart';
import 'package:mobile_app/pages/models/cognitive.dart';
import 'package:mobile_app/pages/games_cognitive/cognitive_game_loading_screen.dart';
import 'package:mobile_app/services/chat_service.dart';
import 'package:mobile_app/services/cognitive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';

class CognitiveDashboardScreen extends StatefulWidget {
  const CognitiveDashboardScreen({super.key});

  @override
  State<CognitiveDashboardScreen> createState() => _CognitiveDashboardScreenState();
}

class _CognitiveDashboardScreenState extends State<CognitiveDashboardScreen> {
  static const String _ttsMutedPrefKey = 'cognitive_dashboard_tts_muted';

  String userName = "";
  int selectedTab = 0; // 0 Home, 1 පාඩම්, 2 Games, 3 ප්‍රශ්න, 4 Profile

  String? _iqCategory;
  bool _loadingIqCategory = true;
  bool _enableAllActivities = Session.enableAllCognitiveActivities;

  // ✅ Double-click confirm
  int? _pendingKey;
  DateTime? _pendingAt;
  final Duration _confirmWindow = const Duration(seconds: 4);

  // ✅ TTS
  final FlutterTts _tts = FlutterTts();
  final ChatService _chatService = ChatService();
  late LlmProvider _chatProvider;
  final stt.SpeechToText _chatStt = stt.SpeechToText();
  bool _sttReady = false;
  bool _isListening = false;
  String? _chatLocaleId;
  String? _systemLocaleId;
  bool _sttFallbackRetried = false;
  String _liveTranscript = '';
  bool _preferSinhalaChat = true;
  bool _sendingVoicePrompt = false;
  bool _ttsMuted = false;

  // ✅ Native vibration channel (Android)
  static const MethodChannel _vibChannel = MethodChannel(
    'app.vibration/native',
  );

  @override
  void initState() {
    super.initState();
    _chatProvider = _chatService.createProvider(preferSinhala: true);
    userName = Session.userName ?? "Student";
    _setupTts();
    _initChatVoice();
    _loadIqCategory();
    _loadActivityPreference();
    _loadTtsMutePreference();
  }

  Future<void> _loadActivityPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(Session.enableAllActivitiesKey) ?? false;
    if (!mounted) return;
    setState(() {
      _enableAllActivities = enabled;
    });
    Session.enableAllCognitiveActivities = enabled;
  }

  Future<void> _loadTtsMutePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final muted = prefs.getBool(_ttsMutedPrefKey) ?? false;
    if (!mounted) return;
    setState(() {
      _ttsMuted = muted;
    });
  }

  Future<void> _loadIqCategory() async {
    final studentId = Session.userId ?? '';
    if (studentId.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _iqCategory = null;
        _loadingIqCategory = false;
      });
      return;
    }

    try {
      final attempts = await LdHistoryApi.fetchHistoryByStudentId(
        studentId.trim(),
      );
      LdAttempt? latest;
      for (final a in attempts) {
        if (latest == null || a.createdAt.isAfter(latest.createdAt)) {
          latest = a;
        }
      }

      if (!mounted) return;
      setState(() {
        _iqCategory = latest?.predLabel.toLowerCase();
        _loadingIqCategory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _iqCategory = null;
        _loadingIqCategory = false;
      });
    }
  }

  static const _activityIq = _ActivityEntry(
    title: "IQ බලමු",
    emoji: '🧠',
    route: '/iq_game',
    keyId: 300,
    gradient: LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const _activityFindImage = _ActivityEntry(
    title: "රූප හොයමු",
    emoji: '🖼️',
    route: '/activity_findImage',
    keyId: 301,
    gradient: LinearGradient(
      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const _activityDraw = _ActivityEntry(
    title: "ඉරි අඳිමු",
    emoji: '✏️',
    route: '/activity_draw',
    keyId: 302,
    gradient: LinearGradient(
      colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const _activityCountNumbers = _ActivityEntry(
    title: "ගණන් කරමු",
    emoji: '🔢',
    route: '/activity_countNumbers',
    keyId: 303,
    gradient: LinearGradient(
      colors: [Color(0xFF834D9B), Color(0xFFD04ED6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const _activityMatchSound = _ActivityEntry(
    title: "රූපය අඳුරගමු",
    emoji: '🔊',
    route: '/activity_matchSound',
    keyId: 304,
    gradient: LinearGradient(
      colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const _activityMatchPattern = _ActivityEntry(
    title: "රටාව හොයමු",
    emoji: '🧩',
    route: '/activity_matchPattern',
    keyId: 305,
    gradient: LinearGradient(
      colors: [Color(0xFFFFB347), Color(0xFFFFCC33)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const _activityMatchNumbers = _ActivityEntry(
    title: "සංඛ්‍යා ගලපමු",
    emoji: '🔢',
    route: '/activity_matchNumbers',
    keyId: 306,
    gradient: LinearGradient(
      colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const _activityMatchImage = _ActivityEntry(
    title: "වර්ගය තෝරමු",
    emoji: '🖼️',
    route: '/activity_matchImage',
    keyId: 307,
    gradient: LinearGradient(
      colors: [Color(0xFF9CECFB), Color(0xFF65C7F7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  List<_ActivityEntry> _activitiesFor(
    String? category,
    bool enableAll,
  ) {
    if (enableAll) {
      return [
        _activityIq,
        _activityFindImage,
        _activityDraw,
        _activityMatchSound,
        _activityMatchImage,
        _activityCountNumbers,
        _activityMatchNumbers,
        _activityMatchPattern,
      ];
    }

    final c = (category ?? '').toLowerCase();
    if (c == 'below') {
      return [_activityIq, _activityFindImage, _activityDraw];
    }
    if (c == 'average') {
      return [_activityIq, _activityMatchSound, _activityMatchImage];
    }
    if (c == 'above') {
      return [
        _activityIq,
        _activityCountNumbers,
        _activityMatchNumbers,
        _activityMatchPattern,
      ];
    }

    return [_activityIq];
  }

  Future<void> _setupTts() async {
    try {
      await _tts.setLanguage("si-LK");
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
    } catch (_) {
      // Sinhala voice not available -> ignore
    }
  }

  @override
  void dispose() {
    if (_chatStt.isListening) {
      _chatStt.stop();
    }
    _tts.stop();
    super.dispose();
  }

  Future<void> _initChatVoice() async {
    final available = await _chatStt.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        if (!mounted) return;

        final msg = error.errorMsg.toLowerCase();
        if (msg.contains('error_speech_timeout')) {
          setState(() {
            _isListening = false;
          });

          final localeIsSinhala =
              (_chatLocaleId ?? '').toLowerCase().startsWith('si');
          final canRetryWithSystem =
              !_sttFallbackRetried &&
              localeIsSinhala &&
              _systemLocaleId != null &&
              _systemLocaleId != _chatLocaleId;

          if (canRetryWithSystem) {
            _sttFallbackRetried = true;
            _chatLocaleId = _systemLocaleId;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Sinhala voice timed out. Retrying with system language.',
                ),
              ),
            );
            unawaited(_startVoiceListening(localeId: _chatLocaleId));
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No speech detected. Tap mic and speak clearly.',
              ),
            ),
          );
          return;
        }

        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice input error: ${error.errorMsg}'),
          ),
        );
      },
    );

    if (!available) return;

    String? preferredLocale;
    final locales = await _chatStt.locales();
    for (final loc in locales) {
      if (loc.localeId.toLowerCase().startsWith('si')) {
        preferredLocale = loc.localeId;
        break;
      }
    }
    preferredLocale ??= (await _chatStt.systemLocale())?.localeId;
    final systemLocale = (await _chatStt.systemLocale())?.localeId;

    if (!mounted) return;
    setState(() {
      _sttReady = true;
      _chatLocaleId = preferredLocale;
      _systemLocaleId = systemLocale;
    });
  }

  Future<void> _toggleChatLanguage() async {
    final oldHistory = _chatProvider.history.toList();
    setState(() {
      _preferSinhalaChat = !_preferSinhalaChat;
      _chatProvider = _chatService.createProvider(
        preferSinhala: _preferSinhalaChat,
        history: oldHistory,
      );
    });
    final msg = _preferSinhalaChat
        ? 'Chat language set to Sinhala'
        : 'Chat language set to English';
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _stopVoiceInput(submitResult: true);
      return;
    }
    if (!_sttReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input is not available on this device.'),
        ),
      );
      return;
    }

    setState(() {
      _liveTranscript = '';
      _sttFallbackRetried = false;
    });

    await _startVoiceListening(localeId: _chatLocaleId);
  }

  Future<void> _startVoiceListening({String? localeId}) async {
    if (!mounted) return;
    setState(() {
      _isListening = true;
    });

    try {
      await _chatStt.listen(
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
        ),
        pauseFor: const Duration(seconds: 8),
        listenFor: const Duration(seconds: 35),
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.trim();
          setState(() {
            _liveTranscript = words;
          });
          if (result.finalResult) {
            unawaited(_stopVoiceInput(submitResult: true));
          }
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input could not start. Please try again.'),
        ),
      );
    }
  }

  Future<void> _stopVoiceInput({required bool submitResult}) async {
    if (_chatStt.isListening) {
      await _chatStt.stop();
    }
    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
    final prompt = _liveTranscript.trim();
    if (submitResult && prompt.isNotEmpty) {
      await _sendPromptFromVoice(prompt);
      if (!mounted) return;
      setState(() {
        _liveTranscript = '';
      });
    }
  }

  Future<void> _sendPromptFromVoice(String prompt) async {
    if (_sendingVoicePrompt) return;
    setState(() {
      _sendingVoicePrompt = true;
    });
    try {
      await for (final _ in _chatProvider.sendMessageStream(prompt)) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ChatService.userFriendlyError(e)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingVoicePrompt = false;
        });
      }
    }
  }

  Future<void> _speakLatestAssistantReply() async {
    if (_ttsMuted) return;

    final history = _chatProvider.history.toList().reversed;
    String? latest;
    for (final msg in history) {
      if (!msg.origin.isLlm) continue;
      final text = msg.text?.trim();
      if (text != null && text.isNotEmpty) {
        latest = text;
        break;
      }
    }

    if (latest == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No AI reply to read yet.')),
      );
      return;
    }

    try {
      await _tts.stop();
      await _tts.setLanguage(_preferSinhalaChat ? 'si-LK' : 'en-US');
      await _tts.speak(ChatService.sanitizeAssistantText(latest));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text-to-speech is not available.')),
      );
    }
  }

  Future<void> _toggleMuteSpeaker() async {
    final nextMuted = !_ttsMuted;
    setState(() {
      _ttsMuted = nextMuted;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ttsMutedPrefKey, nextMuted);

    if (nextMuted) {
      await _tts.stop();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nextMuted ? 'Speaker muted' : 'Speaker unmuted'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ REAL vibration (Native Android) + fallback haptic
  Future<void> _vibrate([int ms = 60]) async {
    try {
      // Try native Android vibration first (works even if haptic weird)
      await _vibChannel.invokeMethod('vibrate', {"ms": ms});
    } catch (_) {
      // Fallback to haptic (may depend on device settings)
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  // ✅ Common confirm message
  String _confirmMsg(String name) => "$name පිටුවට යාමට නැවත එය click කරන්න";

  // ✅ Core confirm handler (navbar + grid + chips)
  Future<void> _confirmThenGo({
    required int keyId,
    required String name,
    required VoidCallback go,
  }) async {
    // ✅ vibrate on EVERY tap
    await _vibrate(60);

    final now = DateTime.now();

    final bool secondTap =
        _pendingKey == keyId &&
        _pendingAt != null &&
        now.difference(_pendingAt!) <= _confirmWindow;

    if (secondTap) {
      setState(() {
        _pendingKey = null;
        _pendingAt = null;
      });
      await _tts.stop();
      go();
      return;
    }

    // first tap -> speak + set pending
    setState(() {
      _pendingKey = keyId;
      _pendingAt = now;
    });

    final msg = _confirmMsg(name);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.deepPurple.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ),
      );
    }

    if (_ttsMuted) return;

    try {
      await _tts.stop();
      await _tts.speak(msg);
    } catch (_) {}
  }

  // ✅ Navbar tap handler
  Future<void> _navTap(int tabIndex) async {
    if (tabIndex == selectedTab) return;

    final keyId = 100 + tabIndex;

    String name;
    String route;

    switch (tabIndex) {
      case 0:
        name = "Home";
        route = "/home_cognitive";
        break;
      case 1:
        name = "IQ බලමු";
        route = "/iq_game";
        break;
      case 2:
        name = "රූප හොයමු";
        route = "/activity_findImage";
        break;
      case 3:
        name = "ඉරි අඳිමු";
        route = "/activity_draw";
        break;
      case 4:
        name = "ගණන් කරමු";
        route = "/activity_countNumbers";
        break;
        case 5:
        name = "ප්‍රගතිය";
        route = "/activity_iqScore";
        break;
      default:
        name = "Profile";
        route = "/profile";
    }

    await _confirmThenGo(
      keyId: keyId,
      name: name,
      go: () => _openCognitiveRoute(name, route),
    );
  }

  void _openCognitiveRoute(String title, String route) {
    final isGameRoute =
        route == '/iq_game' ||
        (route.startsWith('/activity_') && route != '/activity_iqScore');

    if (!isGameRoute) {
      Navigator.pushReplacementNamed(context, route);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CognitiveGameLoadingScreen(gameTitle: title, targetRoute: route),
      ),
    );
  }

  Future<void> _openAiChat() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.9;
        return Theme(
          data: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF5B7CFF),
            brightness: Brightness.light,
          ),
          child: Container(
            height: height,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 6, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Cognitive AI Assistant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _toggleChatLanguage,
                        child: Text(
                          _preferSinhalaChat ? 'සිංහල' : 'English',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: _sendingVoicePrompt
                            ? null
                            : _toggleVoiceInput,
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : null,
                        ),
                        tooltip: _isListening
                            ? 'Stop and send voice input'
                            : 'Start voice input',
                      ),
                      IconButton(
                        onPressed: _toggleMuteSpeaker,
                        icon: Icon(
                          _ttsMuted
                              ? Icons.volume_off_outlined
                              : Icons.volume_up_outlined,
                        ),
                        tooltip:
                            _ttsMuted ? 'Unmute speaker' : 'Mute speaker',
                      ),
                      IconButton(
                        onPressed: _ttsMuted ? null : _speakLatestAssistantReply,
                        icon: const Icon(Icons.record_voice_over_outlined),
                        tooltip: _ttsMuted
                            ? 'Unmute to read latest AI response'
                            : 'Read latest AI response',
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_isListening || _liveTranscript.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    color: const Color(0xFFE8EEFF),
                    child: Text(
                      _isListening
                          ? 'Listening... $_liveTranscript'
                          : 'Voice text: $_liveTranscript',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF25325F),
                      ),
                    ),
                  ),
                Expanded(
                  child: LlmChatView(
                    provider: _chatProvider,
                    welcomeMessage:
                        'ආයුබෝවන්! මම ඔබගේ cognitive ඉගෙනීමේ AI සහායකයා.',
                    suggestions: const [
                      'මතකය වැඩි කරගන්න ක්‍රම 3ක් දෙන්න',
                      'අදට මිනිත්තු 5ක brain exercises දෙන්න',
                      'matching tasks වලට අමාරු ළමයෙකුට උදව් කරන්නේ කොහොමද?',
                    ],
                    enableAttachments: false,
                    enableVoiceNotes: false,
                    autofocus: false,
                    style: LlmChatViewStyle(
                      backgroundColor: const Color(0xFFF8FAFF),
                      progressIndicatorColor: const Color(0xFF5B7CFF),
                      menuColor: const Color(0xFF5B7CFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAiChat,
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('AI Chat'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF667EEA).withOpacity(0.15),
              const Color(0xFF764BA2).withOpacity(0.12),
              const Color(0xFFFFF8E1).withOpacity(0.95),
            ],
          ),
          image: const DecorationImage(
            image: AssetImage(
              "assets/login_page.png",
            ), // Add a subtle pattern if available
            fit: BoxFit.cover,
            opacity: 0.08,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // WELCOME SECTION
                // =====================================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6A11CB).withOpacity(0.9),
                        const Color(0xFF2575FC).withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.7),
                            ],
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF6A11CB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "සාදරයෙන් පිළිගනිමු",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black12,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =====================================================
                // TOP NAV BAR - ENHANCED
                // =====================================================
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFCDB6FF),
                        const Color(0xFFB19CD9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      _TabBtn("Home", selectedTab == 0, () => _navTap(0)),
                      _TabBtn("ප්‍රගතිය", selectedTab == 5, () => _navTap(5)),
                      _TabBtn("Profile", selectedTab == 6, () => _navTap(6)),
                    ],
                  ),
                ),

                // const SizedBox(height: 28),

                // =====================================================
                // SUBJECTS TITLE
                // =====================================================
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 8),
                //   child: Row(
                //     children: [
                //       Container(
                //         width: 6,
                //         height: 40,
                //         decoration: BoxDecoration(
                //           gradient: LinearGradient(
                //             colors: [
                //               const Color(0xFF6A11CB),
                //               const Color(0xFF2575FC),
                //             ],
                //             begin: Alignment.topCenter,
                //             end: Alignment.bottomCenter,
                //           ),
                //           borderRadius: BorderRadius.circular(3),
                //         ),
                //       ),
                //       const SizedBox(width: 12),
                //       const Text(
                //         "ඔබගේ විෂයන්",
                //         style: TextStyle(
                //           fontSize: 32,
                //           fontWeight: FontWeight.w800,
                //           color: Color(0xFF2D1B69),
                //           letterSpacing: -0.5,
                //           shadows: [
                //             Shadow(
                //               blurRadius: 2,
                //               color: Colors.black12,
                //               offset: Offset(1, 1),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                // const SizedBox(height: 4),
                // Padding(
                //   padding: const EdgeInsets.only(left: 26),
                //   child: Text(
                //     "ඔබගේ ඉගෙනීම ආරම්භ කරන්න",
                //     style: TextStyle(
                //       fontSize: 15,
                //       color: Colors.deepPurple.withOpacity(0.7),
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ),

                // const SizedBox(height: 20),

                // // =====================================================
                // // SUBJECT CHIPS - ENHANCED
                // // =====================================================
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: Row(
                //     children: [
                //       _SubjectChip(
                //         label: "ගණිතය",
                //         icon: Icons.calculate_rounded,
                //         color: const Color(0xFF4A6FA5),
                //         onTap: () {
                //           _confirmThenGo(
                //             keyId: 200,
                //             name: "ගණිතය",
                //             go: () => Navigator.pushReplacementNamed(
                //               context,
                //               '/math_lessons',
                //             ),
                //           );
                //         },
                //       ),
                //       _SubjectChip(
                //         label: "සිංහල",
                //         icon: Icons.menu_book_rounded,
                //         color: const Color(0xFF2E7D32),
                //         onTap: () {
                //           _confirmThenGo(
                //             keyId: 201,
                //             name: "සිංහල",
                //             go: () {
                //               ScaffoldMessenger.of(context).showSnackBar(
                //                 SnackBar(
                //                   content: const Text(
                //                     "Sinhala lessons coming soon!",
                //                   ),
                //                   backgroundColor: Colors.green.withOpacity(
                //                     0.9,
                //                   ),
                //                   shape: RoundedRectangleBorder(
                //                     borderRadius: BorderRadius.circular(12),
                //                   ),
                //                 ),
                //               );
                //             },
                //           );
                //         },
                //       ),
                //       _SubjectChip(
                //         label: "ප්‍රශ්න",
                //         icon: Icons.quiz_rounded,
                //         color: const Color(0xFFD32F2F),
                //         onTap: () {
                //           _confirmThenGo(
                //             keyId: 202,
                //             name: "ප්‍රශ්න",
                //             go: () => Navigator.pushReplacementNamed(
                //               context,
                //               '/quiz',
                //             ),
                //           );
                //         },
                //       ),
                //       _SubjectChip(
                //         label: "ගැටළු",
                //         icon: Icons.lightbulb_rounded,
                //         color: const Color(0xFFF57C00),
                //         onTap: () {
                //           _confirmThenGo(
                //             keyId: 203,
                //             name: "ගැටළු",
                //             go: () {
                //               // Add your logic here
                //             },
                //           );
                //         },
                //       ),
                //     ],
                //   ),
                // ),

                const SizedBox(height: 32),

                // =====================================================
                // MAIN GRID - ENHANCED
                // =====================================================
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: _LessonsGrid(
                        items: _activitiesFor(
                          _loadingIqCategory ? null : _iqCategory,
                          _enableAllActivities,
                        ),
                        onOpen: (title, route, keyId) {
                          _confirmThenGo(
                            keyId: keyId,
                            name: title,
                            go: () => _openCognitiveRoute(title, route),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// TAB BUTTON - ENHANCED
// =====================================================
class _TabBtn extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _TabBtn(this.text, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B00FF).withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF9D50BB),
                          const Color(0xFF6E48AA),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: selected
                    ? Border.all(color: Colors.white.withOpacity(0.8), width: 2)
                    : null,
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF2D1B69),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SUBJECT CHIP - ENHANCED
// =====================================================
class _SubjectChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SubjectChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// GRID - ENHANCED
// =====================================================
class _LessonsGrid extends StatelessWidget {
  final List<_ActivityEntry> items;
  final void Function(String title, String route, int keyId) onOpen;

  const _LessonsGrid({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(4),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2 / 3,
      children: items
          .map(
            (item) => _gridItem(
              context,
              item.title,
              item.emoji,
              item.route,
              item.keyId,
              item.gradient,
            ),
          )
          .toList(),
    );
  }

  Widget _gridItem(
    BuildContext context,
    String title,
    String emoji,
    String route,
    int keyId,
    Gradient gradient,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => onOpen(title, route, keyId),
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black26,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityEntry {
  final String title;
  final String emoji;
  final String route;
  final int keyId;
  final Gradient gradient;

  const _ActivityEntry({
    required this.title,
    required this.emoji,
    required this.route,
    required this.keyId,
    required this.gradient,
  });
}
