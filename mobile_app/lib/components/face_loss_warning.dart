import 'package:flutter/material.dart';
import '../services/eye_tracking_service.dart';

class FaceLossWarning extends StatefulWidget {
  const FaceLossWarning({super.key});

  @override
  State<FaceLossWarning> createState() => _FaceLossWarningState();
}

class _FaceLossWarningState extends State<FaceLossWarning>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: EyeTrackingService().isFaceDetectedNotifier,
      builder: (context, isFaceDetected, child) {
        if (isFaceDetected) return const SizedBox.shrink();

        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Border flashing
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange.withOpacity(
                          0.5 + (_animation.value * 0.5),
                        ),
                        width: 8 + (_animation.value * 12),
                      ),
                    ),
                  ),
                  // Toast like message
                  Positioned(
                    top: 100, // Avoid overlapping with top statuses
                    left: 16,
                    right: 16,
                    child: SafeArea(
                      child: Center(
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.face_retouching_off,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    "මුහුණ හඳුනාගත නොහැක! තිරය දෙස බලන්න\nFace Not Detected! Look at the screen",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
