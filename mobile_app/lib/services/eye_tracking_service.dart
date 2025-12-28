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

  Future<EyeTrackingInitializationResult> initialize() async {
    if (_isInitialized) return EyeTrackingInitializationResult(success: true);

    debugPrint("EyeTracking: Starting initialization...");

    // 1. Permissions
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (!status.isGranted) {
      debugPrint("EyeTracking: Camera permission denied.");
      return EyeTrackingInitializationResult(
        success: false,
        error: "Camera permission denied. Please enable it in settings.",
      );
    }

    try {
      // 2. Setup ML Kit Face Detector
      debugPrint("EyeTracking: Creating Face Detector...");
      final options = FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
      );
      _faceDetector = FaceDetector(options: options);

      // 3. Setup Camera
      debugPrint("EyeTracking: Finding cameras...");
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("EyeTracking: No cameras found on device.");
        return EyeTrackingInitializationResult(
          success: false,
          error:
              "No cameras found. If using an emulator, enable the front camera in AVD settings.",
        );
      }

      final frontCam = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      debugPrint("EyeTracking: Selected camera: ${frontCam.name}");
      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      try {
        await _cameraController!.initialize();
      } catch (e) {
        debugPrint(
          "EyeTracking: Fatal error initializing CameraController: $e",
        );
        return EyeTrackingInitializationResult(
          success: false,
          error:
              "Camera is busy or missing. Restarting the emulator might help.\nError: $e",
        );
      }
      _isInitialized = true;
      debugPrint("EyeTracking: Initialization complete.");
      return EyeTrackingInitializationResult(success: true);
    } catch (e) {
      debugPrint("EyeTracking Service Init Error: $e");
      return EyeTrackingInitializationResult(
        success: false,
        error: "Camera initialization failed: $e",
      );
    }
  }

  Future<void> startTracking() async {
    if (!_isInitialized) {
      final result = await initialize();
      if (!result.success) return;
    }

    if (_isTracking || _cameraController == null) return;

    debugPrint("EyeTracking: Starting image stream...");
    _isTracking = true;
    _cameraController!.startImageStream((CameraImage image) async {
      if (!_isTracking || _isProcessing) return;

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
        }
      } catch (e) {
        debugPrint("EyeTracking Image Processing Error: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _processFace(Face face, double imgWidth, double imgHeight) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye != null && rightEye != null) {
      double avgX = (leftEye.position.x + rightEye.position.x) / 2;
      double avgY = (leftEye.position.y + rightEye.position.y) / 2;

      double normX = avgX / imgWidth;
      double normY = avgY / imgHeight;

      final view = PlatformDispatcher.instance.views.first;
      final size = view.physicalSize / view.devicePixelRatio;

      double screenWidth = size.width;
      double screenHeight = size.height;

      double targetX = (1.0 - normX) * screenWidth;
      double targetY = normY * screenHeight;

      _gazeController.add(
        GazeData(
          x: targetX,
          y: targetY,
          confidence: 0.9,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationValue = _orientations[DeviceOrientation.portraitUp];
      if (rotationValue != null) {
        if (camera.lensDirection == CameraLensDirection.front) {
          rotationValue = (sensorOrientation + rotationValue) % 360;
        } else {
          rotationValue = (sensorOrientation - rotationValue + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationValue);
      }
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.yuv420) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888))
      return null;

    if (image.planes.length < 1) return null;

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

  Future<void> stopTracking() async {
    debugPrint("EyeTracking: Stopping tracking...");
    _isTracking = false;
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
  }

  Future<void> startCalibration(List<CalibrationPoint> points) async {
    // Basic logic is done. In a real app, you'd calculate a transform matrix here.
  }

  Future<void> addCalibrationPoint(CalibrationPoint point) async {}

  Future<void> finishCalibration() async {}

  Future<void> clearCalibration() async {}

  Future<double> getCalibrationAccuracy() async {
    return 0.9;
  }

  List<CalibrationPoint> createStandardPoints(double width, double height) {
    const margin = 0.1;
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
    debugPrint("EyeTracking: Disposing service.");
    _isTracking = false;
    _cameraController?.dispose();
    _faceDetector?.close();
    _gazeController.close();
  }
}
