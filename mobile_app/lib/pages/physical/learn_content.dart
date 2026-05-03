import 'package:flutter/material.dart';
import 'package:mobile_app/pages/physical/lesson_detail_screen.dart';
import '../../components/input_aware_button.dart';
import '../../models/input_modes.dart';
import '../../components/responsive_layout.dart';
import '../../services/lessons_api.dart';
import '../../services/voice_focus_service.dart';
import '../../session/session.dart';

/// Learn content (Learn tab)
class LearnContent extends StatefulWidget {
  final InputMode inputMode;
  final String? initialSubject;

  const LearnContent({super.key, required this.inputMode, this.initialSubject});

  @override
  State<LearnContent> createState() => _LearnContentState();
}

class _LearnContentState extends State<LearnContent> {
  late String _selectedSubject;

  List<dynamic> _backendLessons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject ?? 'Sinhala';
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    try {
      if (Session.token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session token is missing. Please log in.';
        });
        return;
      }
      final data = await LessonApi.fetchMyLessons(Session.token!);
      setState(() {
        _backendLessons = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load lessons: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Layout Logic
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);
    final int crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);

    // Filter Logic
    final filteredLessons = _backendLessons.where((lesson) {
      return (lesson['subject']?.toString() ?? '').toLowerCase() ==
          _selectedSubject.toLowerCase();
    }).toList();

    return Column(
      children: [
        // ... (Subject Toggle Section remains same) ...
        // ===== SUBJECT TOGGLE SECTION (Redesigned) =====
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFD1C4E9).withOpacity(0.3), // Soft lavender
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // SINHALA TAB
              Expanded(
                child: InputAwareButton(
                  onTap: () {
                    VoiceFocusService().clear();
                    setState(() => _selectedSubject = 'Sinhala');
                  },
                  inputMode: widget.inputMode,
                  voiceLabel: "සිංහල",
                  showVoiceIndex: true,
                  borderRadius: BorderRadius.circular(25),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: _selectedSubject == 'Sinhala'
                          ? const Color(0xFF26A69A) // Green/Teal
                          : Colors.transparent,
                      boxShadow: _selectedSubject == 'Sinhala'
                          ? [
                              BoxShadow(
                                color: const Color(0xFF26A69A).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "සිංහල", // Sinhala in Sinhala
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 0.5,
                        shadows: _selectedSubject == 'Sinhala'
                            ? [
                                const Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // MATHS TAB
              Expanded(
                child: InputAwareButton(
                  onTap: () {
                    VoiceFocusService().clear();
                    setState(() => _selectedSubject = 'Maths');
                  },
                  inputMode: widget.inputMode,
                  voiceLabel: "ගණිතය",
                  showVoiceIndex: true,
                  borderRadius: BorderRadius.circular(25),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: _selectedSubject == 'Maths'
                          ? const Color(0xFF7E57C2) // Purple
                          : Colors.transparent,
                      boxShadow: _selectedSubject == 'Maths'
                          ? [
                              BoxShadow(
                                color: const Color(0xFF7E57C2).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "ගණිතය", // Maths in Sinhala
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 0.5,
                        shadows: _selectedSubject == 'Maths'
                            ? [
                                const Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ===== CONTENT GRID =====
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                )
              : filteredLessons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 80,
                        color: const Color(0xFF4527A0).withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No lessons found for\n$_selectedSubject",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF4527A0),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: filteredLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = filteredLessons[index];
                    return _LearnCard(
                      index: index,
                      title: lesson['title']?.toString() ?? 'No Title',
                      grade: 'Grade ${lesson['grade']?.toString() ?? '-'}',
                      subject: lesson['subject']?.toString() ?? '',
                      inputMode: widget.inputMode,
                      onTap: () {
                        final themeColor = lesson['subject'] == 'Maths'
                            ? const Color(0xFF7E57C2)
                            : const Color(0xFF26A69A);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LessonDetailScreen(
                              title: lesson['title']?.toString() ?? 'No Title',
                              subject: lesson['subject']?.toString() ?? '',
                              grade:
                                  'Grade ${lesson['grade']?.toString() ?? '-'}',
                              description: lesson['description']?.toString(),
                              videoUrl: lesson['videoUrl']?.toString(),
                              lessonId: lesson['_id']?.toString(),
                              inputMode: widget.inputMode,
                              themeColor: themeColor,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ================= LEARN CARD (VIBRANT REDESIGN) =================

class _LearnCard extends StatelessWidget {
  final int index;
  final String title;
  final String grade;
  final String subject;
  final VoidCallback onTap;
  final InputMode inputMode;

  const _LearnCard({
    required this.index,
    required this.title,
    required this.grade,
    required this.subject,
    required this.onTap,
    required this.inputMode,
  });

  @override
  Widget build(BuildContext context) {
    // Subject-based base colors
    final baseColor = subject == 'Maths'
        ? const Color(0xFF7E57C2)
        : const Color(0xFF26A69A);

    // Slight variations for grid visual interest
    final cardColor = Color.lerp(baseColor, Colors.white, (index % 3) * 0.05)!;

    return InputAwareButton(
      borderRadius: BorderRadius.circular(25),
      onTap: onTap,
      inputMode: inputMode,
      voiceLabel: title,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                subject == 'Maths'
                    ? Icons.calculate_outlined
                    : Icons.menu_book_outlined,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Grade Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                grade,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
