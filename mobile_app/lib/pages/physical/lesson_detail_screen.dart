import 'package:flutter/material.dart';
import '../../components/input_aware_button.dart';
import '../../models/input_modes.dart';
import '../../services/auth_api.dart';
import '../video_player_page.dart';
import 'games_content.dart';

class LessonDetailScreen extends StatelessWidget {
  final String title;
  final String subject;
  final String grade;
  final String? description;
  final String? videoUrl;
  final Color themeColor;
  final InputMode inputMode;

  const LessonDetailScreen({
    super.key,
    required this.title,
    required this.subject,
    required this.grade,
    this.description,
    this.videoUrl,
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.black87,
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
                    // 1. VIDEO PLAYER
                    InputAwareButton(
                      onTap: () {
                        if (videoUrl != null && videoUrl!.isNotEmpty) {
                          final fullUrl = '${AuthApi.baseUrl}$videoUrl';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerPage(
                                videoUrl: fullUrl,
                                title: title,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No video available for this lesson',
                              ),
                            ),
                          );
                        }
                      },
                      inputMode: inputMode,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
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
                      description != null && description!.isNotEmpty
                          ? description!
                          : "No description available for this lesson.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 4. INTERACTIVE ASSESSMENTS & GAMES
                    const Text(
                      "Practice & Play",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Responsive row of specific action cards
                    Row(
                      children: [
                        // QUIZ BUTTON
                        Expanded(
                          child: _buildActionCard(
                            context: context,
                            title: "Attempt Quiz",
                            subtitle: "Test your $subject knowledge",
                            icon: Icons.quiz_rounded,
                            color: themeColor,
                            onTap: () {
                              // TODO: Navigate to Subject-Specific Quiz Screen here
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Quiz module for $title coming soon!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // GAMES BUTTON
                        Expanded(
                          child: _buildActionCard(
                            context: context,
                            title: "Play Games",
                            subtitle: "Interactive $subject games",
                            icon: Icons.games_rounded,
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    appBar: AppBar(
                                      title: Text("$subject Games"),
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      leading: IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                    body: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: GamesContent(inputMode: inputMode),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

  // Reusable action card builder for Quiz and Games buttons
  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InputAwareButton(
      onTap: onTap,
      inputMode: inputMode,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height:
            140, // Fixed height to maintain visual balance alongside each other
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.2,
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
