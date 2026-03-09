
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_app/component/top_nav_bar.dart';

class HearingGameDashboard extends StatelessWidget {
  const HearingGameDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 ENHANCED BACKGROUND IMAGE
          // Positioned.fill(
          //   child: Image.asset(
          //     // 'assets/background.jpeg',
          //     fit: BoxFit.cover,
          //   ),
          // ),

          // 🔹 GRADIENT OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.2),
                    const Color(0xFF764BA2).withOpacity(0.15),
                    const Color(0xFFFFF8E1).withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // 🔹 BLUR LAYER
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // 🔹 PATTERN OVERLAY
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                "assets/pattern-bg.jpeg",
                fit: BoxFit.cover,
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
                  TopNavBar(selectedTab: 2),
                  const SizedBox(height: 24),

                  // ✅ ENHANCED PAGE TITLE
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 8),
                  //   child: Row(
                  //     children: [
                  //       Container(
                  //         width: 6,
                  //         height: 40,
                  //         decoration: BoxDecoration(
                  //           gradient: LinearGradient(
                  //             colors: [
                  //               const Color(0xFF6A11CB),
                  //               const Color(0xFF2575FC),
                  //             ],
                  //             begin: Alignment.topCenter,
                  //             end: Alignment.bottomCenter,
                  //           ),
                  //           borderRadius: BorderRadius.circular(3),
                  //         ),
                  //       ),
                  //       const SizedBox(width: 12),
                  //       const Text(
                  //         "ප්‍රශ්න",
                  //         style: TextStyle(
                  //           fontSize: 34,
                  //           fontWeight: FontWeight.w800,
                  //           color: Color(0xFF2D1B69),
                  //           letterSpacing: -0.5,
                  //           shadows: [
                  //             Shadow(
                  //               blurRadius: 2,
                  //               color: Colors.black12,
                  //               offset: Offset(1, 1),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // const SizedBox(height: 4),
                  // Padding(
                  //   padding: const EdgeInsets.only(left: 26),
                  //   child: Text(
                  //     "විවිධ විෂයන්ගේ ප්‍රශ්න උත්තර දී ඔබේ දැනුම පරීක්ෂා කරන්න",
                  //     style: TextStyle(
                  //       fontSize: 15,
                  //       color: Colors.deepPurple.withOpacity(0.7),
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 32),

                  // ✅ ENHANCED TWO BUTTON CARDS
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
                          padding: const EdgeInsets.all(24),
                          crossAxisCount: 2,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 3/2,
                          children: [
                            _QuizCard(
                              title: "ගණිත Games",
                              icon: Icons.calculate,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () {
                                Navigator.pushNamed(context, '/hearing_games');
                              },
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
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuizCard({
    required this.title,
    required this.icon,
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
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black26,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
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