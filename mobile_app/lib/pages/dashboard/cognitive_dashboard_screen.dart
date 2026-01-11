import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_app/session/session.dart';
import 'package:flutter/services.dart'; // ✅ MethodChannel + Haptic

class CognitiveDashboardScreen extends StatefulWidget {
  const CognitiveDashboardScreen({super.key});

  @override
  State<CognitiveDashboardScreen> createState() => _CognitiveDashboardScreenState();
}

class _CognitiveDashboardScreenState extends State<CognitiveDashboardScreen> {
  String userName = "";
  int selectedTab = 0; // 0 Home, 1 පාඩම්, 2 Games, 3 ප්‍රශ්න, 4 Profile

  // ✅ Double-click confirm
  int? _pendingKey;
  DateTime? _pendingAt;
  final Duration _confirmWindow = const Duration(seconds: 4);

  // ✅ TTS
  final FlutterTts _tts = FlutterTts();

  // ✅ Native vibration channel (Android)
  static const MethodChannel _vibChannel = MethodChannel(
    'app.vibration/native',
  );

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
      // Sinhala voice not available -> ignore
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // ✅ REAL vibration (Native Android) + fallback haptic
  Future<void> _vibrate([int ms = 60]) async {
    try {
      // Try native Android vibration first (works even if haptic weird)
      await _vibChannel.invokeMethod('vibrate', {"ms": ms});
    } catch (_) {
      // Fallback to haptic (may depend on device settings)
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  // ✅ Common confirm message
  String _confirmMsg(String name) => "$name පිටුවට යාමට නැවත එය click කරන්න";

  // ✅ Core confirm handler (navbar + grid + chips)
  Future<void> _confirmThenGo({
    required int keyId,
    required String name,
    required VoidCallback go,
  }) async {
    // ✅ vibrate on EVERY tap
    await _vibrate(60);

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
        SnackBar(
          content: Text(
            msg,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.deepPurple.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ),
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

    final keyId = 100 + tabIndex;

    String name;
    String route;

    switch (tabIndex) {
      case 0:
        name = "Home";
        route = "/home_cognitive";
        break;
      case 1:
        name = "IQ බලමු";
        route = "/iq_game";
        break;
      case 2:
        name = "රූප හොයමු";
        route = "/activity_findImage";
        break;
      case 3:
        name = "ඉරි අඳිමු";
        route = "/activity_draw";
        break;
      case 4:
        name = "ගණන් කරමු";
        route = "/activity_countNumbers";
        break;
      default:
        name = "Profile";
        route = "/profile";
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF667EEA).withOpacity(0.15),
              const Color(0xFF764BA2).withOpacity(0.12),
              const Color(0xFFFFF8E1).withOpacity(0.95),
            ],
          ),
          image: const DecorationImage(
            image: AssetImage(
              "assets/login_page.png",
            ), // Add a subtle pattern if available
            fit: BoxFit.cover,
            opacity: 0.08,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // WELCOME SECTION
                // =====================================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6A11CB).withOpacity(0.9),
                        const Color(0xFF2575FC).withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.7),
                            ],
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF6A11CB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "සාදරයෙන් පිළිගනිමු",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black12,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =====================================================
                // TOP NAV BAR - ENHANCED
                // =====================================================
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFCDB6FF),
                        const Color(0xFFB19CD9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      _TabBtn("Home", selectedTab == 0, () => _navTap(0)),
                      _TabBtn("IQ බලමු", selectedTab == 1, () => _navTap(1)),
                      _TabBtn("රූප හොයමු", selectedTab == 2, () => _navTap(2)),
                      _TabBtn("ඉරි අඳිමු", selectedTab == 3, () => _navTap(3)),
                      _TabBtn("ගණන් කරමු", selectedTab == 4, () => _navTap(4)),
                      _TabBtn("Profile", selectedTab == 5, () => _navTap(5)),
                    ],
                  ),
                ),

                // const SizedBox(height: 28),

                // =====================================================
                // SUBJECTS TITLE
                // =====================================================
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
                //         "ඔබගේ විෂයන්",
                //         style: TextStyle(
                //           fontSize: 32,
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
                //     "ඔබගේ ඉගෙනීම ආරම්භ කරන්න",
                //     style: TextStyle(
                //       fontSize: 15,
                //       color: Colors.deepPurple.withOpacity(0.7),
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ),

                // const SizedBox(height: 20),

                // // =====================================================
                // // SUBJECT CHIPS - ENHANCED
                // // =====================================================
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: Row(
                //     children: [
                //       _SubjectChip(
                //         label: "ගණිතය",
                //         icon: Icons.calculate_rounded,
                //         color: const Color(0xFF4A6FA5),
                //         onTap: () {
                //           _confirmThenGo(
                //             keyId: 200,
                //             name: "ගණිතය",
                //             go: () => Navigator.pushReplacementNamed(
                //               context,
                //               '/math_lessons',
                //             ),
                //           );
                //         },
                //       ),
                //       _SubjectChip(
                //         label: "සිංහල",
                //         icon: Icons.menu_book_rounded,
                //         color: const Color(0xFF2E7D32),
                //         onTap: () {
                //           _confirmThenGo(
                //             keyId: 201,
                //             name: "සිංහල",
                //             go: () {
                //               ScaffoldMessenger.of(context).showSnackBar(
                //                 SnackBar(
                //                   content: const Text(
                //                     "Sinhala lessons coming soon!",
                //                   ),
                //                   backgroundColor: Colors.green.withOpacity(
                //                     0.9,
                //                   ),
                //                   shape: RoundedRectangleBorder(
                //                     borderRadius: BorderRadius.circular(12),
                //                   ),
                //                 ),
                //               );
                //             },
                //           );
                //         },
                //       ),
                //       _SubjectChip(
                //         label: "ප්‍රශ්න",
                //         icon: Icons.quiz_rounded,
                //         color: const Color(0xFFD32F2F),
                //         onTap: () {
                //           _confirmThenGo(
                //             keyId: 202,
                //             name: "ප්‍රශ්න",
                //             go: () => Navigator.pushReplacementNamed(
                //               context,
                //               '/quiz',
                //             ),
                //           );
                //         },
                //       ),
                //       _SubjectChip(
                //         label: "ගැටළු",
                //         icon: Icons.lightbulb_rounded,
                //         color: const Color(0xFFF57C00),
                //         onTap: () {
                //           _confirmThenGo(
                //             keyId: 203,
                //             name: "ගැටළු",
                //             go: () {
                //               // Add your logic here
                //             },
                //           );
                //         },
                //       ),
                //     ],
                //   ),
                // ),

                const SizedBox(height: 32),

                // =====================================================
                // MAIN GRID - ENHANCED
                // =====================================================
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
// TAB BUTTON - ENHANCED
// =====================================================
class _TabBtn extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _TabBtn(this.text, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B00FF).withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF9D50BB),
                          const Color(0xFF6E48AA),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: selected
                    ? Border.all(color: Colors.white.withOpacity(0.8), width: 2)
                    : null,
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF2D1B69),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SUBJECT CHIP - ENHANCED
// =====================================================
class _SubjectChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SubjectChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.3,
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
// GRID - ENHANCED
// =====================================================
class _LessonsGrid extends StatelessWidget {
  final void Function(String title, String route, int keyId) onOpen;

  const _LessonsGrid({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(4),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2 / 3,
      children: [
        _gridItem(
          context,
          "IQ බලමු",
          '🧠',
          '/iq_game',
          300,
          LinearGradient(
            colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _gridItem(
          context,
          "රූප හොයමු",
          '🖼️',
          '/activity_findImage',
          301,
          LinearGradient(
            colors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _gridItem(
          context,
          "ඉරි අඳිමු",
          '✏️',
          '/activity_draw',
          302,
          LinearGradient(
            colors: [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _gridItem(
          context,
          "ගණන් කරමු",
          '🔢',
          '/activity_countNumbers',
          303,
          LinearGradient(
            colors: [const Color(0xFF834D9B), const Color(0xFFD04ED6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
         _gridItem(
          context,
          "රූපය අඳුරගමු",
          '🔢',
          '/activity_matchSound',
          303,
          LinearGradient(
            colors: [const Color(0xFF834D9B), const Color(0xFFD04ED6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ), _gridItem(
          context,
          "රටාව හොයමු",
          '✏️',
          '/activity_matchPattern',
          302,
          LinearGradient(
            colors: [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
         _gridItem(
          context,
          "වර්ගය තෝරමු",
          '✏️',
          '/activity_matchCategory',
          302,
          LinearGradient(
            colors: [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  Widget _gridItem(
    BuildContext context,
    String title,
    String emoji,
    String route,
    int keyId,
    Gradient gradient,
  ) {
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
          onTap: () => onOpen(title, route, keyId),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
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