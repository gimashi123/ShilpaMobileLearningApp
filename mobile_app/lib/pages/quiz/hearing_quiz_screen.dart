import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_app/component/top_nav_bar.dart';

class QuizPageSimple extends StatelessWidget {
  const QuizPageSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpeg', // same background
              fit: BoxFit.cover,
            ),
          ),

          // 🔹 BLUR LAYER
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // blur amount
              child: Container(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),

          // 🔹 MAIN UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ NAV BAR (Quiz selected)
                  TopNavBar(selectedTab: 3),
                  const SizedBox(height: 20),

                  // Page title with white background
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "ප්‍රශ්න",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ TWO BUTTON CARDS
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 4 / 3,
                      children: [
                        _QuizCard(
                          title: "ගණිත ප්‍රශ්න",
                          icon: Icons.calculate,
                          onTap: () {
                            Navigator.pushNamed(context, '/general_quiz');
                          },
                        ),
                        _QuizCard(
                          title: "සිංහල ප්‍රශ්න",
                          icon: Icons.menu_book,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("සිංහල ප්‍රශ්න ඉක්මනින් එයි"),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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

class _QuizCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuizCard({
    required this.title,
    required this.icon,
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
            colors: [Color.fromARGB(255, 230, 229, 232), Color.fromARGB(255, 219, 216, 219)],
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
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color.fromARGB(255, 21, 21, 21),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
