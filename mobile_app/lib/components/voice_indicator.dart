import 'package:flutter/material.dart';
import 'dart:async';
import '../services/interaction_status_service.dart';
import '../services/voice_command_parser.dart';

class VoiceIndicator extends StatefulWidget {
  const VoiceIndicator({super.key});

  @override
  State<VoiceIndicator> createState() => _VoiceIndicatorState();
}

class _VoiceIndicatorState extends State<VoiceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  StreamSubscription? _voiceSub;
  String _statusMessage = "අහගෙන ඉන්නවා..."; // Listening...
  bool _isRecognized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _initListener();
  }

  void _initListener() {
    _voiceSub = InteractionStatusService().voiceStream.listen((command) {
      if (command != VoiceCommand.unknown && mounted) {
        setState(() {
          _isRecognized = true;
          _statusMessage = "විධානය හඳුනාගත්තා!"; // Command Recognized
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isRecognized = false;
              _statusMessage = "අහගෙන ඉන්නවා...";
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _voiceSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _animation,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_isRecognized ? Colors.teal : Colors.redAccent)
                  .withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isRecognized ? Colors.teal : Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecognized ? Icons.check : Icons.mic,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _statusMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}
