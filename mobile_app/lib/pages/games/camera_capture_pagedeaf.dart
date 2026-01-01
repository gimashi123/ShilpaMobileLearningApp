import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class CaptureSignPage extends StatefulWidget {
  final int expected;      // expected answer (1..10)
  final String apiBaseUrl; // example: http://192.168.1.176:8000

  const CaptureSignPage({
    super.key,
    required this.expected,
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
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // 1) Ask permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _error = "Camera permission denied";
          _loading = false;
        });
        return;
      }

      // 2) Get available cameras
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _error = "No camera found on this device";
          _loading = false;
        });
        return;
      }

      // 3) IMPORTANT: Use BACK camera for hand signs (more clear)
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      // 4) Create controller
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // 5) Initialize
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

  Future<void> _captureAndSend() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _sending = true;
      _resultText = null;
      _error = null;
    });

    try {
      // 1) Take a photo
      final XFile file = await _controller!.takePicture();

      // 2) Prepare Multipart request to /predict_image
      final uri = Uri.parse("${widget.apiBaseUrl}/predict_image");

      final req = http.MultipartRequest("POST", uri);

      // Field name MUST be "image" because FastAPI endpoint uses: image: UploadFile = File(...)
      req.files.add(await http.MultipartFile.fromPath("image", file.path));

      // expected is Form field
      req.fields["expected"] = widget.expected.toString();

      // 3) Send
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode != 200) {
        setState(() {
          _resultText = "Failed: API ${resp.statusCode}: ${resp.body}";
        });
        return;
      }

      // 4) Parse JSON
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final pred = data["prediction"];
      final conf = data["confidence"];
      final isCorrect = data["is_correct"];

      setState(() {
        _resultText =
            "Predicted: $pred | confidence: $conf | is_correct: $isCorrect";
      });

      // 5) Return result to previous page (so your Level1 page can show ✅/❌)
      if (mounted) {
        Navigator.pop(context, {
          "prediction": pred,
          "confidence": conf,
          "is_correct": isCorrect,
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "Failed: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Capture Sign"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Stack(
                  children: [
                    // Camera preview
                    Positioned.fill(child: CameraPreview(_controller!)),

                    // Simple guide text (so you don’t capture face/ceiling)
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Show ONLY your HAND sign in the center.\nExpected answer: ${widget.expected}",
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Capture button
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: ElevatedButton.icon(
                        onPressed: _sending ? null : _captureAndSend,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_sending ? "Sending..." : "Capture & Check"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    // Debug text (optional)
                    if (_resultText != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 90,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _resultText!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
