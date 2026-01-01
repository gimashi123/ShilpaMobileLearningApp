import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  // singleton
  SpeechService._internal();
  static final SpeechService instance = SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  String? _localeId; // e.g. 'si-LK' or system fallback

  bool get isReady => _ready;
  String? get localeId => _localeId;

  /// Call once when app starts (in main)
  Future<void> init() async {
    final available = await _speech.initialize(
      onStatus: (status) => print('STT status: $status'),
      onError: (err) => print('STT error: $err'),
    );

    if (!available) {
      _ready = false;
      return;
    }

    // try Sinhala first
    final locales = await _speech.locales();
    String? si;

    for (final loc in locales) {
      print('STT locale: ${loc.localeId} | ${loc.name}');
      if (loc.localeId.toLowerCase().startsWith('si')) {
        si = loc.localeId;
        break;
      }
    }

    if (si != null) {
      _localeId = si;
    } else {
      final sys = await _speech.systemLocale();
      _localeId = sys?.localeId;
    }

    print('SpeechService using locale: $_localeId');

    _ready = true;
  }

  /// Start listening – callback is called every time partial/final result comes
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_ready) {
      print('SpeechService: not ready');
      return;
    }

    await _speech.listen(
      localeId: _localeId,
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
  }

  void stop() {
    _speech.stop();
  }
}
