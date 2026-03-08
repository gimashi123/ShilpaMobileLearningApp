import 'dart:async';
import 'package:flutter/material.dart';

class IdleDinoOverlay extends StatefulWidget {
  final Widget child; // The main game UI
  final String gifPath;

  const IdleDinoOverlay({super.key, required this.child, required this.gifPath});

  @override
  State<IdleDinoOverlay> createState() => _IdleDinoOverlayState();
}

class _IdleDinoOverlayState extends State<IdleDinoOverlay> with SingleTickerProviderStateMixin {
  Timer? _idleTimer;
  bool _isDinoRunning = false;
  late AnimationController _moveController;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Speed of the dino crossing
    );

    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _stopDino(); // Hide dino if it's currently on screen
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 15), _startDino);
  }

  void _startDino() {
    if (!mounted) return;
    setState(() => _isDinoRunning = true);
    _moveController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _isDinoRunning = false);
      _resetIdleTimer(); // Restart the 15s wait after it finishes running
    });
  }

  void _stopDino() {
    if (_isDinoRunning) {
      _moveController.stop();
      setState(() => _isDinoRunning = false);
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _resetIdleTimer(), // Detects any touch on the screen
      child: Stack(
        children: [
          widget.child, // This is your PatternGamePage
          if (_isDinoRunning)
            IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final startX = constraints.maxWidth;
                  final endX = -200.0;
                  final top = constraints.maxHeight * 0.7;

                  return AnimatedBuilder(
                    animation: _moveController,
                    child: Image.asset(widget.gifPath, width: 200),
                    builder: (context, child) {
                      final left = Tween<double>(
                        begin: startX,
                        end: endX,
                      ).evaluate(_moveController);

                      return Transform.translate(
                        offset: Offset(left, top),
                        child: child,
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
