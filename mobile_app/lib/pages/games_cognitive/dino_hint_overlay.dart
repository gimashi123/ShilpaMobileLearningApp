import 'dart:async';
import 'dart:math' as Math;
import 'package:flutter/material.dart';

enum PathType { straight, wave, curve, zigzag }

class DinoHintOverlay extends StatefulWidget {
  final PathType pathType;
  final bool isVisible;
  final Offset? targetPosition;

  const DinoHintOverlay({
    super.key,
    required this.pathType,
    required this.isVisible,
    this.targetPosition,
  });

  @override
  State<DinoHintOverlay> createState() => _DinoHintOverlayState();
}

class _DinoHintOverlayState extends State<DinoHintOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isVisible) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(DinoHintOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible) {
      _controller.repeat();
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

  Path _getDinoPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    switch (widget.pathType) {
      case PathType.straight:
        path.moveTo(centerX, 100);
        path.lineTo(centerX, size.height - 100);
        break;
      case PathType.wave:
        const startY = 100.0;
        final endY = size.height - 100;
        for (double y = startY; y <= endY; y += 5) {
          final progress = (y - startY) / (endY - startY);
          final x = centerX + 60.0 * Math.sin(progress * 4 * Math.pi);
          if (y == startY) path.moveTo(x, y); else path.lineTo(x, y);
        }
        break;
      case PathType.curve:
        path.moveTo(80, centerY);
        path.quadraticBezierTo(centerX, 100, size.width - 80, centerY);
        break;
      case PathType.zigzag:
        final stepHeight = (size.height - 200) / 5;
        path.moveTo(80, 100);
        for (int i = 0; i < 5; i++) {
          final x = (i % 2 == 0) ? size.width - 80 : 80.0;
          final y = 100 + (i + 1) * stepHeight;
          path.lineTo(x, y);
        }
        break;
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              Offset handPosition;
              double tapScale = 1.0;
              double tapOpacity = 0.0;

              if (widget.targetPosition != null) {
                final tapProgress =
                    0.5 - (0.5 - _controller.value).abs();
                handPosition = Offset(
                  widget.targetPosition!.dx,
                  widget.targetPosition!.dy - 36 - (1 - tapProgress) * 18,
                );
                tapScale = 0.8 + (tapProgress * 0.45);
                tapOpacity = tapProgress.clamp(0.0, 1.0);
              } else {
                final path = _getDinoPath(size);
                final metricIterator = path.computeMetrics().iterator;
                if (!metricIterator.moveNext()) return const SizedBox();

                final metric = metricIterator.current;
                final tangent = metric.getTangentForOffset(
                  metric.length * _controller.value,
                );
                if (tangent == null) return const SizedBox();
                handPosition = tangent.position;
              }

              return Stack(
                children: [
                  if (widget.targetPosition != null)
                    Positioned(
                      left: widget.targetPosition!.dx - 18,
                      top: widget.targetPosition!.dy - 18,
                      child: Opacity(
                        opacity: tapOpacity,
                        child: Transform.scale(
                          scale: tapScale,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5).withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1E88E5).withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: handPosition.dx - 28,
                    top: handPosition.dy - 28,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 10,
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
                ],
              );
            },
          );
        },
      ),
    );
  }
}
