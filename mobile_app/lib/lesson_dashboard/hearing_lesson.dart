import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_app/component/top_nav_bar.dart';

class HearingLesson extends StatelessWidget {
  const HearingLesson({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          // 🔹 BLUR LAYER
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
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
                  TopNavBar(selectedTab: 1),

                  const SizedBox(height: 24), // ✅ space below navbar

                  // Title
                  

                  const SizedBox(height: 32), // ✅ THIS moves cards down

                  // ✅ FULL IMAGE CARDS
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 4 / 3,
                      children: [
                        _LessonCard(
                          title: "ගණිත පාඩම්",
                          imageAsset: 'assets/math.jpg',
                          onTap: () {
                            Navigator.pushNamed(context, '/math_lessons');
                          },
                        ),
                        _LessonCard(
                          title: "සිංහල පාඩම්",
                          imageAsset: 'assets/sinhala.jpg',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("සිංහල පාඩම් ඉක්මනින් එයි"),
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

class _LessonCard extends StatelessWidget {
  final String title;
  final String imageAsset;
  final VoidCallback onTap;

  const _LessonCard({
    required this.title,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6), // margin around card
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 🖼 FULL CARD IMAGE
              Positioned.fill(
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                ),
              ),

              // 🔹 OVERLAY
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                ),
              ),

              // 📘 TITLE
              Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
