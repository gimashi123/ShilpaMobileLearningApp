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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ NAV BAR
              TopNavBar(selectedTab: 3),
              const SizedBox(height: 20),

              const Text(
                "ප්‍රශ්න",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),

              // ✅ FOUR QUIZ CARDS
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3 / 3,
                  children: [
                    _QuizCard(
                      symbol: "+",
                      title: "එකතු කිරීම",
                      onTap: () => _goToQuiz(context, Op.add),
                    ),
                    _QuizCard(
                      symbol: "-",
                      title: "අඩු කිරීම",
                      onTap: () => _goToQuiz(context, Op.sub),
                    ),
                    _QuizCard(
                      symbol: "×",
                      title: "ගුණ කිරීම",
                      onTap: () => _goToQuiz(context, Op.mul),
                    ),
                    _QuizCard(
                      symbol: "÷",
                      title: "බෙදීම",
                      onTap: () => _goToQuiz(context, Op.div),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final String symbol;
  final String title;
  final VoidCallback onTap;

  const _QuizCard({
    required this.symbol,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF7E57C2), Color(0xFFAB47BC)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              symbol,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
