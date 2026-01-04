import 'package:flutter/material.dart';
import '../../components/input_aware_button.dart';
import '../../models/input_modes.dart';
import 'games_content.dart';

class LessonDetailScreen extends StatelessWidget {
  final String title;
  final String subject;
  final String grade;
  final Color themeColor;
  final InputMode inputMode;

  const LessonDetailScreen({
    super.key,
    required this.title,
    required this.subject,
    required this.grade,
    required this.inputMode,
    this.themeColor = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with Back Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InputAwareButton(
                    onTap: () => Navigator.pop(context),
                    inputMode: inputMode,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: IgnorePointer(
                        child: IconButton(
                          onPressed: () {}, // Handled by InputAwareButton
                          icon: const Icon(Icons.arrow_back_ios_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            padding: const EdgeInsets.only(
                              left: 8,
                            ), // Visual center usually needs offset for back arrow
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      "Lesson Details",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),

            // Main Content Scrollable Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. VIDEO PLAYER (Placeholder)
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/physical.png',
                          ), // Placeholder image
                          fit: BoxFit.cover,
                          opacity: 0.6,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 40,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. TITLE & META INFO
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _buildMetaTag(
                          Icons.menu_book_rounded,
                          subject,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildMetaTag(
                          Icons.school_rounded,
                          grade,
                          Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _buildMetaTag(
                          Icons.timer_rounded,
                          "15 Mins",
                          Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 3. DESCRIPTION
                    const Text(
                      "About this Lesson",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "In this interactive lesson, we will explore the fundamentals of $title. "
                      "Designed for $grade students, this session covers key concepts "
                      "through engaging visual examples and easy-to-follow explanations.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 4. ACTION BUTTONS (Enroll & Quiz)
                    Row(
                      children: [
                        Expanded(
                          child: InputAwareButton(
                            onTap: () {
                              // Enroll Action
                            },
                            inputMode: inputMode,
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: IgnorePointer(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 4,
                                    shadowColor: themeColor.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    "Enroll Now",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InputAwareButton(
                            onTap: () {
                              // Quiz Action
                            },
                            inputMode: inputMode,
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: IgnorePointer(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: themeColor,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.quiz_rounded,
                                        color: themeColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Attempt Quiz",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 5. RELATED GAMES BUTTON
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade100,
                            Colors.orange.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.games_rounded, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                "Gamified Learning",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Master this topic by playing related educational games!",
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: InputAwareButton(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Scaffold(
                                      appBar: AppBar(
                                        title: const Text("Related Games"),
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        leading: IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                      body: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: GamesContent(
                                          inputMode: inputMode,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              inputMode: inputMode,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: double.infinity,
                                child: IgnorePointer(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Play Related Games",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Padding
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
