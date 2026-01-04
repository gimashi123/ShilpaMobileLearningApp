import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class BlindRegisterPage extends StatefulWidget {
  const BlindRegisterPage({super.key});

  @override
  State<BlindRegisterPage> createState() => _BlindRegisterPageState();
}

class _BlindRegisterPageState extends State<BlindRegisterPage> {
  // 0 = name, 1 = email, 2 = password
  int _step = 0;

  // Controllers to keep values (you can send these to backend later)
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  // Role (default student)
  final String _role = 'student';

  // TTS
  final FlutterTts _tts = FlutterTts();

  // STT
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;
  String _lastHeard = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initSpeech();
      await _speak(_stepPrompt(0));
      _startListening(); // start for name
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ---------- TTS ----------
  Future<void> _speak(String text) async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    var ok = await _tts.setLanguage('si-LK');
    if (ok == 0) {
      await _tts.setLanguage('en-US');
    }

    await _tts.stop();
    await _tts.speak(text);
  }

  String _stepPrompt(int step) {
    switch (step) {
      case 0:
        return 'දැන් ඔබගේ නම කථා කරන්න. උදාහරණයක් ලෙස, "සුනාන්දි පෙරේරා" කියන්න.';
      case 1:
        return 'දැන් ඔබගේ ඊමේල් ලිපිනය කථා කරන්න. උදාහරණයක් ලෙස, "student at gmail dot com" කියන්න.';
      case 2:
        return 'දැන් ඔබගේ සංකේත පදය කථා කරන්න. අවසානයේ Register කිරීම සිදු කරමු.';
      default:
        return '';
    }
  }

  // ---------- STT ----------
  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          setState(() => _listening = false);
        }
      },
      onError: (error) {
        setState(() {
          _lastHeard = 'Error: ${error.errorMsg}';
          _listening = false;
        });
      },
    );
    setState(() => _speechAvailable = available);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || _listening) return;

    setState(() {
      _lastHeard = '';
      _listening = true;
    });

    // Try Sinhala locale if available, else default
    String? localeId;
    try {
      final locales = await _speech.locales();
      final si = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith('si'),
        orElse: () => locales.first,
      );
      localeId = si.localeId;
    } catch (_) {
      localeId = null;
    }

    await _speech.listen(
      localeId: localeId, // si_LK if exists, else device default
      listenFor: const Duration(seconds: 7),
      partialResults: false, // we only care final
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;
        setState(() => _lastHeard = text);
        _handleHeardText(text);
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _listening = false);
  }

  Future<void> _handleHeardText(String text) async {
    // stop mic while TTS talking
    await _stopListening();

    if (_step == 0) {
      // Name step
      _nameCtrl.text = text;
      await _speak('ඔබගේ නම $text. දැන් ඊමේල් ලිපිනය කියන්න.');
      setState(() => _step = 1);
      _startListening();
    } else if (_step == 1) {
      // Email step
      _emailCtrl.text = text;
      await _speak('ඔබගේ ඊමේල් $text. දැන් සංකේත පදය කියන්න.');
      setState(() => _step = 2);
      _startListening();
    } else if (_step == 2) {
      // Password step
      _passwordCtrl.text = text;
      await _speak('ඔබගේ සංකේත පදය ලියා ගති. දැන් පෙය්ජය ලියාපදිංචි කරමු.');
      await _submit();
    }
  }

  // ---------- Submit ----------
  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final role = _role; // always 'student' here

    if (name.isEmpty || email.isEmpty || password.length < 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('දත්ත සම්පූර්ණ නොවයි.')));
      await _speak('කරුණාකර නැවත වරක් උත්සාහ කරන්න.');
      // Optionally go back to first step
      setState(() => _step = 0);
      await _speak(_stepPrompt(0));
      _startListening();
      return;
    }

    // TODO: send {name, email, password, role} to backend here.
    // e.g. Api.register(name: name, email: email, password: password, role: role);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully Registered (student role)')),
    );
    await _speak('ඔබ ශිෂ්‍ය ලෙස සාර්ථකව ලියාපදිංචි විය.');

    if (!mounted) return;
    Navigator.pushNamed(context, '/login');
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B38FB), Color(0xFF22073E)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFB388FF),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),

            // Replay current step instructions
            Positioned(
              right: 16,
              top: 32,
              child: Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(32),
                child: IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.white),
                  tooltip: 'Replay instructions',
                  onPressed: () => _speak(_stepPrompt(_step)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final stepTitle = switch (_step) {
      0 => 'පියවර 1 / 3 - නම (Voice)',
      1 => 'පියවර 2 / 3 - Email (Voice)',
      2 => 'පියවර 3 / 3 - Password (Voice)',
      _ => '',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stepTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Role: Student (පෙරනිමියෙන් ශිෂ්‍ය භූමිකාව)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),

        // Show what system heard (optional, for helpers/sighted users)
        if (_lastHeard.isNotEmpty)
          Text(
            'ඔබ කිව්වේ: $_lastHeard',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),

        const SizedBox(height: 24),

        // Mic button
        ElevatedButton.icon(
          onPressed: _listening ? _stopListening : _startListening,
          icon: Icon(_listening ? Icons.mic : Icons.mic_none),
          label: Text(
            _listening ? 'කීවය සවන් දෙනවා…' : 'Voice Input ආරම්භ කරන්න',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E5BFF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Show summary fields (for debugging/teacher)
        _buildSummaryFields(),
      ],
    );
  }

  Widget _buildSummaryFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Name: ${_nameCtrl.text}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          'Email: ${_emailCtrl.text}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          'Password: ${_passwordCtrl.text.isEmpty ? '---' : '●●●●●●'}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        const Text('Role: student', style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}
