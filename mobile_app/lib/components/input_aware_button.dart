import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/input_modes.dart';
import '../services/eye_tracking_service.dart';

class InputAwareButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final InputMode inputMode;
  final Duration dwellDuration;
  final Color progressColor;
  final BorderRadius? borderRadius;

  const InputAwareButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.inputMode,
    this.dwellDuration = const Duration(milliseconds: 1200), // Slightly faster
    this.progressColor = const Color(0xFF6E4BC6),
    this.borderRadius,
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
  bool _isGazeInside = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.dwellDuration,
    );
    _updateGazeSubscription();
  }

  @override
  void didUpdateWidget(InputAwareButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dwellDuration != widget.dwellDuration) {
      _controller.duration = widget.dwellDuration;
    }

    if (oldWidget.inputMode != widget.inputMode) {
      _updateGazeSubscription();
    }
  }

  void _updateGazeSubscription() {
    _gazeSubscription?.cancel();
    _gazeSubscription = null;
    _isGazeInside = false;
    _resetDwell();

    if (widget.inputMode == InputMode.eyeGaze) {
      _gazeSubscription = EyeTrackingService().gazeStream.listen((data) {
        _checkGazeHit(data.x, data.y);
      });
    }
  }

  void _checkGazeHit(double gazeX, double gazeY) {
    if (!mounted || widget.onTap == null) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final Offset localPos = box.globalToLocal(Offset(gazeX, gazeY));
    final bool isInside = box.size.contains(localPos);

    if (isInside && !_isGazeInside) {
      _isGazeInside = true;
      _handleDwellStart(localPos);
    } else if (!isInside && _isGazeInside) {
      _isGazeInside = false;
      _resetDwell();
    } else if (isInside && _isGazeInside) {
      _handleDwellUpdate(localPos);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _dwellTimer?.cancel();
    _gazeSubscription?.cancel();
    super.dispose();
  }

  void _handleDwellStart(Offset localPosition) {
    if (widget.onTap == null) return;

    setState(() {
      _touchPosition = localPosition;
    });
    _controller.forward(from: 0.0);

    _dwellTimer?.cancel();
    _dwellTimer = Timer(widget.dwellDuration, () {
      if (mounted) {
        widget.onTap!();
        // Don't reset immediately to give feedback, but normally we should or the user lifts finger
        // For now, let's keep showing full circle until lift?
        // Or just reset.
        // If we reset, the user might not know it activated if there is no audio feedback.
        // But the action normally navigates away or changes state.
        _resetDwell();
      }
    });
  }

  void _handleDwellUpdate(Offset localPosition) {
    if (_touchPosition != null) {
      setState(() {
        _touchPosition = localPosition;
      });
    }
  }

  void _resetDwell() {
    _dwellTimer?.cancel();
    _controller.reset();
    if (mounted) {
      setState(() {
        _touchPosition = null;
      });
    }
  }

  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: _buildInteractionWrapper(),
    );
  }

  Widget _buildInteractionWrapper() {
    // If not dwell or gaze mode, behave like a standard InkWell
    if (widget.inputMode != InputMode.dwellTouch &&
        widget.inputMode != InputMode.eyeGaze) {
      return InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        borderRadius: widget.borderRadius,
        child: widget.child,
      );
    }

    if (widget.inputMode == InputMode.eyeGaze) {
      return Stack(
        clipBehavior: Clip.antiAlias,
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

    // Dwell interaction
    return Listener(
      onPointerDown: (event) {
        setState(() => _isPressed = true);
        _handleDwellStart(event.localPosition);
      },
      onPointerMove: (event) => _handleDwellUpdate(event.localPosition),
      onPointerUp: (_) {
        setState(() => _isPressed = false);
        _resetDwell();
      },
      onPointerCancel: (_) {
        setState(() => _isPressed = false);
        _resetDwell();
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.antiAlias,
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

    final radius = 30.0;

    // Draw background
    canvas.drawCircle(position, radius, bgPaint);

    // Draw arc
    final rect = Rect.fromCircle(center: position, radius: radius);
    final sweepAngle = 2 * pi * progress.value;

    // Rotate -90 degrees to start from top
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _DwellPainter oldDelegate) => true;
}
