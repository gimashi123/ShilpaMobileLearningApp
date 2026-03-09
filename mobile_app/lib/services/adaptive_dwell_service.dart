import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'performance_logger.dart';

/// The core Adaptive Multimodal Interaction Optimization Framework.
/// This service dynamically adjusts the dwell activation duration based on
/// user stability and interaction performance.
class AdaptiveDwellService {
  static final AdaptiveDwellService _instance =
      AdaptiveDwellService._internal();
  factory AdaptiveDwellService() => _instance;
  AdaptiveDwellService._internal();

  // --- Constants ---
  static const String _keyDwellDuration = 'optimized_dwell_duration';
  static const double _defaultDwell = 2.0; // seconds
  static const double _minDwell = 1.0; // seconds (from requirements)
  static const double _maxDwell = 3.0; // seconds (from requirements)
  static const double _increment = 0.2; // +0.2s for false selection/instability
  static const double _decrement = 0.1; // -0.1s for high accuracy efficiency
  static const int _thresholdCancellations =
      3; // Number of cancellations to trigger increase
  static const int _thresholdSuccesses =
      5; // Number of successes to trigger decrease

  // --- State Variables ---
  double _currentDwellInSeconds = _defaultDwell;
  int _consecutiveCancellations = 0;
  int _consecutiveSuccesses = 0;
  bool _isInitialized = false;

  // Notification stream for UI adaptations (pop-ups/toasts)
  final _adaptationController =
      StreamController<DwellAdaptationEvent>.broadcast();
  Stream<DwellAdaptationEvent> get adaptationStream =>
      _adaptationController.stream;

  double get currentDwellDuration => _currentDwellInSeconds;
  Duration get currentDuration =>
      Duration(milliseconds: (_currentDwellInSeconds * 1000).toInt());

  /// Initializes the service and loads previously learned duration.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentDwellInSeconds =
          prefs.getDouble(_keyDwellDuration) ?? _defaultDwell;

      // Ensure bounds are respected even on load
      _currentDwellInSeconds = _currentDwellInSeconds.clamp(
        _minDwell,
        _maxDwell,
      );

      _isInitialized = true;
      debugPrint(
        'AdaptiveDwellService: Initialized with duration: ${_currentDwellInSeconds}s',
      );

      await PerformanceLogger().init();
      await PerformanceLogger().logEvent(
        event: 'INITIALIZE',
        details: 'Loaded optimized duration',
        newValue: '${_currentDwellInSeconds}s',
      );
    } catch (e) {
      debugPrint('AdaptiveDwellService: Init error: $e');
    }
  }

  /// Records a successful dwell selection.
  /// If the user is consistently successful, the system attempts to decrease dwell time for efficiency.
  Future<void> recordSuccess() async {
    _consecutiveCancellations = 0; // Reset instability counter
    _consecutiveSuccesses++;

    await PerformanceLogger().logEvent(
      event: 'SELECTION_SUCCESS',
      details: 'Consecutive successes: $_consecutiveSuccesses',
    );

    if (_consecutiveSuccesses >= _thresholdSuccesses &&
        _currentDwellInSeconds > _minDwell) {
      final oldVal = _currentDwellInSeconds;
      _currentDwellInSeconds = (_currentDwellInSeconds - _decrement).clamp(
        _minDwell,
        _maxDwell,
      );
      _consecutiveSuccesses = 0;

      if (oldVal != _currentDwellInSeconds) {
        await _applyAdaptation(oldVal, 'USER_PROFICIENCY_HIGH');
      }
    }
  }

  /// Records an aborted dwell attempt (user look-away or lift-off).
  /// If the user consistently cancels, the system assumes instability and increases dwell time.
  Future<void> recordCancellation() async {
    _consecutiveSuccesses = 0; // Reset proficiency counter
    _consecutiveCancellations++;

    await PerformanceLogger().logEvent(
      event: 'SELECTION_CANCELLATION',
      details: 'Consecutive cancellations: $_consecutiveCancellations',
    );

    if (_consecutiveCancellations >= _thresholdCancellations &&
        _currentDwellInSeconds < _maxDwell) {
      final oldVal = _currentDwellInSeconds;
      _currentDwellInSeconds = (_currentDwellInSeconds + _increment).clamp(
        _minDwell,
        _maxDwell,
      );
      _consecutiveCancellations = 0;

      if (oldVal != _currentDwellInSeconds) {
        await _applyAdaptation(oldVal, 'USER_INSTABILITY_DETECTED');
      }
    }
  }

  /// Applies the adjustment, saves to preferences, and notifies observers.
  Future<void> _applyAdaptation(double oldValue, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDwellDuration, _currentDwellInSeconds);

    final event = DwellAdaptationEvent(
      oldValue: oldValue,
      newValue: _currentDwellInSeconds,
      reason: reason,
      direction: _currentDwellInSeconds > oldValue
          ? AdaptationDirection.increased
          : AdaptationDirection.decreased,
    );

    _adaptationController.add(event);

    await PerformanceLogger().logEvent(
      event: 'DURATION_ADAPTED',
      details: 'Adaptive optimization event',
      oldValue: '${oldValue}s',
      newValue: '${_currentDwellInSeconds}s',
      reason: reason,
    );

    debugPrint(
      'AdaptiveDwellService: Optimized duration to ${_currentDwellInSeconds}s due to $reason',
    );
  }

  /// Resets the dwell duration to the system default (2.0s).
  /// This is essential for professional accessibility apps to recover from
  /// outlier sessions or user fatigue.
  Future<void> resetToDefault() async {
    final oldVal = _currentDwellInSeconds;
    _currentDwellInSeconds = _defaultDwell;
    _consecutiveCancellations = 0;
    _consecutiveSuccesses = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDwellDuration, _currentDwellInSeconds);

    final event = DwellAdaptationEvent(
      oldValue: oldVal,
      newValue: _currentDwellInSeconds,
      reason: 'USER_MANUAL_RESET',
      direction: _currentDwellInSeconds > oldVal
          ? AdaptationDirection.increased
          : AdaptationDirection.decreased,
    );

    _adaptationController.add(event);

    await PerformanceLogger().logEvent(
      event: 'MANUAL_RESET',
      details: 'User reset interaction settings to default',
      oldValue: '${oldVal}s',
      newValue: '${_currentDwellInSeconds}s',
    );

    debugPrint(
      'AdaptiveDwellService: Duration reset to default (2.0s) by user.',
    );
  }

  void dispose() {
    _adaptationController.close();
  }
}

/// Represents an adaptation event to be visualized in the UI.
class DwellAdaptationEvent {
  final double oldValue;
  final double newValue;
  final String reason;
  final AdaptationDirection direction;

  DwellAdaptationEvent({
    required this.oldValue,
    required this.newValue,
    required this.reason,
    required this.direction,
  });
}

enum AdaptationDirection { increased, decreased }
