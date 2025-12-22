import 'package:flutter/material.dart';
import 'package:mobile_app/pages/video_player_page.dart';
import 'package:mobile_app/services/auth_api.dart';
import 'package:mobile_app/services/lessons_api.dart';
import 'package:mobile_app/session/session.dart';
import 'package:mobile_app/widgets/top_nav_bar.dart';

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
      print('Error fetching lessons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ✅ COMMON NAV BAR (Lessons tab selected)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TopNavBar(selectedTab: 1), // 1 = පාඩම්
            ),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ගණිතය පාඩම්",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // ================= EXISTING BODY (UNCHANGED) =================
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
                            final raw = lesson['videoUrl'] as String? ?? '';

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
                                  title: lesson['title'] ?? 'Lesson video',
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
    );
  }
}
