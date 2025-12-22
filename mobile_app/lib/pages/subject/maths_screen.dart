import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLessons();
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
      setState(() {
        lessons = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorText = e.toString();
      });
      // ignore: avoid_print
      print('Error fetching lessons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "My Lessons",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
