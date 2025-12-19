import 'package:flutter/material.dart';
import 'package:mobile_app/session/session.dart';
import '../../models/input_modes.dart';
import '../../components/input_mode_switch.dart';
import '../../components/input_aware_button.dart';

class PhysicalDashboardScreen extends StatefulWidget {
  const PhysicalDashboardScreen({super.key});

  @override
  State<PhysicalDashboardScreen> createState() =>
      _PhysicalDashboardScreenState();
}

class _PhysicalDashboardScreenState extends State<PhysicalDashboardScreen> {
  String userName = "";
  InputMode _inputMode = InputMode.dwellTouch;

  @override
  void initState() {
    super.initState();
    // load name from Session (set at login)
    userName = Session.userName ?? "Student";
  }

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // TOP BAR WITH REAL USER NAME
                // =====================================================
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
                      children: [
                        Text(
                          "Hi, $userName 👋",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          "Ready to learn something new today? physical",
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

                // =====================================================
                // INPUT MODE SWITCH
                // =====================================================
                InputModeSwitch(
                  selectedMode: _inputMode,
                  onChanged: (mode) {
                    setState(() {
                      _inputMode = mode;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // =====================================================
                // TODAY'S SUMMARY CARD
                // =====================================================
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
                        "assets/login_page.png",
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =====================================================
                // SUBJECTS TITLE
                // =====================================================
                const Text(
                  "ඔබගේ විෂයන් ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // =====================================================
                // SUBJECT CHIPS
                // =====================================================
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SubjectChip(
                        label: "ගණිතය",
                        icon: Icons.calculate,
                        inputMode: _inputMode,
                        onTap: () {
                          Navigator.pushNamed(context, '/math_lessons');
                        },
                      ),
                      _SubjectChip(
                        label: "සිංහල",
                        icon: Icons.menu_book,
                        inputMode: _inputMode,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Sinhala lessons coming soon!"),
                            ),
                          );
                        },
                      ),
                      _SubjectChip(
                        label: "ප්‍රශ්න",
                        icon: Icons.quiz,
                        inputMode: _inputMode,
                        onTap: () {
                          Navigator.pushNamed(context, '/quiz');
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // =====================================================
                // GRID OF LESSON CARDS
                // =====================================================
                Expanded(child: _LessonsGrid(inputMode: _inputMode)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//=====================================================
// Subject chip widget
//=====================================================
class _SubjectChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final InputMode inputMode;

  const _SubjectChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.inputMode,
  });

  @override
  Widget build(BuildContext context) {
    return InputAwareButton(
      onTap: onTap,
      inputMode: inputMode,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.deepPurple.shade100),
        ),
        child: Row(
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

//=====================================================
// Lessons Grid
//=====================================================
class _LessonsGrid extends StatelessWidget {
  final InputMode inputMode;
  const _LessonsGrid({required this.inputMode});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.only(bottom: 8),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 3 / 2.5,
      children: [
        InputAwareButton(
          inputMode: inputMode,
          onTap: () {
            Navigator.pushNamed(context, '/math_lessons');
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 238, 235, 235),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "ගණිතය",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),

        InputAwareButton(
          inputMode: inputMode,
          onTap: () {
            Navigator.pushNamed(context, '/quiz');
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 244, 243, 241),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "සිංහල",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),

        InputAwareButton(
          inputMode: inputMode,
          onTap: () {
            Navigator.pushNamed(context, '/quiz');
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "ප්‍රශ්න",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
