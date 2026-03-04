import 'dart:async';

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

  final _statusController = StreamController<InteractionStatus>.broadcast();
  Stream<InteractionStatus> get statusStream => _statusController.statusStream;

  void updateStatus(InteractionStatus status) {
    _statusController.add(status);
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
