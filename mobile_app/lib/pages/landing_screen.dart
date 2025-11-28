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
    return Scaffold(
      backgroundColor: const Color(0xFF5A2DCC),
      body: Stack(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C0430),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "ඔබේ විශේෂ අවශ්‍යතාව තෝරන්න",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Visual
                      _DisabilityCard(
                        label: "දෘශ්‍ය",
                        asset: "assets/visual.png",
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

                      // Hearing
                      _DisabilityCard(
                        label: "ශ්‍රවණ",
                        asset: "assets/hearing.png",
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

                      // Physical
                      _DisabilityCard(
                        label: "ශාරීරික",
                        asset: "assets/physical.png",
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

                      // Cognitive
                      _DisabilityCard(
                        label: "ඥානීය",
                        asset: "assets/cognitive.png",
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
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 🔊 Replay button
          Positioned(
            top: 32,
            right: 24,
            child: Material(
              color: Colors.white.withOpacity(0.9),
              shape: const CircleBorder(),
              elevation: 3,
              child: IconButton(
                icon: const Icon(Icons.volume_up, color: Color(0xFF5A2DCC)),
                tooltip: 'ආවර්ජනයෙන් ශ්‍රවණය කරන්න',
                onPressed: _speakInstruction,
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
  final VoidCallback onTap;

  const _DisabilityCard({
    required this.label,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 80,
        height: 90,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Image.asset(asset, fit: BoxFit.contain)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
