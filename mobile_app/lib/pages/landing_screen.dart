import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_app/pages/auth/create_account_screen.dart';
import 'package:mobile_app/pages/models/disability_type.dart';

class ChooseDisabilityPage extends StatefulWidget {
  const ChooseDisabilityPage({super.key});

  @override
  State<ChooseDisabilityPage> createState() => _ChooseDisabilityPageState();
}

class _ChooseDisabilityPageState extends State<ChooseDisabilityPage> {
  final FlutterTts _tts = FlutterTts();

  static const String _instructionText = 'ඔබේ විශේෂ අවශ්‍යතාව තෝරන්න';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakInstruction();
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakInstruction() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    var ok = await _tts.setLanguage('si-LK');
    if (ok == 0) {
      await _tts.setLanguage('en-US');
    }

    await _tts.stop();
    await _tts.speak(_instructionText);
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _DisabilityCard(
        label: "දෘශ්‍ය",
        asset: "assets/visual.png",
        accent: const Color(0xFF6C3BFF),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegisterPage(
                disabilityType: DisabilityType.visual,
              ),
            ),
          );
        },
      ),
      _DisabilityCard(
        label: "ශ්‍රවණ",
        asset: "assets/hearing.png",
        accent: const Color(0xFF00C2A8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegisterPage(
                disabilityType: DisabilityType.hearing,
              ),
            ),
          );
        },
      ),
      _DisabilityCard(
        label: "ශාරීරික",
        asset: "assets/physical.png",
        accent: const Color(0xFFFF7A5A),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegisterPage(
                disabilityType: DisabilityType.physical,
              ),
            ),
          );
        },
      ),
      _DisabilityCard(
        label: "ඥානීය",
        asset: "assets/cognitive.png",
        accent: const Color(0xFF4DA0FF),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegisterPage(
                disabilityType: DisabilityType.cognitive,
              ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5A2DCC), Color(0xFF1E0747)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      constraints: const BoxConstraints(maxWidth: 920),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF9A6CFF), Color(0xFF6C3BFF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.accessibility_new, color: Colors.white, size: 34),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "ඔබේ විශේෂ අවශ්‍යතාව තෝරන්න",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4)
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "ඔබට සුදුසු කණ්ඩායම තෝරන්න — පහසුවෙන් කරගන්න.",
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Cards (responsive Wrap)
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: cards,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Replay floating button
          Positioned(
            top: 20,
            right: 18,
            child: Semantics(
              button: true,
              label: 'Replay instruction',
              child: Material(
                elevation: 6,
                shape: const CircleBorder(),
                color: Colors.white,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _speakInstruction,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.volume_up, color: Color(0xFF5A2DCC)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabilityCard extends StatelessWidget {
  final String label;
  final String asset;
  final Color accent;
  final VoidCallback onTap;

  const _DisabilityCard({
    required this.label,
    required this.asset,
    required this.onTap,
    this.accent = const Color(0xFF6C3BFF),
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width > 600 ? 180 : 140;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.12), Colors.white.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [accent, accent.withOpacity(0.7)]),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 3)],
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
