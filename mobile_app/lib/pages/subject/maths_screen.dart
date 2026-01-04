import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:mobile_app/component/top_nav_bar.dart';
import 'package:mobile_app/pages/video_player_page.dart';
import 'package:mobile_app/services/auth_api.dart';
import 'package:mobile_app/services/lessons_api.dart';
import 'package:mobile_app/session/session.dart';

class StudentLessonsPage extends StatefulWidget {
  const StudentLessonsPage({super.key});

  @override
  State<StudentLessonsPage> createState() => _StudentLessonsPageState();
}

class _StudentLessonsPageState extends State<StudentLessonsPage> {
  List<dynamic> lessons = [];
  bool loading = true;
  String? errorText;

  // 🔊 TTS
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _ttsBusy = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadLessons();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("si-LK");
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        if (!mounted) return;
        setState(() => _ttsBusy = true);
      });
      _tts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() => _ttsBusy = false);
      });
      _tts.setErrorHandler((_) {
        if (!mounted) return;
        setState(() => _ttsBusy = false);
      });

      _ttsReady = true;
    } catch (_) {
      _ttsReady = false;
    }
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _stopSpeak() async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  String _titleOf(dynamic lesson) => (lesson['title'] ?? 'No title').toString();
  String _subjectOf(dynamic lesson) => (lesson['subject'] ?? '').toString();
  String _gradeOf(dynamic lesson) => (lesson['grade'] ?? '').toString();

  String _descForTts(dynamic lesson) {
    final title = _titleOf(lesson);
    final subject = _subjectOf(lesson);
    final grade = _gradeOf(lesson);

    final parts = <String>[];
    parts.add("පාඩම: $title");
    if (subject.trim().isNotEmpty) parts.add("විෂය: $subject");
    if (grade.trim().isNotEmpty) parts.add("ශ්‍රේණිය: $grade");
    parts.add("වීඩියෝ බලන්න දකුණට ස්වයිප් කරන්න.");
    parts.add("විස්තර නැවත අහන්න දෙපාරක් ටැප් කරන්න.");
    return parts.join(". ");
  }

  String _buildLessonsListForTts(List<dynamic> list) {
    if (list.isEmpty) {
      return "ඔබට ඉගෙන ගැනීමට හැකි පාඩම් නැහැ.";
    }

    // read max 10 titles (avoid too long)
    const maxRead = 10;
    final toRead = list.take(maxRead).toList();
    final remaining = list.length - toRead.length;

    final buffer = StringBuffer();
    buffer.writeln("ඔබට ඉගෙන ගැනීමට හැකි පාඩම් මෙන්න.");

    for (int i = 0; i < toRead.length; i++) {
      final t = _titleOf(toRead[i]);
      buffer.writeln("${i + 1}. $t.");
    }

    if (remaining > 0) {
      buffer.writeln("තවත් පාඩම් $remainingක් තිබෙනවා.");
    }

    buffer.writeln("පාඩමක විස්තර අහන්න එක පාර ටැප් කරන්න.");
    buffer.writeln("විස්තර නැවත අහන්න දෙපාරක් ටැප් කරන්න.");
    buffer.writeln("වීඩියෝ බලන්න දකුණට ස්වයිප් කරන්න.");

    return buffer.toString();
  }

  Future<void> _loadLessons() async {
    try {
      if (Session.token == null) {
        setState(() {
          loading = false;
          errorText = 'Session.token is null – not logged in?';
        });
        return;
      }

      final data = await LessonApi.fetchMyLessons(Session.token!);

      if (!mounted) return;
      setState(() {
        lessons = data;
        loading = false;
        errorText = null;
      });

      // 🎧 voice: title + list down lessons
      await _speak(_buildLessonsListForTts(lessons));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorText = e.toString();
      });
      await _speak("පාඩම් ලබාගැනීම අසාර්ථකයි.");
      // ignore: avoid_print
      print('Error fetching lessons: $e');
    }
  }

  void _openLessonVideo(dynamic lesson) {
    final raw = (lesson['videoUrl'] as String?) ?? '';
    if (raw.isEmpty) return;

    const apiBase = AuthApi.baseUrl;
    final fullUrl = '$apiBase$raw';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VideoPlayerPage(videoUrl: fullUrl, title: _titleOf(lesson)),
      ),
    );
  }

  @override
  void dispose() {
    _stopSpeak();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTab = w >= 600;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // ✅ TOP NAV BAR (Lessons tab selected)
              TopNavBar(selectedTab: 1),
              const SizedBox(height: 12),

              // ✅ Page title row (replacement for AppBar)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ඔබට ඉගෙන ගැනීමට හැකි පාඩම්",
                  style: TextStyle(
                    fontSize: isTab ? 26 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ✅ Content
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : errorText != null
                        ? Center(child: Text(errorText!))
                        : lessons.isEmpty
                            ? const Center(child: Text('No lessons available'))
                            : ListView.builder(
                                itemCount: lessons.length,
                                itemBuilder: (ctx, i) {
                                  final lesson = lessons[i];
                                  return ListTile(
                                    title: Text(lesson['title'] ?? 'No title'),
                                    subtitle: Text(
                                      "${lesson['subject'] ?? ''} | Grade ${lesson['grade']}",
                                    ),
                                    onTap: () {
                                      final raw =
                                          lesson['videoUrl'] as String? ?? '';

                                      print('RAW videoUrl from API: $raw');

                                      if (raw.isEmpty) {
                                        print('No videoUrl in lesson');
                                        return;
                                      }

                                      const apiBase = AuthApi.baseUrl;
                                      final fullUrl = '$apiBase$raw';

                                      print('FULL video URL: $fullUrl');

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => VideoPlayerPage(
                                            videoUrl: fullUrl,
                                            title:
                                                lesson['title'] ?? 'Lesson video',
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatefulWidget {
  final dynamic lesson;
  final bool isTab;

  final VoidCallback onFocusSpeak;
  final VoidCallback onTapSpeak;
  final VoidCallback onDoubleTapSpeak;
  final VoidCallback onSwipeRightPlay;

  const _LessonCard({
    required this.lesson,
    required this.isTab,
    required this.onFocusSpeak,
    required this.onTapSpeak,
    required this.onDoubleTapSpeak,
    required this.onSwipeRightPlay,
  });

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> {
  final FocusNode _focusNode = FocusNode();
  Offset? _start;
  Offset? _last;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onFocusSpeak();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _titleOf() => (widget.lesson['title'] ?? 'No title').toString();
  String _subjectOf() => (widget.lesson['subject'] ?? '').toString();
  String _gradeOf() => (widget.lesson['grade'] ?? '').toString();

  void _trySwipeRight() {
    final s = _start;
    final e = _last;
    _start = null;
    _last = null;
    if (s == null || e == null) return;

    final dx = e.dx - s.dx;
    final dy = e.dy - s.dy;

    // Must be mostly horizontal and to the right
    final minDx = widget.isTab ? 90.0 : 65.0;

    if (dx > minDx && dx.abs() > dy.abs()) {
      widget.onSwipeRightPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTab = widget.isTab;

    return Focus(
      focusNode: _focusNode,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        // ✅ Single tap = speak description
        onTap: () {
          _focusNode.requestFocus();
          widget.onTapSpeak();
        },

        // ✅ Double tap = replay description
        onDoubleTap: () {
          _focusNode.requestFocus();
          widget.onDoubleTapSpeak();
        },

        // 👉 Swipe right = play lesson
        onPanStart: (d) {
          _start = d.globalPosition;
          _last = d.globalPosition;
        },
        onPanUpdate: (d) {
          _last = d.globalPosition;
        },
        onPanEnd: (d) {
          _trySwipeRight();
        },

        child: Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTab ? 16 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isTab ? 56 : 48,
                  height: isTab ? 56 : 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_fill,
                    size: isTab ? 38 : 32,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: isTab ? 16 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleOf(),
                        style: TextStyle(
                          fontSize: isTab ? 18 : 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${_subjectOf()} • Grade ${_gradeOf()}",
                        style: TextStyle(
                          fontSize: isTab ? 14 : 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "",
                        style: TextStyle(
                          fontSize: isTab ? 13 : 12,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
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
