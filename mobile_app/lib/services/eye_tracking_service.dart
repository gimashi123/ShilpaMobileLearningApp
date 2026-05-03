import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'performance_logger.dart'; // Added for research logging

/// -------------------------------------------------------------------------
/// COMPONENT: 1-Euro Filter for Adaptive Smoothing
/// -------------------------------------------------------------------------
class OneEuroFilter {
  final double minCutoff;
  final double beta;
  final double dCutoff;
  double _lastTimestamp = -1;
  double _yPrev = 0;
  double _dyPrev = 0;

  OneEuroFilter({this.minCutoff = 1.0, this.beta = 0.0, this.dCutoff = 1.0});

  double filter(double value, double timestamp) {
    if (_lastTimestamp == -1) {
      _lastTimestamp = timestamp;
      _yPrev = value;
      return value;
    }

    double dt = timestamp - _lastTimestamp;
    if (dt <= 0) return _yPrev;

    double dy = (value - _yPrev) / dt;
    double dySmoothed = _lowPass(dy, _dyPrev, _alpha(dt, dCutoff));
    _dyPrev = dySmoothed;

    double cutoff = minCutoff + beta * dySmoothed.abs();
    double ySmoothed = _lowPass(value, _yPrev, _alpha(dt, cutoff));

    _lastTimestamp = timestamp;
    _yPrev = ySmoothed;

    return ySmoothed;
  }

  double _alpha(double dt, double cutoff) {
    double tau = 1.0 / (2 * math.pi * cutoff);
    return 1.0 / (1.0 + tau / dt);
  }

  double _lowPass(double value, double prev, double alpha) {
    return alpha * value + (1.0 - alpha) * prev;
  }
}

class GazeData {
  final double x;
  final double y;
  final double confidence;
  final bool isStable;
  final double blinkProbability; // Adds support for "Blink to Select"
  final double luminance; // New: To detect low-light environments
  final double deviceShake; // New: To detect shaky hands via accelerometer
  final DateTime timestamp;

  GazeData({
    required this.x,
    required this.y,
    required this.confidence,
    this.isStable = false,
    this.blinkProbability = 1.0,
    this.luminance = 100.0,
    this.deviceShake = 0.0,
    required this.timestamp,
  });
}

class CalibrationPoint {
  final double x;
  final double y;
  final int order;

  CalibrationPoint({required this.x, required this.y, required this.order});
}

class EyeTrackingInitializationResult {
  final bool success;
  final String? error;

  EyeTrackingInitializationResult({required this.success, this.error});
}

class EyeTrackingService {
  static final EyeTrackingService _instance = EyeTrackingService._internal();
  factory EyeTrackingService() => _instance;
  EyeTrackingService._internal();

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isInitialized = false;
  bool _isTracking = false;
  bool _isProcessing = false;

  final StreamController<GazeData> _gazeController =
      StreamController<GazeData>.broadcast();
  Stream<GazeData> get gazeStream => _gazeController.stream;

  // Optimized ValueNotifiers for global UI overlays (e.g. Cursor)
  final ValueNotifier<Offset> currentGaze = ValueNotifier(
    const Offset(-100, -100),
  );
  final ValueNotifier<bool> isStableNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isFaceDetectedNotifier = ValueNotifier(true);
  final ValueNotifier<Offset?> stickyPosition = ValueNotifier(null);

  bool get isInitialized => _isInitialized;

  // --- CALIBRATION & FILTERING DATA ---
  final Map<int, List<Offset>> _calibrationSamples = {};
  Offset _gazeOffset = Offset.zero;
  double _calculatedAccuracy = 0.0;

  // Smoothing & Stability Model Variables
  final List<Offset> _history = [];
  static const int _historyLimit = 15; // N frames for variance calculation
  static const double _spikeThreshold = 150.0; // Max pixels jump allowed
  double _stabilityVarianceThreshold =
      25.0; // Pixels variance (Personalized later)

  // 1-Euro Filter Instances
  final OneEuroFilter _filterX = OneEuroFilter(minCutoff: 0.5, beta: 0.01);
  final OneEuroFilter _filterY = OneEuroFilter(minCutoff: 0.5, beta: 0.01);

  Offset? _lastRawPosition;

  // Environment & Motion Data
  double _currentLuminance = 100.0;
  double _currentDeviceShake = 0.0;
  StreamSubscription? _accelerometerSub;

  Future<EyeTrackingInitializationResult> initialize() async {
    if (_isInitialized) return EyeTrackingInitializationResult(success: true);

    debugPrint("EyeTracking: Starting initialization...");

    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (!status.isGranted) {
      return EyeTrackingInitializationResult(
        success: false,
        error: "Camera permission denied.",
      );
    }

    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableClassification: true, // For blink/eye status if needed later
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return EyeTrackingInitializationResult(
          success: false,
          error: "No cameras found.",
        );
      }

      final frontCam = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      // Optimize for low-light if needed
      if (await _cameraController!.getMinExposureOffset() < 0) {
        await _cameraController!.setExposureOffset(1.0); // Brighten by default
      }

      // Start Accelerometer to detect shaky hands
      _accelerometerSub = accelerometerEventStream().listen((event) {
        // Calculate G-force magnitude change
        _currentDeviceShake = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        // Normalize: Subtract gravity (~9.8) and clamp
        _currentDeviceShake = (_currentDeviceShake - 9.8).abs().clamp(0.0, 5.0);
      });

      _isInitialized = true;
      debugPrint("EyeTracking: Initialization successful.");
      return EyeTrackingInitializationResult(success: true);
    } catch (e) {
      debugPrint("EyeTracking: Initialization error: $e");
      return EyeTrackingInitializationResult(
        success: false,
        error: "Init Error: $e",
      );
    }
  }

  Future<void> startTracking() async {
    if (!_isInitialized || _isTracking || _cameraController == null) return;

    _isTracking = true;
    debugPrint("EyeTracking: Image stream started.");

    _cameraController!.startImageStream((image) async {
      if (!_isTracking || _isProcessing) return;
      _isProcessing = true;

      try {
        final inputImage = _processCameraImage(image);
        if (inputImage == null) {
          _isProcessing = false;
          return;
        }

        // Environment Check: Calculate Luminance from Y-Plane
        _currentLuminance = _calculateLuminance(image);

        final faces = await _faceDetector?.processImage(inputImage);

        if (faces != null && faces.isNotEmpty && _isTracking) {
          isFaceDetectedNotifier.value = true;
          _processFace(
            faces.first,
            image.width.toDouble(),
            image.height.toDouble(),
          );
        } else {
          isFaceDetectedNotifier.value = false;
          // Send 0 confidence to indicate no face detected
          _gazeController.add(
            GazeData(
              x: -1,
              y: -1,
              confidence: 0,
              luminance: _currentLuminance,
              deviceShake: _currentDeviceShake,
              timestamp: DateTime.now(),
            ),
          );
        }
      } catch (e) {
        debugPrint("EyeTracking: Processing error: $e");
      } finally {
        await Future.delayed(const Duration(milliseconds: 33)); // Target ~30fps
        _isProcessing = false;
      }
    });
  }

  InputImage? _processCameraImage(CameraImage image) {
    try {
      final sensorOrientation =
          _cameraController!.description.sensorOrientation;
      final rotation = _inputImageRotation(sensorOrientation);
      if (rotation == null) return null;

      // FOR ANDROID, WE MANUALLY CONVERT TO NV21 TO PREVENT IllegalArgumentException
      if (Platform.isAndroid) {
        final nv21Bytes = _yuv420ToNv21(image);
        return InputImage.fromBytes(
          bytes: nv21Bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.width,
          ),
        );
      } else {
        // IOS logic (BGRA8888)
        // We requested bgra8888, so we assume it is bgra8888.
        // If dynamic format needed, we'd need a mapping from image.format.raw
        const format = InputImageFormat.bgra8888;
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }
    } catch (e) {
      debugPrint("EyeTracking: Image conversion failed: $e");
      return null;
    }
  }

  InputImageRotation? _inputImageRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final numPixels = width * height;
    final nv21 = Uint8List(numPixels * 3 ~/ 2);

    // Y plane - copy row by row to strip padding
    int id = 0;
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        nv21[id++] = yBuffer[row * yPlane.bytesPerRow + col];
      }
    }

    // U and V planes are interleaved for NV21
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;

    // In NV21, the UV plane follows the Y plane and consists of interleaved V and U samples.
    // For each 2x2 block of pixels, there is one V and one U sample.
    for (int row = 0; row < uvHeight; row++) {
      for (int col = 0; col < uvWidth; col++) {
        // vPlane and uPlane might have different bytesPerPixel (usually 1 or 2)
        final vIndex =
            row * vPlane.bytesPerRow + (col * (vPlane.bytesPerPixel ?? 1));
        final uIndex =
            row * uPlane.bytesPerRow + (col * (uPlane.bytesPerPixel ?? 1));

        nv21[id++] = vBuffer[vIndex];
        nv21[id++] = uBuffer[uIndex];
      }
    }
    return nv21;
  }

  double _calculateLuminance(CameraImage image) {
    final Uint8List plane = image.planes[0].bytes;
    double total = 0;
    // Sample every 10th pixel for performance
    for (int i = 0; i < plane.length; i += 10) {
      total += plane[i];
    }
    return total / (plane.length / 10);
  }

  /// -------------------------------------------------------------------------
  /// ALGORITHM 1: Real-Time Gaze Stability Filtering Model (The "Catch")
  /// This algorithm runs at ~30 FPS to stabilize raw jittery eye/head data.
  /// -------------------------------------------------------------------------
  void _processFace(Face face, double imgWidth, double imgHeight) {
    final stopwatch = Stopwatch()..start();

    // Step 1: Landmark Extraction (Requirement 3.2 - Research Ready)
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];

    // Landmark-based pre-validation (ensure critical landmarks are visible)
    if (leftEye == null || rightEye == null || noseBase == null) return;

    // Extract head orientation values (Yaw/Pitch)
    final yaw = face.headEulerAngleY ?? 0;
    final pitch = face.headEulerAngleX ?? 0;

    final view = PlatformDispatcher.instance.views.first;
    final size = view.physicalSize / view.devicePixelRatio;

    const sensitivity = 35.0;
    double centerX = size.width / 2;
    double centerY = size.height / 2;

    // Calculate Target Screen Position
    // Mirroring: +Yaw turns Left (on screen), so subtract.
    // Pitch: +Pitch looks Up, so subtract.
    double targetX = centerX - (yaw * sensitivity);
    double targetY = centerY - (pitch * sensitivity);

    // Calibration: Add the 'Drift' offset we learned.
    // Scale: We keep 1.0 for now as rotational mapping is absolute.
    targetX = targetX + _gazeOffset.dx;
    targetY = targetY + _gazeOffset.dy;

    // Clamp to screen
    targetX = targetX.clamp(0.0, size.width);
    targetY = targetY.clamp(0.0, size.height);

    Offset currentRawPosition = Offset(targetX, targetY);

    // Step 3: Spike Detection and Removal
    if (_lastRawPosition != null) {
      double distance = (currentRawPosition - _lastRawPosition!).distance;
      if (distance > _spikeThreshold) return;
    }
    _lastRawPosition = currentRawPosition;

    _lastRawPosition = currentRawPosition;

    // Step 2: 1-Euro Filter Smoothing (Adaptive)
    // Replaces EMA for better jitter suppression while maintaining low lag.
    double timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;
    double filteredX = _filterX.filter(currentRawPosition.dx, timestamp);
    double filteredY = _filterY.filter(currentRawPosition.dy, timestamp);
    Offset smoothedPos = Offset(filteredX, filteredY);

    // Still track history for variance/stability calculation
    _history.add(currentRawPosition);
    if (_history.length > _historyLimit) _history.removeAt(0);

    // Step 4: Stability Window Logic
    bool isStable = false;
    if (_history.length >= _historyLimit) {
      double variance = _calculateVariance(_history, smoothedPos);
      isStable = variance < _stabilityVarianceThreshold;
    }

    stopwatch.stop();

    // Performance Logging: Latency Monitoring (Requirement 4.1)
    if (_history.length % 60 == 0) {
      PerformanceLogger().logEvent(
        event: 'GAZE_LATENCY',
        details: 'Frame -> Landmark -> Smoothed Point',
        newValue: '${stopwatch.elapsedMilliseconds}ms',
      );
    }

    // Extract Eye Open Probability (New for Blink-to-Select)
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
    final blinkProb = (leftEyeOpen + rightEyeOpen) / 2.0;

    // Update global ValueNotifiers
    // MAGNETIC LOGIC: If a sticky position (button center) is set, lock the public cursor to it.
    if (stickyPosition.value != null) {
      currentGaze.value = stickyPosition.value!;
    } else {
      currentGaze.value = smoothedPos;
    }
    
    isStableNotifier.value = isStable;

    _gazeController.add(
      GazeData(
        x: smoothedPos.dx,
        y: smoothedPos.dy,
        confidence: 0.9,
        isStable: isStable,
        blinkProbability: blinkProb,
        luminance: _currentLuminance,
        deviceShake: _currentDeviceShake,
        timestamp: DateTime.now(),
      ),
    );
  }

  double _calculateVariance(List<Offset> points, Offset mean) {
    double sumSquaredDist = 0;
    for (var p in points) {
      sumSquaredDist += (p - mean).distanceSquared;
    }
    return sumSquaredDist / points.length;
  }

  // --- CALIBRATION INTERFACE ---
  Future<void> startCalibration(List<CalibrationPoint> points) async {
    await clearCalibration();
    await PerformanceLogger().logEvent(event: 'CALIBRATION_STARTED');
  }

  Future<void> clearCalibration() async {
    _calibrationSamples.clear();
    _gazeOffset = Offset.zero;
    _history.clear();
    _calculatedAccuracy = 0.0;
    _lastRawPosition = null;
  }

  void addCalibrationPoint(
    CalibrationPoint point, {
    required Offset currentGaze,
  }) {
    _calibrationSamples.putIfAbsent(point.order, () => []).add(currentGaze);
  }

  Future<void> finishCalibration() async {
    if (_calibrationSamples.isEmpty) return;

    // 1. Calculate Drift Offset (using Center Point if available)
    if (_calibrationSamples.containsKey(2)) {
      final samples = _calibrationSamples[2]!;
      double avgX =
          samples.map((e) => e.dx).reduce((a, b) => a + b) / samples.length;
      double avgY =
          samples.map((e) => e.dy).reduce((a, b) => a + b) / samples.length;

      final view = PlatformDispatcher.instance.views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      // Offset = ScreenCenter - MeasuredCenter
      _gazeOffset = Offset((size.width / 2) - avgX, (size.height / 2) - avgY);
    }

    // 2. Real Accuracy Calculation (Variance/Stability)
    double totalVariance = 0;
    int groups = 0;

    _calibrationSamples.forEach((k, samples) {
      if (samples.length > 1) {
        // Centroid of this sample group
        double cx =
            samples.map((e) => e.dx).reduce((a, b) => a + b) / samples.length;
        double cy =
            samples.map((e) => e.dy).reduce((a, b) => a + b) / samples.length;

        // Sum of distances from centroid
        double sumDist = 0;
        for (var p in samples) sumDist += (Offset(cx, cy) - p).distance;
        totalVariance += (sumDist / samples.length);
        groups++;
      }
    });

    // Average variance across all calibration points
    double avgVar = groups > 0 ? totalVariance / groups : 50.0;

    // Map Variance to Percentage (0-100)
    // 0 variance = 100%. 100px variance = 0%.
    _calculatedAccuracy = (1.0 - (avgVar / 100.0)).clamp(0.01, 0.99);

    // -------------------------------------------------------------------------
    // ALGORITHM 2: Personalized Threshold Generation (The "Learn")
    // This algorithm computes a user-specific stability threshold based on
    // their unique jitter profile measured during calibration.
    // -------------------------------------------------------------------------
    _stabilityVarianceThreshold = (avgVar * 1.5).clamp(15.0, 60.0);

    // ACCURACY METRICS LOGGING
    await PerformanceLogger().logEvent(
      event: 'CALIBRATION_FINISHED',
      details: 'Personalized thresholds generated',
      oldValue: 'Default: 25.0',
      newValue: _stabilityVarianceThreshold.toStringAsFixed(2),
      reason: 'Accuracy: ${(_calculatedAccuracy * 100).toStringAsFixed(1)}%',
    );
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    currentGaze.value = const Offset(-100, -100);
    if (_cameraController?.value.isStreamingImages ?? false) {
      await _cameraController?.stopImageStream();
    }
  }

  Future<double> getCalibrationAccuracy() async => _calculatedAccuracy;

  void setStickyPosition(Offset? pos) {
    stickyPosition.value = pos;
  }

  List<CalibrationPoint> createStandardPoints(double width, double height) {
    const margin = 0.2;
    return [
      CalibrationPoint(x: width * margin, y: height * margin, order: 0),
      CalibrationPoint(x: width * (1 - margin), y: height * margin, order: 1),
      CalibrationPoint(x: width * 0.5, y: height * 0.5, order: 2),
      CalibrationPoint(x: width * margin, y: height * (1 - margin), order: 3),
      CalibrationPoint(
        x: width * (1 - margin),
        y: height * (1 - margin),
        order: 4,
      ),
    ];
  }

  void dispose() {
    _isTracking = false;
    _cameraController?.dispose();
    _faceDetector?.close();
    _gazeController.close();
    _accelerometerSub?.cancel();
  }
}
