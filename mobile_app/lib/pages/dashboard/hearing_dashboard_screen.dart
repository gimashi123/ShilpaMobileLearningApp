import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_app/pages/subject/hearing_math.dart';
import 'package:mobile_app/session/session.dart';
import 'package:mobile_app/component/top_nav_bar.dart';

// IMPORTANT: Op and QuizPagehearing are in quiz.dart
import 'package:mobile_app/pages/quiz.dart';

class HearingDashboardScreen extends StatefulWidget {
  const HearingDashboardScreen({super.key});

  @override
  State<HearingDashboardScreen> createState() => _HearingDashboardScreenState();
}

class _HearingDashboardScreenState extends State<HearingDashboardScreen> {
  String userName = "";

  @override
  void initState() {
    super.initState();
    userName = Session.userName ?? "Student";
  }

  Future<void> _openQuizPicker() async {
    final Op? selected = await showDialog<Op>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            "Choose Quiz Type",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B69),
            ),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _QuizTypeBtn(
                label: "+",
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                ),
                onTap: () => Navigator.pop(ctx, Op.add),
              ),
              _QuizTypeBtn(
                label: "-",
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                ),
                onTap: () => Navigator.pop(ctx, Op.sub),
              ),
              _QuizTypeBtn(
                label: "×",
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                onTap: () => Navigator.pop(ctx, Op.mul),
              ),
              _QuizTypeBtn(
                label: "÷",
                gradient: const LinearGradient(
                  colors: [Color(0xFF834D9B), Color(0xFFD04ED6)],
                ),
                onTap: () => Navigator.pop(ctx, Op.div),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    Navigator.pushNamed(
      context,
      '/quizhearing',
      arguments: selected,
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
              const Color(0xFF667EEA).withOpacity(0.15),
              const Color(0xFF764BA2).withOpacity(0.12),
              const Color(0xFFFFF8E1).withOpacity(0.95),
            ],
          ),
          image: const DecorationImage(
            image: AssetImage("assets/pattern-bg.jpeg"),
            fit: BoxFit.cover,
            opacity: 0.08,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // TOP NAV BAR - ENHANCED
                // =====================================================
                TopNavBar(selectedTab: 0),
                const SizedBox(height: 24),

                // =====================================================
                // WELCOME SECTION
                // =====================================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6A11CB).withOpacity(0.9),
                        const Color(0xFF2575FC).withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.7),
                            ],
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF6A11CB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "සාදරයෙන් පිළිගනිමු",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black12,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // =====================================================
                // SUBJECTS TITLE
                // =====================================================
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
                        "ඔබගේ විෂයන්",
                        style: TextStyle(
                          fontSize: 32,
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
                    "ඔබගේ ඉගෙනීම ආරම්භ කරන්න",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.deepPurple.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // =====================================================
                // MAIN GRID - ENHANCED
                // =====================================================
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
                      child: _LessonsGrid(
                        onTap: (title, route) {
                          if (route == '/quizhearing') {
                            _openQuizPicker();
                          } else if (route == '/quizhear') {
                            Navigator.pushNamed(context, '/quizhear');
                          } else {
                            Navigator.pushNamed(context, route);
                          }
                        },
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

// =====================================================
// QUIZ TYPE BUTTON - ENHANCED
// =====================================================
class _QuizTypeBtn extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuizTypeBtn({
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.3),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}

// =====================================================
// LESSONS GRID - ENHANCED
// =====================================================
class _LessonsGrid extends StatelessWidget {
  final void Function(String title, String route) onTap;

  const _LessonsGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(4),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2 / 3,
      children: [
        _gridItem(
          context,
          "ගණිතය",
          '📐',
          '/math_lessons',
          const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _gridItem(
          context,
          "සිංහල",
          '📖',
          '/quizhearing',
          const LinearGradient(
            colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _gridItem(
          context,
          "ප්‍රශ්න",
          '❓',
          '/quizhear',
          const LinearGradient(
            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _gridItem(
          context,
          "GAMES",
          '🎮',
          '/quizhearing',
          const LinearGradient(
            colors: [Color(0xFF834D9B), Color(0xFFD04ED6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  Widget _gridItem(
    BuildContext context,
    String title,
    String emoji,
    String route,
    Gradient gradient,
  ) {
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
          onTap: () => onTap(title, route),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
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