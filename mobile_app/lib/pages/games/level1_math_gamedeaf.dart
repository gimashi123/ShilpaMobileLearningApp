// lib/pages/games/level1_math_gamedeaf.dart
//
// ✅ Level 1 Math Game (Deaf UI)
// ✅ Answers MUST be 1..10 (because your model trained only 1..10)
// ✅ Flow:
//    1) Start screen -> Play
//    2) 10 questions ( +, -, ×, ÷ ) generated safely
//    3) Press "Check (Sign)" -> opens camera page -> captures photo -> sends to API /predict_image
//    4) If correct -> ✅ shows happy + enables Next
//       If wrong   -> ❌ shows sad + Next locked
//    5) After 10/10 -> Win screen
//
// ⚠️ IMPORTANT: Change kApiBaseUrl to YOUR PC IP (same WiFi)
// Example: http://192.168.1.176:8000
//
// Required packages in pubspec.yaml:
//   camera: ^0.10.5+9 (or your version)
//   permission_handler: ^11.3.1 (or your version)
//   http: ^1.2.2 (or your version)

import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

/// ✅ CHANGE THIS
const String kApiBaseUrl = "http://192.168.1.176:8000";

/// =======================
/// Question Model + Bank
/// =======================
class L1Question {
  final String text; // "4 ÷ 1 = ?"
  final int answer; // 1..10
  const L1Question(this.text, this.answer);
}

class L1QuestionBank {
  static final _rng = Random();

  static L1Question randomQuestion() {
    final op = _rng.nextInt(4); // 0:+ 1:- 2:* 3:/

    if (op == 0) {
      // + : ensure answer <= 10
      final a = _rng.nextInt(10) + 1; // 1..10
      final b = _rng.nextInt(10 - a + 1); // 0..(10-a)
      final ans = a + b; // <=10
      return L1Question("$a + $b = ?", ans);
    }

    if (op == 1) {
      // - : ensure answer 1..10 (no negative, no zero)
      final a = _rng.nextInt(10) + 1; // 1..10
      final b = _rng.nextInt(a); // 0..a-1
      final ans = a - b; // 1..10 because b < a
      return L1Question("$a - $b = ?", ans);
    }

    if (op == 2) {
      // * : ensure answer <= 10 using safe pairs
      const pairs = [
        [1, 1],
        [1, 2],
        [1, 3],
        [1, 4],
        [1, 5],
        [1, 6],
        [1, 7],
        [1, 8],
        [1, 9],
        [1, 10],
        [2, 1],
        [2, 2],
        [2, 3],
        [2, 4],
        [2, 5],
        [3, 1],
        [3, 2],
        [3, 3],
        [4, 1],
        [4, 2],
        [5, 1],
        [5, 2],
        [6, 1],
        [7, 1],
        [8, 1],
        [9, 1],
        [10, 1],
      ];
      final p = pairs[_rng.nextInt(pairs.length)];
      final a = p[0], b = p[1];
      final ans = a * b; // <=10
      return L1Question("$a × $b = ?", ans);
    }

    // / : clean division, answer 1..10
    final ans = _rng.nextInt(10) + 1; // 1..10
    final divisor = _rng.nextInt(9) + 1; // 1..9
    final dividend = ans * divisor; // divisible
    return L1Question("$dividend ÷ $divisor = ?", ans);
  }

  static List<L1Question> buildLevel(int count) {
    final list = <L1Question>[];
    while (list.length < count) {
      list.add(randomQuestion());
    }
    return list;
  }
}

/// =======================
/// MAIN GAME PAGE
/// =======================
class Level1MathGameDeaf extends StatefulWidget {
  const Level1MathGameDeaf({super.key, required List<CameraDescription> cameras});

  @override
  State<Level1MathGameDeaf> createState() => _Level1MathGameDeafState();
}

class _Level1MathGameDeafState extends State<Level1MathGameDeaf> {
  // ✅ Questions generated ONCE for this level
  final List<L1Question> _questions = L1QuestionBank.buildLevel(10);

  bool _started = false; // start screen vs game screen
  int _index = 0;

  // result UI
  bool _checked = false;
  bool _isCorrect = false;
  int? _predicted;
  String? _errorMsg;

  bool get _levelFinished => _index >= _questions.length;

  L1Question get _currentQ => _questions[_index];

  void _resetForNextQuestion() {
    _checked = false;
    _isCorrect = false;
    _predicted = null;
    _errorMsg = null;
  }

  void _startLevel() {
    setState(() {
      _started = true;
      _index = 0;
      _resetForNextQuestion();
    });
  }

  void _goNext() {
    if (!_checked || !_isCorrect) return; // ✅ lock next until correct
    setState(() {
      _index++;
      if (!_levelFinished) {
        _resetForNextQuestion();
      }
    });
  }

  /// ✅ Open camera page, capture image, send to API, get prediction
  Future<void> _checkUsingSign() async {
    setState(() {
      _errorMsg = null;
    });

    final expected = _currentQ.answer;

    final result = await Navigator.push<_CaptureResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureSignPage(
          expectedAnswer: expected,
          apiBaseUrl: kApiBaseUrl,
        ),
      ),
    );

    // user canceled
    if (result == null) return;

    setState(() {
      _checked = true;

      if (result.error != null) {
        _errorMsg = result.error;
        _isCorrect = false;
        _predicted = null;
        return;
      }

      _predicted = result.prediction;
      _isCorrect = (result.isCorrect == true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1) START SCREEN
    if (!_started) {
      return Scaffold(
        appBar: AppBar(title: const Text("Level 1")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Level 1",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Answer using sign language (1 to 10)",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _startLevel,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Play"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2) WIN SCREEN
    if (_levelFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text("Level 1")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 72),
                const SizedBox(height: 12),
                const Text(
                  "You win Level 1 🎉",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _started = false;
                    });
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text("Back to Start"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3) GAME SCREEN
    final q = _currentQ;

    return Scaffold(
      appBar: AppBar(
        title: Text("Level 1 (${_index + 1} / ${_questions.length})"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Question card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  q.text,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Icon(Icons.help_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              "Show answer using sign",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 22),

            // Result area
            Expanded(
              child: Center(
                child: _buildResultArea(),
              ),
            ),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkUsingSign,
                    child: const Text("Check (Sign)"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_checked && _isCorrect) ? _goNext : null,
                    child: const Text("Next"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (!_checked || !_isCorrect)
              const Text(
                "Correct answer required",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_errorMsg != null) {
      return Text(
        "Failed: $_errorMsg",
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      );
    }

    if (!_checked) {
      return const SizedBox.shrink();
    }

    // ✅ Correct
    if (_isCorrect) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 8),
          Text(
            "Correct ✅ (Predicted: ${_predicted ?? "-"})",
            style: const TextStyle(fontSize: 18, color: Colors.green),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text("😄", style: TextStyle(fontSize: 26)),
        ],
      );
    }

    // ❌ Wrong
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cancel, size: 80, color: Colors.red),
        const SizedBox(height: 8),
        Text(
          "Wrong ❌ (Predicted: ${_predicted ?? "-"})",
          style: const TextStyle(fontSize: 18, color: Colors.red),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text("😢", style: TextStyle(fontSize: 26)),
      ],
    );
  }
}

/// =======================
/// CAPTURE PAGE (CAMERA)
/// =======================
/// This page:
/// 1) requests camera permission
/// 2) opens front camera
/// 3) on "Start 3s Capture" -> waits 3 seconds -> takes photo
/// 4) uploads to API /predict_image (multipart)
/// 5) returns prediction to game page
class CaptureSignPage extends StatefulWidget {
  final int expectedAnswer;
  final String apiBaseUrl;

  const CaptureSignPage({
    super.key,
    required this.expectedAnswer,
    required this.apiBaseUrl,
  });

  @override
  State<CaptureSignPage> createState() => _CaptureSignPageState();
}

class _CaptureSignPageState extends State<CaptureSignPage> {
  CameraController? _controller;
  bool _loading = true;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // ✅ ask camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _error = "Camera permission denied";
          _loading = false;
        });
        return;
      }

      // ✅ list cameras
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _error = "No camera found on this device";
          _loading = false;
        });
        return;
      }

      // ✅ prefer FRONT camera (for student selfie)
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );

      // ✅ create controller
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Camera init error: $e";
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start3sCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      // ✅ small instruction: user has 3 seconds to show hand clearly
      await Future.delayed(const Duration(seconds: 3));

      // ✅ take photo
      final XFile shot = await _controller!.takePicture();

      // ✅ upload to API
      final res = await _uploadToApi(
        imagePath: shot.path,
        expected: widget.expectedAnswer,
      );

      if (!mounted) return;

      Navigator.pop(context, res);
    } catch (e) {
      setState(() {
        _error = "$e";
        _sending = false;
      });
    }
  }

  Future<_CaptureResult> _uploadToApi({
    required String imagePath,
    required int expected,
  }) async {
    final uri = Uri.parse("${widget.apiBaseUrl}/predict_image");

    final req = http.MultipartRequest("POST", uri);

    // ✅ IMPORTANT:
    // our FastAPI expects field name: "file"
    req.files.add(await http.MultipartFile.fromPath("file", imagePath));

    // ✅ expected answer (Form field)
    req.fields["expected"] = expected.toString();

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      return _CaptureResult(
        error: "API ${streamed.statusCode}: $body",
      );
    }

    // ✅ parse JSON manually (simple)
    // expected JSON: {"prediction":10,"confidence":0.99,"is_correct":false}
    final pred = _readInt(body, "prediction");
    final isCorrect = _readBool(body, "is_correct");

    return _CaptureResult(
      prediction: pred,
      isCorrect: isCorrect,
    );
  }

  // tiny JSON readers (no extra package)
  int? _readInt(String json, String key) {
    final r = RegExp('"$key"\\s*:\\s*(\\d+)');
    final m = r.firstMatch(json);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  bool? _readBool(String json, String key) {
    final r = RegExp('"$key"\\s*:\\s*(true|false)');
    final m = r.firstMatch(json);
    if (m == null) return null;
    return m.group(1) == "true";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Capture Sign"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _sending ? null : () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(
                  error: _error!,
                  expected: widget.expectedAnswer,
                  onRetry: _sending ? null : _initCamera,
                )
              : _controller == null
                  ? _ErrorView(
                      error: "Camera not available",
                      expected: widget.expectedAnswer,
                      onRetry: _sending ? null : _initCamera,
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: CameraPreview(_controller!),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Text(
                                "Expected answer: ${widget.expectedAnswer}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: _sending ? null : _start3sCapture,
                                icon: const Icon(Icons.videocam),
                                label: Text(_sending ? "Sending..." : "Start 3s Capture"),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Tip: show ONLY your hand clearly, close to camera, good light.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final int expected;
  final VoidCallback? onRetry;

  const _ErrorView({
    required this.error,
    required this.expected,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Expected answer: $expected",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Failed: $error",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
          ],
        ),
      ),
    );
  }
}

/// result returned from capture page back to game page
class _CaptureResult {
  final int? prediction;
  final bool? isCorrect;
  final String? error;

  _CaptureResult({
    this.prediction,
    this.isCorrect,
    this.error,
  });
}
