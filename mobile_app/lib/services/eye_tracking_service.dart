import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/services.dart';

class GazeData {
  final double x;
  final double y;
  final double confidence;
  final DateTime timestamp;

  GazeData({
    required this.x,
    required this.y,
    required this.confidence,
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

  bool get isInitialized => _isInitialized;

  // --- CALIBRATION DATA ---
  final Map<int, List<Offset>> _calibrationSamples = {};
  Offset _gazeOffset = Offset.zero;
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  double _calculatedAccuracy = 0.0;

  // Smoothing
  final List<Offset> _history = [];
  static const int _historyLimit = 10;

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

        final faces = await _faceDetector?.processImage(inputImage);

        if (faces != null && faces.isNotEmpty && _isTracking) {
          _processFace(
            faces.first,
            image.width.toDouble(),
            image.height.toDouble(),
          );
        } else {
          // Send 0 confidence to indicate no face detected
          _gazeController.add(
            GazeData(x: -1, y: -1, confidence: 0, timestamp: DateTime.now()),
          );
        }
      } catch (e) {
        debugPrint("EyeTracking: Processing error: $e");
      } finally {
        // Essential delay for emulator stability
        await Future.delayed(const Duration(milliseconds: 100));
        _isProcessing = false;
      }
    });
  }

  InputImage? _processCameraImage(CameraImage image) {
    try {
      final sensorOrientation =
          _cameraController!.description.sensorOrientation;
      final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      if (rotation == null) return null;

      // FOR ANDROID, WE MANUALLY CONVERT TO NV21 TO PREVENT IllegalArgumentException
      if (Platform.isAndroid) {
        final nv21Bytes = _yuv420ToNv21(image);
        return InputImage.fromBytes(
          bytes: nv21Bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21, // Use NV21 explicitly
            bytesPerRow: image.width,
          ),
        );
      } else {
        // IOS logic (BGRA8888)
        final format = InputImageFormatValue.fromRawValue(image.format.raw);
        if (format == null) return null;

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

  void _processFace(Face face, double imgWidth, double imgHeight) {
    // We switch here to HEAD POSE tracking (Yaw/Pitch) which acts as a 'Virtual Joystick'
    // Attached to the nose. This is far more intuitive for 'Gaze' control than raw Cartesian movement.

    // Yaw = Left/Right (Degrees). Pitch = Up/Down (Degrees).
    final yaw = face.headEulerAngleY ?? 0;
    final pitch = face.headEulerAngleX ?? 0;

    final view = PlatformDispatcher.instance.views.first;
    final size = view.physicalSize / view.devicePixelRatio;

    // Sensitivity: 30 pixels per degree of rotation
    const sensitivity = 30.0;
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

    // Smoothing (Sliding Window)
    _history.add(Offset(targetX, targetY));
    if (_history.length > _historyLimit) _history.removeAt(0);

    double avgX =
        _history.map((e) => e.dx).reduce((a, b) => a + b) / _history.length;
    double avgY =
        _history.map((e) => e.dy).reduce((a, b) => a + b) / _history.length;

    _gazeController.add(
      GazeData(x: avgX, y: avgY, confidence: 0.9, timestamp: DateTime.now()),
    );
  }

  // --- CALIBRATION INTERFACE ---
  Future<void> startCalibration(List<CalibrationPoint> points) async {
    await clearCalibration();
  }

  Future<void> clearCalibration() async {
    _calibrationSamples.clear();
    _gazeOffset = Offset.zero;
    _history.clear();
    _calculatedAccuracy = 0.0;
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

    debugPrint(
      "EyeTracking: Accuracy: ${(_calculatedAccuracy * 100).toStringAsFixed(1)}%",
    );
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    if (_cameraController?.value.isStreamingImages ?? false) {
      await _cameraController?.stopImageStream();
    }
  }

  Future<double> getCalibrationAccuracy() async => _calculatedAccuracy;

  List<CalibrationPoint> createStandardPoints(double width, double height) {
    const margin = 0.15;
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
  }
}
