import 'package:flutter/material.dart';
import 'package:mobile_app/pages/quiz.dart'; // Op enum
import 'package:mobile_app/component/top_nav_bar.dart';
import 'package:mobile_app/pages/subject/hearing_math.dart';

class QuizHubPage extends StatelessWidget {
  const QuizHubPage({super.key});

  void _goToQuiz(BuildContext context, Op op) {
    Navigator.pushNamed(
      context,
      '/quizhearing',
      arguments: op,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF667EEA).withOpacity(0.08),
              const Color(0xFF764BA2).withOpacity(0.06),
              const Color(0xFFFFF8E1).withOpacity(0.9),
            ],
          ),
          image: const DecorationImage(
            image: AssetImage("assets/pattern-bg.jpeg"),
            fit: BoxFit.cover,
            opacity: 0.06,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ NAV BAR
                TopNavBar(selectedTab: 3),
                const SizedBox(height: 24),

                // ✅ TITLE SECTION WITH DECORATIVE LINE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6A11CB),
                              const Color(0xFF2575FC),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "ප්‍රශ්න",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D1B69),
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black12,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    "විවිධ ක්‍රියාකාරකම් තෝරාගෙන අභියෝගයට මුහුණ දෙන්න",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.deepPurple.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ✅ FOUR QUIZ CARDS - ENHANCED
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: GridView.count(
                        padding: const EdgeInsets.all(16),
                        crossAxisCount: 4,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.9,
                        children: [
                          _QuizCard(
                            symbol: "+",
                            title: "එකතු කිරීම",
                            gradient: const LinearGradient(
                              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => _goToQuiz(context, Op.add),
                          ),
                          _QuizCard(
                            symbol: "-",
                            title: "අඩු කිරීම",
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => _goToQuiz(context, Op.sub),
                          ),
                          _QuizCard(
                            symbol: "×",
                            title: "ගුණ කිරීම",
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => _goToQuiz(context, Op.mul),
                          ),
                          _QuizCard(
                            symbol: "÷",
                            title: "බෙදීම",
                            gradient: const LinearGradient(
                              colors: [Color(0xFF834D9B), Color(0xFFD04ED6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => _goToQuiz(context, Op.div),
                          ),
                        ],
                      ),
                    ),
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

class _QuizCard extends StatelessWidget {
  final String symbol;
  final String title;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuizCard({
    required this.symbol,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      symbol,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black26,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black26,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
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