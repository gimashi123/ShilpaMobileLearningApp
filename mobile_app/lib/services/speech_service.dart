import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class SpeechService {
  // singleton
  SpeechService._internal();
  static final SpeechService instance = SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  String? _localeId; // e.g. 'si-LK' or system fallback
  bool _isListening = false;

  // Callback for recognized text
  void Function(String text)? _onCommandRecognized;

  bool get isReady => _ready;
  bool get isListening => _isListening;
  String? get localeId => _localeId;

  /// Call once when app starts (in main)
  Future<void> init() async {
    try {
      // Explicitly check/request microphone permission
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }

      final available = await _speech.initialize(
        onStatus: (status) {
          print('STT status: $status');
          if (status == 'done' || status == 'notListening') {
            _handleListeningStopped();
          }
        },
        onError: (err) {
          print('STT error: ${err.errorMsg} - Permanent: ${err.permanent}');
          // If it's a timeout or other error, try to restart if we should be listening
          if (_isListening) {
            _handleListeningStopped();
          }
        },
      );

      if (!available) {
        print('Speech recognition not available on this device');
        _ready = false;
        return;
      }

      // try Sinhala first
      final locales = await _speech.locales();
      String? si;

      for (final loc in locales) {
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

      print('SpeechService ready using locale: $_localeId');
      _ready = true;
    } catch (e) {
      print('SpeechService init exception: $e');
      _ready = false;
    }
  }

  /// Sets the callback for command recognition
  void setCommandListener(void Function(String text) onCommand) {
    _onCommandRecognized = onCommand;
  }

  /// Start continuous listening
  Future<void> startListening() async {
    if (!_ready) {
      print('SpeechService not ready, re-initializing...');
      await init();
    }

    if (!_ready || _isListening) return;

    _isListening = true;
    print('Starting voice listener loop...');
    await _startListeningInternal();
  }

  Future<void> _startListeningInternal() async {
    if (!_isListening) return;

    try {
      await _speech.listen(
        localeId: _localeId,
        onResult: (result) {
          double confidence = result.confidence;
          print(
            'Heard: ${result.recognizedWords} (Final: ${result.finalResult}, Conf: ${confidence.toStringAsFixed(2)})',
          );

          // Acoustic Confidence Threshold Filter
          // If confidence is too low (< 0.5), we ignore to prevent false activations
          if (result.finalResult && _onCommandRecognized != null) {
            if (confidence > 0.5 || confidence == 0) {
              // 0 sometimes means not reported
              _onCommandRecognized!(result.recognizedWords);
            } else {
              print('Ignored low confidence recognition: $confidence');
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 10), // Increased pause duration
        cancelOnError: false, // Don't cancel immediately on error
        listenMode:
            stt.ListenMode.dictation, // Use dictation for better sensitivity
        partialResults: true,
      );
    } catch (e) {
      print('Error in _startListeningInternal: $e');
    }
  }

  void _handleListeningStopped() {
    // If we are supposed to be listening, restart after a short delay
    if (_isListening) {
      Timer(const Duration(milliseconds: 1000), () {
        if (_isListening) {
          _startListeningInternal();
        }
      });
    }
  }

  void stopListening() {
    print('Stopping voice listener...');
    _isListening = false;
    _speech.stop();
  }
}
