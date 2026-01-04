import 'package:flutter/material.dart';

class ResultPagee extends StatefulWidget {
  final String op;
  final int correctCount;
  final int score;

  const ResultPagee({
    super.key,
    required this.op,
    required this.correctCount,
    required this.score,
  });

  @override
  State<ResultPagee> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPagee> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _scoreAnim;
  late final Animation<double> _progressAnim;
  late final List<Animation<double>> _starScales;

  int get stars {
    if (widget.score >= 90) return 3;
    if (widget.score >= 60) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scoreAnim = IntTween(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );

    _progressAnim = Tween<double>(begin: 0.0, end: widget.correctCount / 10.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );

    // staggered star animations
    _starScales = List.generate(3, (i) {
      final start = 0.65 + i * 0.12;
      final end = start + 0.25;
      final target = i < stars ? 1.0 : 0.0;
      return Tween<double>(begin: 0.0, end: target).animate(
        CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.elasticOut)),
      );
    });

    // start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _backToHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Decorative gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFe8f0ff), Color(0xFFfbe9ff)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // soft decorative circles
          Positioned(
            top: -60,
            left: -40,
            child: Container(width: 180, height: 180, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle)),
          ),
          Positioned(
            bottom: -80,
            right: -50,
            child: Container(width: 260, height: 260, decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.06), shape: BoxShape.circle)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: _backToHome,
                      ),
                      const Spacer(),
                      // small celebratory icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.emoji_events, color: Colors.amber),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  // Title block
                  Column(
                    children: [
                      const Text(
                        "Quiz Completed",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Math ${widget.op} Quiz",
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Main result card
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // animated score with glow
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${_scoreAnim.value}",
                                        style: const TextStyle(
                                          fontSize: 54,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "SCORE",
                                        style: TextStyle(fontSize: 13, color: Colors.black54, letterSpacing: 2),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Correct count and progress
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Correct", style: TextStyle(color: Colors.black87, fontSize: 16)),
                                    Text("${widget.correctCount} / 10", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: LinearProgressIndicator(
                                    value: _progressAnim.value,
                                    minHeight: 12,
                                    backgroundColor: Colors.grey.shade200,
                                    color: Colors.deepPurple,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Animated stars
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (i) {
                                    final scale = _starScales[i].value;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Icon(
                                          i < stars ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                          size: 36,
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                const SizedBox(height: 14),

                                // motivational text
                                Text(
                                  widget.score >= 80 ? "Great job!" : (widget.score >= 50 ? "Nice attempt!" : "Keep practicing!"),
                                  style: TextStyle(fontSize: 15, color: Colors.black.withOpacity(0.75)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // action buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _backToHome,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text("Back to Home", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.deepPurple.withOpacity(0.7)),
                          ),
                          child: const Text("Try Again", style: TextStyle(fontSize: 16, color: Colors.deepPurple)),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
