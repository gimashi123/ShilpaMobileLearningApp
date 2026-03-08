import 'package:flutter/material.dart';

class FindImageHandHintOverlay extends StatefulWidget {
  final bool isVisible;
  final Offset? targetPosition;

  const FindImageHandHintOverlay({
    super.key,
    required this.isVisible,
    this.targetPosition,
  });

  @override
  State<FindImageHandHintOverlay> createState() =>
      _FindImageHandHintOverlayState();
}

class _FindImageHandHintOverlayState extends State<FindImageHandHintOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.isVisible && widget.targetPosition != null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(FindImageHandHintOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldAnimate = widget.isVisible && widget.targetPosition != null;
    if (shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || widget.targetPosition == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = Curves.easeInOut.transform(_controller.value);
          final tapWave = 1.0 - (_controller.value - 0.68).abs() / 0.32;
          final ringOpacity = tapWave.clamp(0.0, 1.0).toDouble();
          final ringScale = 0.75 + (ringOpacity * 0.45);
          final handLift = 22.0 * (1.0 - value);
          final handScale = 1.0 - (ringOpacity * 0.1);

          return Stack(
            children: [
              Positioned(
                left: widget.targetPosition!.dx - 22,
                top: widget.targetPosition!.dy - 22,
                child: Opacity(
                  opacity: ringOpacity,
                  child: Transform.scale(
                    scale: ringScale,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.45),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: widget.targetPosition!.dx - 28,
                top: widget.targetPosition!.dy - 68 - handLift,
                child: Transform.scale(
                  scale: handScale,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pan_tool_alt_rounded,
                      size: 30,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
