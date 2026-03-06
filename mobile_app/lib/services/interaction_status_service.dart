import 'dart:async';
import 'voice_command_parser.dart';

enum InteractionState {
  none,
  hovering,
  waitingConfirmation,
  blinkDetected,
  confirmed,
}

/// A centralized service to manage and broadcast the visual state of
/// multimodal interactions across the entire screen.
class InteractionStatusService {
  static final InteractionStatusService _instance =
      InteractionStatusService._internal();
  factory InteractionStatusService() => _instance;
  InteractionStatusService._internal();

  // Status controller for visual states (Hover, Confirm)
  final _statusController = StreamController<InteractionStatus>.broadcast();
  Stream<InteractionStatus> get statusStream => _statusController.statusStream;

  // Voice command controller for multimodal fusion
  final _voiceController = StreamController<VoiceCommand>.broadcast();
  Stream<VoiceCommand> get voiceStream => _voiceController.stream;

  void updateStatus(InteractionStatus status) {
    _statusController.add(status);
  }

  void emitVoiceCommand(VoiceCommand command) {
    _voiceController.add(command);
  }

  void clear() {
    _statusController.add(InteractionStatus(state: InteractionState.none));
  }
}

class InteractionStatus {
  final InteractionState state;
  final String? label;

  InteractionStatus({required this.state, this.label});
}

extension on StreamController<InteractionStatus> {
  Stream<InteractionStatus> get statusStream => stream;
}
