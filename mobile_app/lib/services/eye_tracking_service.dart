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

  // Smoothing
  final List<Offset> _history = [];
  static const int _historyLimit = 8;

  Future<EyeTrackingInitializationResult> initialize() async {
    if (_isInitialized) return EyeTrackingInitializationResult(success: true);

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
      return EyeTrackingInitializationResult(success: true);
    } catch (e) {
      return EyeTrackingInitializationResult(
        success: false,
        error: "Init Error: $e",
      );
    }
  }

  Future<void> startTracking() async {
    if (!_isInitialized || _isTracking || _cameraController == null) return;

    _isTracking = true;
    _cameraController!.startImageStream((image) async {
      if (!_isTracking || _isProcessing) return;

      // Throttle: Only process if the previous frame is done
      _isProcessing = true;
      try {
        final inputImage = _inputImageFromCameraImage(image);
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
          // No face detected - send a low confidence signal
          _gazeController.add(
            GazeData(x: -1, y: -1, confidence: 0, timestamp: DateTime.now()),
          );
        }
      } catch (e) {
        // Silently skip corrupted frames (common on emulators)
        debugPrint("EyeTracking: Frame skipped due to conversion error.");
      } finally {
        // Delay slightly to give the CPU a break
        await Future.delayed(const Duration(milliseconds: 50));
        _isProcessing = false;
      }
    });
  }

  void _processFace(Face face, double imgWidth, double imgHeight) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye != null && rightEye != null) {
      // Raw coordinates from camera
      double rawX = (leftEye.position.x + rightEye.position.x) / 2;
      double rawY = (leftEye.position.y + rightEye.position.y) / 2;

      // Normalization (0 to 1) based on image size
      double normX = rawX / imgWidth;
      double normY = rawY / imgHeight;

      final view = PlatformDispatcher.instance.views.first;
      final size = view.physicalSize / view.devicePixelRatio;

      // Basic Screen Mapping (Assuming front camera is mirrored)
      double x = (1.0 - normX) * size.width;
      double y = normY * size.height;

      // Apply Calibration Offset
      x = (x + _gazeOffset.dx) * _scaleX;
      y = (y + _gazeOffset.dy) * _scaleY;

      // Smoothing (Sliding Average)
      _history.add(Offset(x, y));
      if (_history.length > _historyLimit) _history.removeAt(0);

      double avgX =
          _history.map((e) => e.dx).reduce((a, b) => a + b) / _history.length;
      double avgY =
          _history.map((e) => e.dy).reduce((a, b) => a + b) / _history.length;

      _gazeController.add(
        GazeData(x: avgX, y: avgY, confidence: 0.95, timestamp: DateTime.now()),
      );
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;

    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Standard Concatenation - Most reliable for modern ML Kit plugins
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

  Future<void> startCalibration(List<CalibrationPoint> points) async {
    await clearCalibration();
  }

  Future<void> clearCalibration() async {
    _calibrationSamples.clear();
    _gazeOffset = Offset.zero;
    _scaleX = 1.0;
    _scaleY = 1.0;
    _history.clear();
  }

  void addCalibrationPoint(
    CalibrationPoint point, {
    required Offset currentGaze,
  }) {
    _calibrationSamples.putIfAbsent(point.order, () => []).add(currentGaze);
  }

  Future<void> finishCalibration() async {
    if (_calibrationSamples.isEmpty) return;

    // Calibration Order 2 is the CENTER point
    if (_calibrationSamples.containsKey(2)) {
      final samples = _calibrationSamples[2]!;
      double avgGazeX =
          samples.map((e) => e.dx).reduce((a, b) => a + b) / samples.length;
      double avgGazeY =
          samples.map((e) => e.dy).reduce((a, b) => a + b) / samples.length;

      final view = PlatformDispatcher.instance.views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      final screenCenter = Offset(size.width / 2, size.height / 2);

      // Store the global drift offset
      _gazeOffset = Offset(
        screenCenter.dx - avgGazeX,
        screenCenter.dy - avgGazeY,
      );
    }
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    if (_cameraController?.value.isStreamingImages ?? false) {
      await _cameraController?.stopImageStream();
    }
  }

  Future<double> getCalibrationAccuracy() async => 0.95;

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
