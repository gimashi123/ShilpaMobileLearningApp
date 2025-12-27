import 'package:eye_tracking/eye_tracking.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class EyeTrackingService {
  static final EyeTrackingService _instance = EyeTrackingService._internal();
  factory EyeTrackingService() => _instance;
  EyeTrackingService._internal();

  final EyeTracking _plugin = EyeTracking();
  bool _isInitialized = false;

  StreamSubscription? _gazeSubscription;
  final _gazeController = StreamController<GazeData>.broadcast();

  Stream<GazeData> get gazeStream => _gazeController.stream;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // 1. Request Camera Permission
    var status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      return false;
    }

    try {
      // 2. Initialize Plugin
      await _plugin.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint("EyeTracking Init Error: $e");
      return false;
    }
  }

  Future<void> startTracking() async {
    if (!_isInitialized) await initialize();

    await _plugin.startTracking();

    // Listen to gaze data
    _gazeSubscription?.cancel();
    _gazeSubscription = _plugin.getGazeStream().listen((data) {
      _gazeController.add(data);
    });
  }

  Future<void> stopTracking() async {
    await _plugin.stopTracking();
    _gazeSubscription?.cancel();
    _gazeSubscription = null;
  }

  // --- CALIBRATION METHODS ---

  Future<void> startCalibration(List<CalibrationPoint> points) async {
    await _plugin.startCalibration(points);
  }

  Future<void> addCalibrationPoint(CalibrationPoint point) async {
    await _plugin.addCalibrationPoint(point);
  }

  Future<void> finishCalibration() async {
    await _plugin.finishCalibration();
  }

  Future<void> clearCalibration() async {
    await _plugin.clearCalibration();
  }

  Future<double> getCalibrationAccuracy() async {
    return await _plugin.getCalibrationAccuracy();
  }

  List<CalibrationPoint> createStandardPoints(double width, double height) {
    return EyeTracking.createStandardCalibration(
      screenWidth: width,
      screenHeight: height,
    );
  }

  void dispose() {
    stopTracking();
    _gazeController.close();
  }
}
