import 'package:flutter/material.dart';

class MathLessonsPage extends StatelessWidget {
  const MathLessonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Dummy lesson list (later replace with backend data)
    final lessons = [
      {
        'title': 'එකතු කිරීම (Addition)',
        'grade': '3',
        'description': 'අංක 0 – 100 අතර එකතු කිරීම.',
        'icon': Icons.add,
      },
      {
        'title': 'අඩු කිරීම (Subtraction)',
        'grade': '3',
        'description': 'දිනපොළේ ගණන් සමඟ අඩු කිරීම.',
        'icon': Icons.remove,
      },
      {
        'title': 'ගුණනය (Multiplication)',
        'grade': '4',
        'description': 'ගුණනය වගු 1 – 10 පුනරාවර්තනය.',
        'icon': Icons.clear,
      },
      {
        'title': 'බෙදාහැරීම (Division)',
        'grade': '4',
        'description': 'සමාන කොටස් වලට බෙදීම.',
        'icon': Icons.percent,
      },
      {
        'title': 'රූප හා ආකාර (Shapes)',
        'grade': '5',
        'description': 'බහු කොණ, වෘත්ත, චතුරස්‍ර හඳුනාගන්න.',
        'icon': Icons.category,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF5A2DCC),
        foregroundColor: Colors.white,
        title: const Text(
          'ගණිත පාඩම්',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF5A2DCC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'උදව්වෙන් ගණිතය ඉගෙන ගමු ✨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ඔබේ ශ්‍රේණියට හොඳින් ගැළපෙන පාඩම්, වීඩියෝ හා විභාග.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Lessons list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lesson = lessons[index];

                return _MathLessonCard(
                  title: lesson['title'] as String,
                  grade: lesson['grade'] as String,
                  description: lesson['description'] as String,
                  icon: lesson['icon'] as IconData,
                  colorScheme: colorScheme,
                  onOpenLesson: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Open lesson: ${lesson['title']} (connect video/PDF here)',
                        ),
                      ),
                    );
                  },
                  onOpenQuiz: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Open quiz for: ${lesson['title']}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Single lesson card widget
class _MathLessonCard extends StatelessWidget {
  final String title;
  final String grade;
  final String description;
  final IconData icon;
  final ColorScheme colorScheme;
  final VoidCallback onOpenLesson;
  final VoidCallback onOpenQuiz;

  const _MathLessonCard({
    required this.title,
    required this.grade,
    required this.description,
    required this.icon,
    required this.colorScheme,
    required this.onOpenLesson,
    required this.onOpenQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7E57C2), Color(0xFFAB47BC)],
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),

          const SizedBox(width: 12),

          // Text + buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF311B92),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ශ්‍රේණිය: $grade',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: onOpenLesson,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A2DCC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Lesson'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onOpenQuiz,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5A2DCC),
                        side: const BorderSide(color: Color(0xFF5A2DCC)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Quiz'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
