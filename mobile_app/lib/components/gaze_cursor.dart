import 'package:flutter/material.dart';
import '../services/eye_tracking_service.dart';

/// A gaze cursor that updates efficiently using ValueListenableBuilder.
/// Designed to be used in an Overlay to stay visible across navigation.
class GazeCursor extends StatelessWidget {
  const GazeCursor({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: EyeTrackingService().currentGaze,
      builder: (context, pos, _) {
        // If cursor is off-screen (default), don't render anything complex.
        if (pos.dx < 0 || pos.dy < 0) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable: EyeTrackingService().isStableNotifier,
          builder: (context, isStable, _) {
            return Positioned(
              left: pos.dx - (isStable ? 12 : 15),
              top: pos.dy - (isStable ? 12 : 15),
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: isStable ? 24 : 30,
                  height: isStable ? 24 : 30,
                  decoration: BoxDecoration(
                    color: (isStable ? Colors.greenAccent : Colors.blueAccent)
                        .withOpacity(0.35),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isStable ? Colors.greenAccent : Colors.blueAccent,
                      width: isStable ? 3 : 2,
                    ),
                    boxShadow: isStable
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isStable ? Colors.green : Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
