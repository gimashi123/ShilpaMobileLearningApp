import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// A service to log performance metrics for research and evaluation.
/// This supports the "Continuous Performance Logging" requirement of the framework.
class PerformanceLogger {
  static final PerformanceLogger _instance = PerformanceLogger._internal();
  factory PerformanceLogger() => _instance;
  PerformanceLogger._internal();

  File? _logFile;

  /// Initializes the log file in the application documents directory.
  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/interaction_performance_logs.csv';
      _logFile = File(path);

      if (!await _logFile!.exists()) {
        await _logFile!.writeAsString(
          'Timestamp,Event,Details,OldValue,NewValue,Reason\n',
        );
      }
      debugPrint('PerformanceLogger: Initialized at $path');
    } catch (e) {
      debugPrint('PerformanceLogger: Initialization error: $e');
    }
  }

  /// Logs an interaction event to the CSV file.
  Future<void> logEvent({
    required String event,
    String details = '',
    String oldValue = '',
    String newValue = '',
    String reason = '',
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry =
        '$timestamp,$event,"$details",$oldValue,$newValue,"$reason"\n';

    debugPrint('PerformanceLogger: $logEntry');

    try {
      if (_logFile == null) await init();
      await _logFile?.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      debugPrint('PerformanceLogger: Error writing log: $e');
    }
  }

  /// Retrieves the log file for sharing or export.
  Future<File?> getLogFile() async {
    if (_logFile == null) await init();
    return _logFile;
  }
}
