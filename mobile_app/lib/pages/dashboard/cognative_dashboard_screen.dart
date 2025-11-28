import 'package:flutter/material.dart';

class CognativeDashboardScreen extends StatelessWidget {
  const CognativeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F2FD), Color.fromARGB(255, 55, 35, 58), Color(0xFFFFF8E1)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP BAR
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: cs.primary.withOpacity(0.1),
                      child: const Icon(Icons.person, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Hi, Chamindu 👋",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "Ready to learn something new today? cognative",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // TODAY'S SUMMARY CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7E57C2), Color(0xFFAB47BC)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Today’s Learning",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "3 lessons • 2 quizzes • 1 game",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Keep your 5-day streak! 🔥",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        "assets/login_page.png", // or any small mascot image
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // QUICK STATS
                Row(
                  children: [
                    _SmallStatCard(
                      icon: Icons.stars_rounded,
                      label: "Stars",
                      value: "120",
                      color: const Color(0xFFFFCA28),
                    ),
                    const SizedBox(width: 12),
                    _SmallStatCard(
                      icon: Icons.emoji_events,
                      label: "Badges",
                      value: "5",
                      color: const Color(0xFF4DB6AC),
                    ),
                    const SizedBox(width: 12),
                    _SmallStatCard(
                      icon: Icons.timelapse,
                      label: "Minutes",
                      value: "32",
                      color: const Color(0xFF64B5F6),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // SUBJECTS TITLE
                const Text(
                  "Your subjects",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // SUBJECT CHIPS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: const [
                      _SubjectChip(label: "Maths", icon: Icons.calculate),
                      _SubjectChip(label: "Sinhala", icon: Icons.menu_book),
                      _SubjectChip(label: "English", icon: Icons.translate),
                      _SubjectChip(label: "Science", icon: Icons.science),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // GRID OF CARDS
                const Expanded(child: _LessonsGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Small top stats
class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SmallStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.18),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Subject chips
class _SubjectChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SubjectChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.deepPurple),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }
}

// Grid of lesson cards
class _LessonsGrid extends StatelessWidget {
  const _LessonsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.only(bottom: 8),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 3 / 2.5,
      children: const [
        _LessonCard(
          title: "Maths – Fractions",
          subtitle: "2/5 lessons done",
          progress: 0.4,
          color: Color(0xFFFFF3E0),
          icon: Icons.pie_chart_outline_outlined,
        ),
        _LessonCard(
          title: "English – Reading",
          subtitle: "Story: The Lost Cat",
          progress: 0.7,
          color: Color(0xFFE3F2FD),
          icon: Icons.menu_book_outlined,
        ),
        _LessonCard(
          title: "Sinhala – Grammar",
          subtitle: "New words",
          progress: 0.25,
          color: Color(0xFFF3E5F5),
          icon: Icons.text_fields,
        ),
        _LessonCard(
          title: "Fun Quiz",
          subtitle: "Mixed subjects",
          progress: 0.0,
          color: Color(0xFFE8F5E9),
          icon: Icons.quiz_outlined,
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress; // 0.0–1.0
  final Color color;
  final IconData icon;

  const _LessonCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        // TODO: navigate to lesson / game
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(icon, size: 20, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.6),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.deepPurpleAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
