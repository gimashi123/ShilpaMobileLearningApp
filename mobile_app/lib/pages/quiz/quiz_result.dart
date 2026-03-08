import 'package:flutter/material.dart';

class ResultPage extends StatefulWidget {
  final int score;
  final int total;

  const ResultPage({super.key, required this.score, required this.total});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartbeatAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _heartbeatAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(_heartbeatAnimation);

    _heartbeatAnimation.repeat(reverse: true);
  }

  @override
  void dispose() {
    _heartbeatAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double percentage = widget.score / widget.total;

    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Result")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                percentage >= 0.5
                    ? Icons.emoji_events
                    : Icons.sentiment_dissatisfied,
                size: 120,
                color: percentage >= 0.5 ? Colors.orange : Colors.red,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Score: ${widget.score} / ${widget.total}",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Text(
              percentage >= 0.5 ? "🎉 Great Job!" : "Keep Practicing!",
              style: const TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Back to Quiz Hub"),
            ),
          ],
        ),
      ),
    );
  }
}
