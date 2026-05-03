import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/input_modes.dart';
import '../services/eye_tracking_service.dart';
import '../services/adaptive_dwell_service.dart';
import '../services/interaction_status_service.dart';
import '../services/voice_command_parser.dart';
import '../services/performance_logger.dart';
import '../services/voice_focus_service.dart';

class InputAwareButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final InputMode inputMode;
  final Duration? dwellDuration; // Optional override
  final Color progressColor;
  final BorderRadius? borderRadius;
  final String? voiceLabel; // Added for semantic matching
  final bool showVoiceIndex;

  const InputAwareButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.inputMode,
    this.dwellDuration,
    this.progressColor = const Color(0xFF6E4BC6),
    this.borderRadius,
    this.voiceLabel,
    this.showVoiceIndex = true,
  });

  @override
  State<InputAwareButton> createState() => _InputAwareButtonState();
}

class _InputAwareButtonState extends State<InputAwareButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _dwellTimer;
  Offset? _touchPosition;
  StreamSubscription? _gazeSubscription;
  StreamSubscription? _voiceSubscription;
  bool _isGazeInside = false;
  bool _isBlinking = false;
  bool _isWaitingForSecondBlink = false;
  Timer? _confirmationTimeout;
  int? _voiceId; // Numeric ID for voice indexing
  StreamSubscription? _focusRefreshSubscription;

  final _adaptiveService = AdaptiveDwellService();
  final _interactionService = InteractionStatusService();

  @override
  void initState() {
    super.initState();
    _adaptiveService.init();

    _controller = AnimationController(
      vsync: this,
      duration: widget.dwellDuration ?? _adaptiveService.currentDuration,
    );
    _updateGazeSubscription();
    _initVoiceFusionListener();

    // Register for voice indexing
    if (widget.onTap != null) {
      _voiceId = VoiceFocusService().register(
        widget.onTap!,
        label: widget.voiceLabel,
      );
      _focusRefreshSubscription = VoiceFocusService().refreshStream.listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _initVoiceFusionListener() {
    _voiceSubscription?.cancel();
    _voiceSubscription = _interactionService.voiceStream.listen((command) {
      _handleVoiceCommand(command);
    });
  }

  void _handleVoiceCommand(VoiceCommand command) {
    if (!mounted || widget.onTap == null) return;

    // MULTIMODAL FUSION LOGIC:
    // If the user is currently looking at this button (Eye Gaze)
    // or holding it (Dwell Touch), and says "Select" or "Confirm",
    // trigger the button immediately.
    final bool isBeingTargeted = _isGazeInside || _touchPosition != null;

    if (isBeingTargeted &&
        (command == VoiceCommand.select || command == VoiceCommand.confirm)) {
      debugPrint("Multimodal Fusion Triggered: Gaze/Dwell + Voice ($command)");

      // Research Performance Logging
      PerformanceLogger().logEvent(
        event: "MULTIMODAL_FUSION",
        details:
            "Targeted by ${_isGazeInside ? 'Gaze' : 'Dwell'} and triggered by Voice ($command)",
      );

      _interactionService.updateStatus(
        InteractionStatus(state: InteractionState.confirmed),
      );

      if (widget.onTap != null) {
        widget.onTap!();
      }

      _resetDwell(isCancellation: false);

      // Brief confirmation feedback
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _interactionService.clear();
      });
    }
  }

  @override
  void didUpdateWidget(InputAwareButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dwellDuration != widget.dwellDuration) {
      _controller.duration =
          widget.dwellDuration ?? _adaptiveService.currentDuration;
    }

    if (oldWidget.inputMode != widget.inputMode) {
      _updateGazeSubscription();
    }
  }

  void _updateGazeSubscription() {
    _gazeSubscription?.cancel();
    _gazeSubscription = null;
    _isGazeInside = false;
    _isWaitingForSecondBlink = false; // Reset on mode change
    _confirmationTimeout?.cancel(); // Reset on mode change
    _resetDwell(isCancellation: false);

    if (widget.inputMode == InputMode.eyeGaze ||
        widget.inputMode == InputMode.hybrid) {
      _gazeSubscription = EyeTrackingService().gazeStream.listen((data) {
        _checkGazeHit(data);
      });
    }
  }

  void _checkGazeHit(GazeData data) {
    if (!mounted || widget.onTap == null) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final Offset localPos = box.globalToLocal(Offset(data.x, data.y));
    final bool isInside = box.size.contains(localPos);

    if (isInside) {
      if (!_isGazeInside) {
        setState(() => _isGazeInside = true);
        
        // MAGNETIC SNAP: Lock cursor to button center
        final Offset center = box.localToGlobal(box.size.center(Offset.zero));
        EyeTrackingService().setStickyPosition(center);

        _interactionService.updateStatus(
          InteractionStatus(state: InteractionState.hovering),
        );
      }

      // Blink Detection (Probability < 0.35 indicates eyes closed - Sensitive)
      if (data.blinkProbability < 0.35) {
        if (!_isBlinking) {
          _isBlinking = true;
          _handleBlinkTrigger();
        }
      } else {
        _isBlinking = false;
      }
    } else {
      if (_isGazeInside) {
        setState(() {
          _isGazeInside = false;
          _isWaitingForSecondBlink = false;
          _confirmationTimeout?.cancel();
          
          // MAGNETIC UNLOCK: Release cursor
          EyeTrackingService().setStickyPosition(null);

          _interactionService.clear();
          _resetDwell();
        });
      }
    }
  }

  void _handleBlinkTrigger() {
    if (!_isWaitingForSecondBlink) {
      // FIRST BLINK: Start confirmation window
      setState(() => _isWaitingForSecondBlink = true);
      _interactionService.updateStatus(
        InteractionStatus(state: InteractionState.waitingConfirmation),
      );

      // Reset if user doesn't blink again within 2.5 seconds
      _confirmationTimeout?.cancel();
      _confirmationTimeout = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && _isGazeInside) {
          setState(() => _isWaitingForSecondBlink = false);
          _interactionService.updateStatus(
            InteractionStatus(state: InteractionState.hovering),
          );
        }
      });
    } else {
      // SECOND BLINK: Confirmed selection!
      _confirmationTimeout?.cancel();
      setState(() => _isWaitingForSecondBlink = false);

      _interactionService.updateStatus(
        InteractionStatus(state: InteractionState.confirmed),
      );

      if (widget.onTap != null) widget.onTap!();

      // Clear message after a short delay
      Future.delayed(
        const Duration(seconds: 1),
        () => _interactionService.clear(),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _dwellTimer?.cancel();
    _gazeSubscription?.cancel();
    _voiceSubscription?.cancel();
    _focusRefreshSubscription?.cancel();
    if (_isGazeInside) {
      EyeTrackingService().setStickyPosition(null);
    }
    if (_voiceId != null) VoiceFocusService().unregister(_voiceId!);
    super.dispose();
  }

  void _handleDwellStart(Offset localPosition) {
    if (widget.onTap == null) return;
    _controller.duration =
        widget.dwellDuration ?? _adaptiveService.currentDuration;
    setState(() => _touchPosition = localPosition);
    _controller.forward(from: 0.0);

    _dwellTimer?.cancel();
    _dwellTimer = Timer(_controller.duration!, () {
      if (mounted) {
        _adaptiveService.recordSuccess();
        widget.onTap!();
        _resetDwell(isCancellation: false);
      }
    });
  }

  void _handleDwellUpdate(Offset localPosition) {
    if (_touchPosition != null) {
      setState(() => _touchPosition = localPosition);
    }
  }

  void _resetDwell({bool isCancellation = false}) {
    if (isCancellation && _dwellTimer != null && _dwellTimer!.isActive) {
      _adaptiveService.recordCancellation();
    }
    _dwellTimer?.cancel();
    _controller.reset();
    if (mounted) {
      setState(() => _touchPosition = null);
    }
  }

  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: _buildInteractionWrapper(),
        ),
        // VOICE INDEX TAG (Premium Badge Style)
        if ((widget.inputMode == InputMode.voiceControl ||
                widget.inputMode == InputMode.hybrid) &&
            _voiceId != null &&
            widget.showVoiceIndex)
          Positioned(
            top: 2,
            right: 2,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "$_voiceId",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Roboto', // Reliable font
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInteractionWrapper() {
    if (widget.inputMode != InputMode.dwellTouch &&
        widget.inputMode != InputMode.eyeGaze &&
        widget.inputMode != InputMode.hybrid) {
      return InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        borderRadius: widget.borderRadius,
        child: widget.child,
      );
    }

    if (widget.inputMode == InputMode.eyeGaze ||
        widget.inputMode == InputMode.hybrid) {
      return Stack(
        clipBehavior: Clip.antiAlias,
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_touchPosition != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DwellPainter(
                    position: _touchPosition!,
                    progress: _controller,
                    color: widget.progressColor,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Listener(
      onPointerDown: (event) {
        setState(() => _isPressed = true);
        _handleDwellStart(event.localPosition);
      },
      onPointerMove: (event) => _handleDwellUpdate(event.localPosition),
      onPointerUp: (_) {
        setState(() => _isPressed = false);
        _resetDwell(isCancellation: true);
      },
      onPointerCancel: (_) {
        setState(() => _isPressed = false);
        _resetDwell(isCancellation: true);
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.antiAlias,
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_touchPosition != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DwellPainter(
                    position: _touchPosition!,
                    progress: _controller,
                    color: widget.progressColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DwellPainter extends CustomPainter {
  final Offset position;
  final Animation<double> progress;
  final Color color;

  _DwellPainter({
    required this.position,
    required this.progress,
    required this.color,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    const radius = 30.0;
    canvas.drawCircle(position, radius, bgPaint);
    final rect = Rect.fromCircle(center: position, radius: radius);
    final sweepAngle = 2 * pi * progress.value;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _DwellPainter oldDelegate) => true;
}
