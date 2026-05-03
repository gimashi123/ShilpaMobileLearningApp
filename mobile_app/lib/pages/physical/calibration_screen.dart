import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/eye_tracking_service.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final _service = EyeTrackingService();
  List<CalibrationPoint> _points = [];
  int _currentIndex = -1;
  bool _isCalibrating = false;
  bool _isInitializing = true;
  double _progress = 0.0;
  Timer? _collectionTimer;
  String _message = "Initializing camera... Please wait.";

  // New: Environmental/Motion status
  bool _isShaking = false;
  bool _isTooDark = false;
  double _faceConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initCalibration();
  }

  Future<void> _initCalibration() async {
    try {
      final result = await _service.initialize();
      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.error ??
                  "Failed to initialize Eye Tracking. Please check camera permissions.",
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
        return;
      }

      setState(() {
        _isInitializing = false;
        _message = "Prepare to follow the red dot with your eyes.";
      });

      // Start tracking to get camera active
      await _service.startTracking();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Critical Camera Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _start() async {
    final size = MediaQuery.of(context).size;
    _points = _service.createStandardPoints(size.width, size.height);

    await _service.clearCalibration();
    await _service.startCalibration(_points);

    setState(() {
      _isCalibrating = true;
      _currentIndex = 0;
      _message = "Look at the dot...";
    });

    _processNextPoint();
  }

  void _processNextPoint() {
    if (_currentIndex >= _points.length) {
      _finish();
      return;
    }

    _progress = 0.0;
    // Collect data for 2 seconds (10 intervals of 200ms)
    int count = 0;
    const maxCount = 10;

    _collectionTimer?.cancel();
    StreamSubscription? tempSub;

    _collectionTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        tempSub?.cancel();
        return;
      }

      // We don't increment 'count' here anymore.
      // We do it inside the gaze listener below.
    });

    tempSub = _service.gazeStream.listen((data) {
      if (!mounted || !_isCalibrating) return;

      debugPrint(
        "Gaze: Conf=${data.confidence} X=${data.x} Y=${data.y} Lum=${data.luminance.toStringAsFixed(1)} Shake=${data.deviceShake.toStringAsFixed(2)}",
      );

      bool stable = data.isStable && data.deviceShake < 0.2;
      bool goodLight = data.luminance > 45;

      if (mounted) {
        setState(() {
          _isShaking = data.deviceShake >= 0.2;
          _isTooDark = !goodLight;
          _faceConfidence = data.confidence;
        });
      }

      // Only progress if conditions are met:
      // 1. Face detected (confidence > 0.5)
      // 2. Light is sufficient
      // 3. Device is steady (shake < 0.2)
      if (data.confidence > 0.5 && goodLight && !_isShaking) {
        count++;
        if (mounted) {
          setState(() {
            _progress = count / maxCount;
          });
        }

        // Tell the service to pair this current gaze position with the physical dot position
        _service.addCalibrationPoint(
          _points[_currentIndex],
          currentGaze: Offset(data.x, data.y),
        );
      }

      if (count >= maxCount) {
        tempSub?.cancel();
        _collectionTimer?.cancel();
        if (mounted) {
          setState(() {
            _currentIndex++;
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _processNextPoint();
          });
        }
      }
    });
  }

  Future<void> _finish() async {
    if (mounted) {
      setState(() {
        _message = "Calculating accuracy...";
      });
    }

    await _service.finishCalibration();
    final accuracy = await _service.getCalibrationAccuracy();

    if (mounted) {
      setState(() {
        _isCalibrating = false;
        _message =
            "Calibration Complete!\nAccuracy: ${(accuracy * 100).toStringAsFixed(1)}%";
      });

      // Stay on screen for 2 seconds to show result then go back
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  @override
  void dispose() {
    _collectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Message
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Start Button
          if (!_isCalibrating && _currentIndex == -1)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 100),
                  ElevatedButton(
                    onPressed: _isInitializing ? null : _start,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      backgroundColor: _isInitializing
                          ? Colors.grey
                          : Colors.blueAccent,
                    ),
                    child: Text(
                      _isInitializing ? "Initializing..." : "Start Calibration",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),

          // Calibration Dot
          if (_isCalibrating &&
              _currentIndex >= 0 &&
              _currentIndex < _points.length)
            Positioned(
              left: _points[_currentIndex].x - 25,
              top: _points[_currentIndex].y - 25,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress Ring
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: _progress,
                      color: _isShaking || _isTooDark ? Colors.orange : Colors.greenAccent,
                      strokeWidth: 4,
                    ),
                  ),
                  // Inner Dot
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _isShaking || _isTooDark ? Colors.yellow : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isShaking || _isTooDark ? Colors.yellow : Colors.red)
                              .withAlpha(128),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Feedback Overlays
          if (_isCalibrating)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 50),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isShaking || _isTooDark ? Colors.orange : Colors.blueAccent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isTooDark ? Icons.wb_sunny : Icons.face,
                      color: _isTooDark ? Colors.orange : Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isTooDark
                          ? "Room too dark! Move to light."
                          : _isShaking
                              ? "Hold steady..."
                              : _faceConfidence < 0.5
                                  ? "Face not detected"
                                  : "Collecting stable data...",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
