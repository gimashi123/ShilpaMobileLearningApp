import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_app/session/session.dart';

class VisualDashboardScreen extends StatefulWidget {
  const VisualDashboardScreen({super.key});

  @override
  State<VisualDashboardScreen> createState() => _VisualDashboardScreenState();
}

class _VisualDashboardScreenState extends State<VisualDashboardScreen> {
  String userName = "";
  int selectedTab = 0; // 0 Home, 1 පාඩම්, 2 Games, 3 ප්‍රශ්න, 4 Profile

  // ✅ Double-click confirm
  int? _pendingKey;
  DateTime? _pendingAt;
  final Duration _confirmWindow = const Duration(seconds: 4);

  // ✅ TTS
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    userName = Session.userName ?? "Student";
    _setupTts();
  }

  Future<void> _setupTts() async {
    try {
      await _tts.setLanguage("si-LK");
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
    } catch (_) {
      // if Sinhala voice not available, ignore
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // ✅ Common confirm message
  String _confirmMsg(String name) => "$name පිටුවට යාමට නැවත එය click කරන්න";

  // ✅ Core confirm handler (works for navbar + grid + chips)
  Future<void> _confirmThenGo({
    required int keyId, // unique id for each target
    required String name,
    required VoidCallback go,
  }) async {
    final now = DateTime.now();

    final bool secondTap =
        _pendingKey == keyId &&
        _pendingAt != null &&
        now.difference(_pendingAt!) <= _confirmWindow;

    if (secondTap) {
      setState(() {
        _pendingKey = null;
        _pendingAt = null;
      });
      await _tts.stop();
      go();
      return;
    }

    // first tap -> speak + set pending
    setState(() {
      _pendingKey = keyId;
      _pendingAt = now;
    });

    final msg = _confirmMsg(name);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }

    try {
      await _tts.stop();
      await _tts.speak(msg);
    } catch (_) {}
  }

  // ✅ Navbar tap handler
  Future<void> _navTap(int tabIndex) async {
    if (tabIndex == selectedTab) return;

    // unique keys for navbar: 100..104
    final keyId = 100 + tabIndex;

    String name;
    String route;

    switch (tabIndex) {
      case 0:
        name = "Home";
        route = "/home_visual";
        break;
      case 1:
        name = "පාඩම්";
        route = "/lessons";
        break;
      case 2:
        name = "Games";
        route = "/games";
        break;
      case 3:
        name = "ප්‍රශ්න";
        route = "/quizdashboard";
        break;
      case 4:
        name = "Profile";
        route = "/profile";
        break;
      default:
        name = "පිටුව";
        route = "/home_visual";
    }

    await _confirmThenGo(
      keyId: keyId,
      name: name,
      go: () => Navigator.pushReplacementNamed(context, route),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // TOP NAV BAR (double-click + voice)
                // =====================================================
                Row(
                  children: [
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCDB6FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                        child: Row(
                          children: [
                            _TabBtn("Home", selectedTab == 0, () => _navTap(0)),
                            _TabBtn(
                              "පාඩම්",
                              selectedTab == 1,
                              () => _navTap(1),
                            ),
                            _TabBtn(
                              "Games",
                              selectedTab == 2,
                              () => _navTap(2),
                            ),
                            _TabBtn(
                              "ප්‍රශ්න",
                              selectedTab == 3,
                              () => _navTap(3),
                            ),
                            _TabBtn(
                              "Profile",
                              selectedTab == 4,
                              () => _navTap(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                ),

                const SizedBox(height: 16),

                // =====================================================
                // TODAY'S SUMMARY CARD (UNCHANGED)
                // =====================================================
                // Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 16,
                //     vertical: 14,
                //   ),
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(20),
                //     gradient: const LinearGradient(
                //       colors: [Color(0xFF7E57C2), Color(0xFFAB47BC)],
                //     ),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withOpacity(0.15),
                //         blurRadius: 10,
                //         offset: const Offset(0, 6),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 18),

                const Text(
                  "ඔබගේ විෂයන් ",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // =====================================================
                // SUBJECT CHIPS (now double-click + voice)
                // =====================================================
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // child: Row(
                  //   children: [
                  //     _SubjectChip(
                  //       label: "ගණිතය",
                  //       icon: Icons.calculate,
                  //       onTap: () {
                  //         _confirmThenGo(
                  //           keyId: 200,
                  //           name: "ගණිතය",
                  //           go: () => Navigator.pushReplacementNamed(
                  //             context,
                  //             '/math_lessons',
                  //           ),
                  //         );
                  //       },
                  //     ),
                  //     _SubjectChip(
                  //       label: "සිංහල",
                  //       icon: Icons.menu_book,
                  //       onTap: () {
                  //         _confirmThenGo(
                  //           keyId: 201,
                  //           name: "සිංහල",
                  //           go: () {
                  //             ScaffoldMessenger.of(context).showSnackBar(
                  //               const SnackBar(
                  //                 content: Text("Sinhala lessons coming soon!"),
                  //               ),
                  //             );
                  //           },
                  //         );
                  //       },
                  //     ),
                  //     _SubjectChip(
                  //       label: "ප්‍රශ්න",
                  //       icon: Icons.quiz,
                  //       onTap: () {
                  //         _confirmThenGo(
                  //           keyId: 202,
                  //           name: "ප්‍රශ්න",
                  //           go: () => Navigator.pushReplacementNamed(
                  //             context,
                  //             '/quiz',
                  //           ),
                  //         );
                  //       },
                  //     ),
                  //   ],
                  // ),
                ),

                const SizedBox(height: 16),

                // =====================================================
                // GRID (now double-click + voice)
                // =====================================================
                Expanded(
                  child: _LessonsGrid(
                    onOpen: (title, route, keyId) {
                      _confirmThenGo(
                        keyId: keyId,
                        name: title,
                        go: () =>
                            Navigator.pushReplacementNamed(context, route),
                      );
                    },
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

// =====================================================
// TAB BUTTON
// =====================================================
class _TabBtn extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _TabBtn(this.text, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7B00FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: Colors.black, width: 3) : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SUBJECT CHIP
// =====================================================
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

// =====================================================
// GRID (with callback so parent can do voice+double click)
// =====================================================
class _LessonsGrid extends StatelessWidget {
  final void Function(String title, String route, int keyId) onOpen;

  const _LessonsGrid({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.only(bottom: 8),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2 / 3,
      children: [
        _gridItem(context, "ගණිතය", '/math_lessons', 300),
        _gridItem(context, "සිංහල", '/quiz', 301),
        _gridItem(context, "ප්‍රශ්න", '/quizdashboard', 302),
        _gridItem(context, "GAMES", '/games', 303),
      ],
    );
  }

  Widget _gridItem(
    BuildContext context,
    String title,
    String route,
    int keyId,
  ) {
    return InkWell(
      onTap: () => onOpen(title, route, keyId),
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
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
