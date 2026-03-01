import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class CognitiveGameLoadingScreen extends StatefulWidget {
  final String gameTitle;
  final String? targetRoute;
  final Duration duration;
  final bool autoNavigate;

  const CognitiveGameLoadingScreen({
    super.key,
    required this.gameTitle,
    this.targetRoute,
    this.duration = const Duration(seconds: 3),
    this.autoNavigate = true,
  }) : assert(
         !autoNavigate || (targetRoute != null && targetRoute != ''),
         'targetRoute is required when autoNavigate is true.',
       );

  @override
  State<CognitiveGameLoadingScreen> createState() =>
      _CognitiveGameLoadingScreenState();
}

class _CognitiveGameLoadingScreenState
    extends State<CognitiveGameLoadingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _timer = Timer(widget.duration, () {
      if (!mounted) return;
      if (!widget.autoNavigate || widget.targetRoute == null) {
        Navigator.of(context).pop();
        return;
      }
      final route = widget.targetRoute!;
      Navigator.pushReplacementNamed(context, route);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.gameTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'සූදානම් වෙමින්...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
