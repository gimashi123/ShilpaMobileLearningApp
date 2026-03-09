import 'dart:async';
import 'package:flutter/foundation.dart';

/// Data structure for a voice-controllable element on the screen.
class VoiceElement {
  final int id;
  final String? label;
  final VoidCallback onTap;

  VoiceElement({required this.id, this.label, required this.onTap});
}

/// Service to manage focusable elements for voice navigation.
/// Assigns IDs and matches voice commands to UI actions.
class VoiceFocusService {
  static final VoiceFocusService _instance = VoiceFocusService._internal();
  factory VoiceFocusService() => _instance;
  VoiceFocusService._internal();

  final List<VoiceElement> _elements = [];
  int _idCounter = 1;

  // Stream to notify UI when indexes need refresh
  final _refreshController = StreamController<void>.broadcast();
  Stream<void> get refreshStream => _refreshController.stream;

  /// Registers a button. Returns a unique ID for this session.
  int register(VoidCallback action, {String? label}) {
    final id = _idCounter++;
    _elements.add(VoiceElement(id: id, label: label, onTap: action));

    // Batch refresh notifications
    _scheduleRefresh();
    return id;
  }

  /// Unregisters a button.
  void unregister(int id) {
    _elements.removeWhere((e) => e.id == id);
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    // Avoid spamming refreshes during build
    Future.microtask(() => _refreshController.add(null));
  }

  /// Finds and triggers an element by ID (e.g. "Select 1")
  bool triggerById(int id) {
    try {
      final element = _elements.firstWhere((e) => e.id == id);
      element.onTap();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Finds and triggers an element by label (e.g. "Select Noun")
  bool triggerByLabel(String input) {
    input = input.toLowerCase().trim();

    // 1. Direct label match
    for (var element in _elements) {
      if (element.label != null && element.label!.toLowerCase() == input) {
        element.onTap();
        return true;
      }
    }

    // 2. Fuzzy matching (Levenshtein logic reused or called)
    // For now, let's keep it simple: Contains
    for (var element in _elements) {
      if (element.label != null &&
          element.label!.toLowerCase().contains(input)) {
        element.onTap();
        return true;
      }
    }

    return false;
  }

  /// Resets the counter when screen changes
  void clear() {
    _elements.clear();
    _idCounter = 1;
    _refreshController.add(null);
  }

  List<VoiceElement> get activeElements => List.unmodifiable(_elements);
}
