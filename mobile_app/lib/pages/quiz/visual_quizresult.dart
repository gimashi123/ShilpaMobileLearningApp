import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class QuizResultPage extends StatefulWidget {
  final int score;
  final int total;
  final String operationName; // e.g., "එකතු කිරීම"
  final String? backRoute; // e.g., "/home_visual" (optional)

  const QuizResultPage({
    Key? key,
    required this.score,
    required this.total,
    required this.operationName,
    this.backRoute,
  }) : super(key: key);

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initAndSpeak();
  }

  Future<void> _initAndSpeak() async {
    try {
      await _tts.setLanguage("si-LK");
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);

      await _tts.speak(
        "ප්‍රශ්න ඉවරයි. ${widget.operationName} ප්‍රතිඵලය. "
        "ඔබගේ ලකුණු ${widget.total} න් ${widget.score}යි. "
        "නැවත පටන්ගන්න Restart බොත්තම ඔබන්න. ආපසු යන්න Back බොත්තම ඔබන්න.",
      );
    } catch (_) {}
  }

  Future<void> _stopSpeak() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopSpeak();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = widget.total == 0
        ? 0
        : ((widget.score / widget.total) * 100).round();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _initAndSpeak, // double tap to repeat result voice
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Result"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _stopSpeak();
              if (!mounted) return;
              if (widget.backRoute != null) {
                Navigator.pushReplacementNamed(context, widget.backRoute!);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "ඔබගේ ලකුණු",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "${widget.score} / ${widget.total}",
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "($percent%) • ${widget.operationName}",
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _stopSpeak();
                            if (!mounted) return;
                            Navigator.pop(
                              context,
                            ); // go back to quiz page (it can reset)
                          },
                          icon: const Icon(Icons.restart_alt),
                          label: const Text("Restart"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _stopSpeak();
                            if (!mounted) return;
                            if (widget.backRoute != null) {
                              Navigator.pushReplacementNamed(
                                context,
                                widget.backRoute!,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.home),
                          label: const Text("Back"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "නැවත ප්‍රතිඵලය අහන්න දෙපාරක් click කරන්න.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
