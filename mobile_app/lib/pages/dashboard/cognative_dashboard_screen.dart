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
            colors: [
              Color(0xFFE3F2FD),
              Color.fromARGB(255, 55, 35, 58),
              Color(0xFFFFF8E1),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final isTablet = w >= 600;

              final horizontalPad = isTablet ? 24.0 : 16.0;
              final verticalPad = isTablet ? 18.0 : 12.0;

              final titleSize = isTablet ? 20.0 : 18.0;
              final subTitleSize = isTablet ? 13.0 : 12.0;

              final gridCrossAxisCount = isTablet ? 3 : 2;
              final gridAspectRatio = isTablet ? (3 / 2.2) : (3 / 2.5);

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPad,
                  vertical: verticalPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP BAR
                    Row(
                      children: [
                        CircleAvatar(
                          radius: isTablet ? 28 : 24,
                          backgroundColor: cs.primary.withOpacity(0.1),
                          child: Icon(Icons.person, size: isTablet ? 32 : 28),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hi, Chamindu 👋",
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "Ready to learn something new today? cognitive",
                              style: TextStyle(
                                fontSize: subTitleSize,
                                color: Colors.black54,
                              ),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 18 : 16,
                        vertical: isTablet ? 16 : 14,
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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

                          // If you don't have this image yet, you can keep it commented or replace with your asset.
                          // Image.asset(
                          //   "assets/login_page.png",
                          //   height: 80,
                          //   fit: BoxFit.contain,
                          // ),

                          // Safe placeholder (won't crash if asset not ready):
                          Container(
                            height: 80,
                            width: 80,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // QUICK STATS (responsive)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _SmallStatCard(
                          icon: Icons.stars_rounded,
                          label: "Stars",
                          value: "120",
                          color: Color(0xFFFFCA28),
                        ),
                        _SmallStatCard(
                          icon: Icons.emoji_events,
                          label: "Badges",
                          value: "5",
                          color: Color(0xFF4DB6AC),
                        ),
                        _SmallStatCard(
                          icon: Icons.timelapse,
                          label: "Minutes",
                          value: "32",
                          color: Color(0xFF64B5F6),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // SUBJECTS TITLE
                    const Text(
                      "Your subjects",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // SUBJECT CHIPS (clickable like reference)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _SubjectChip(
                            label: "IQ Game",
                            icon: Icons.calculate,
                            onTap: () {
                              Navigator.pushNamed(context, '/iq_game');
                            },
                          ),
                          _SubjectChip(
                            label: "Activity",
                            icon: Icons.menu_book,
                            onTap: () {
                              Navigator.pushNamed(context, '/activity_draw');
                            },
                          ),
                          _SubjectChip(
                            label: "Find Image",
                            icon: Icons.menu_book,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/activity_findImage',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // GRID OF CARDS (responsive)
                    Expanded(
                      child: _LessonsGrid(
                        crossAxisCount: gridCrossAxisCount,
                        childAspectRatio: gridAspectRatio,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Small top stats (responsive width)
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
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600;
    final cardWidth = isTablet ? (w - 24 * 2 - 12 * 2) / 3 : (w - 16 * 2);

    return SizedBox(
      width: cardWidth < 220 ? 220 : cardWidth, // keeps nice sizing on tablets
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

// Subject chips (clickable)
class _SubjectChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SubjectChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

// Grid of lesson cards (responsive params)
class _LessonsGrid extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;

  const _LessonsGrid({
    required this.crossAxisCount,
    required this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.only(bottom: 8),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: childAspectRatio,
      children: const [
        _LessonCard(
          title: "Maths – Fractions",
          subtitle: "2/5 lessons done",
          progress: 0.4,
          color: Color(0xFFFFF3E0),
          icon: Icons.pie_chart_outline_outlined,
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
                valueColor: const AlwaysStoppedAnimation<Color>(
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
