import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_app/pages/subject/hearing_math.dart';
import 'package:mobile_app/session/session.dart';
import 'package:mobile_app/component/top_nav_bar.dart';

// IMPORTANT: Op and QuizPagehearing are in quiz.dart
import 'package:mobile_app/pages/quiz.dart';

class HearingDashboardScreen extends StatefulWidget {
  const HearingDashboardScreen({super.key});

  @override
  State<HearingDashboardScreen> createState() => _HearingDashboardScreenState();
}

class _HearingDashboardScreenState extends State<HearingDashboardScreen> {
  String userName = "";

  @override
  void initState() {
    super.initState();
    userName = Session.userName ?? "Student";
  }

  Future<void> _openQuizPicker() async {
    final Op? selected = await showDialog<Op>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Choose Quiz Type"),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuizTypeBtn(label: "+", onTap: () => Navigator.pop(ctx, Op.add)),
              _QuizTypeBtn(label: "-", onTap: () => Navigator.pop(ctx, Op.sub)),
              _QuizTypeBtn(label: "×", onTap: () => Navigator.pop(ctx, Op.mul)),
              _QuizTypeBtn(label: "÷", onTap: () => Navigator.pop(ctx, Op.div)),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    Navigator.pushNamed(
      context,
      '/quizhearing',
      arguments: selected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // ✅ Background image
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Blur layer (adjust sigma for more/less blur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),

          // ✅ Your UI on top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopNavBar(selectedTab: 0),
                  const SizedBox(height: 16),

                  // (Optional) Top bar (kept commented like your code)
                  // Row(
                  //   children: [
                  //     CircleAvatar(
                  //       radius: 24,
                  //       backgroundColor: cs.primary.withOpacity(0.1),
                  //       child: const Icon(Icons.person, size: 28),
                  //     ),
                  //     const SizedBox(width: 12),
                  //     Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           "Hi, $userName 👋",
                  //           style: const TextStyle(
                  //             fontSize: 18,
                  //             fontWeight: FontWeight.w700,
                  //           ),
                  //         ),
                  //         const Text(
                  //           "Ready to learn something new today? hearing",
                  //           style: TextStyle(fontSize: 12, color: Colors.black54),
                  //         ),
                  //       ],
                  //     ),
                  //     const Spacer(),
                  //     IconButton(
                  //       onPressed: () {},
                  //       icon: const Icon(Icons.notifications_outlined),
                  //     ),
                  //   ],
                  // ),

                  const SizedBox(height: 16),

                  // TODAY’S SUMMARY CARD
                  

                  const SizedBox(height: 18),

                  Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.9), // white background
    borderRadius: BorderRadius.circular(10),
  ),
  child: const Text(
    "ඔබගේ විෂයන්",
    style: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
  ),
),
const SizedBox(height: 8),

                  // SUBJECT CHIPS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    // child: Row(
                    //   children: [
                    //     _SubjectChip(
                    //       label: "ගණිතය",
                    //       icon: Icons.calculate,
                    //       onTap: () {
                    //         Navigator.pushNamed(context, '/math_lessons');
                    //       },
                    //     ),
                    //     _SubjectChip(
                    //       label: "සිංහල",
                    //       icon: Icons.menu_book,
                    //       onTap: () {
                    //         ScaffoldMessenger.of(context).showSnackBar(
                    //           const SnackBar(
                    //             content: Text("Sinhala lessons coming soon!"),
                    //           ),
                    //         );
                    //       },
                    //     ),
                    //     _SubjectChip(
                    //       label: "ප්‍රශ්න",
                    //       icon: Icons.quiz,
                    //       onTap: () => Navigator.pushNamed(context, '/quiz'),
                    //     ),
                    //     _SubjectChip(
                    //       label: "GAMES",
                    //       icon: Icons.quiz,
                    //       onTap: _openQuizPicker,
                    //     ),
                    //   ],
                    // ),
                  ),

                  const SizedBox(height: 16),

                  // GRID
                  Expanded(
                    child: _LessonsGrid(
                      onOpenQuizPicker: _openQuizPicker,
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

// Subject chip
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
          color: Colors.white.withOpacity(0.85),
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

// Quiz type button for dialog
class _QuizTypeBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuizTypeBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Lessons Grid
class _LessonsGrid extends StatelessWidget {
  final Future<void> Function() onOpenQuizPicker;

  const _LessonsGrid({required this.onOpenQuizPicker});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.only(bottom: 8),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5 / 3,
      
      children: [
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/math_lessons');
          },
          child: const _GridCard(
            bg: Color.fromARGB(255, 238, 235, 235),
            text: "ගණිතය",
          ),
        ),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sinhala lessons coming soon!")),
            );
          },
          child: const _GridCard(
            bg: Color.fromARGB(255, 244, 243, 241),
            text: "සිංහල",
          ),
        ),
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/quiz'),
          child: const _GridCard(
            bg: Color(0xFFFFF3E0),
            text: "ප්‍රශ්න",
          ),
        ),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Games coming soon!")),
            );
          },
          child: const _GridCard(
            bg: Color.fromARGB(255, 244, 243, 241),
            text: "GAMES",
          ),
        ),
      ],
    );
  }
}

class _GridCard extends StatelessWidget {
  final Color bg;
  final String text;

  const _GridCard({required this.bg, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
