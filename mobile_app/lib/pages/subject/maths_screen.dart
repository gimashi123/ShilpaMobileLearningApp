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

  String _titleOf(dynamic lesson) => (lesson['title'] ?? 'No title').toString();
  String _subjectOf(dynamic lesson) => (lesson['subject'] ?? '').toString();
  String _gradeOf(dynamic lesson) => (lesson['grade'] ?? '').toString();
  String _descriptionOf(dynamic lesson) => (lesson['description'] ?? 'No description available').toString();

  // Get a random color for card based on subject
  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'maths':
      case 'ගණිතය':
        return Colors.blue;
      case 'science':
      case 'විද්‍යාව':
        return Colors.green;
      case 'sinhala':
      case 'සිංහල':
        return Colors.orange;
      case 'english':
      case 'ඉංග්‍රීසි':
        return Colors.purple;
      case 'history':
      case 'ඉතිහාසය':
        return Colors.brown;
      case 'buddhism':
      case 'බුද්ධ ධර්මය':
        return Colors.amber;
      default:
        return Colors.teal;
    }
  }

  // Get icon for subject
  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'maths':
      case 'ගණිතය':
        return Icons.calculate;
      case 'science':
      case 'විද්‍යාව':
        return Icons.science;
      case 'sinhala':
      case 'සිංහල':
        return Icons.translate;
      case 'english':
      case 'ඉංග්‍රීසි':
        return Icons.language;
      case 'history':
      case 'ඉතිහාසය':
        return Icons.history;
      case 'buddhism':
      case 'බුද්ධ ධර්මය':
        return Icons.temple_buddhist;
      default:
        return Icons.menu_book;
    }
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorText = e.toString();
      });

      print('Error fetching lessons: $e');
    }
  }

  void _openLessonVideo(dynamic lesson) {
    final raw = (lesson['videoUrl'] as String?) ?? '';
    if (raw.isEmpty) return;

    final apiBase = AuthApi.baseUrl;
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
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTab = w >= 600;
    
    // Calculate grid columns based on screen width
    int crossAxisCount = 1;
    if (isTab) {
      crossAxisCount = w >= 1200 ? 4 : 3;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              TopNavBar(selectedTab: 1),
              const SizedBox(height: 12),

              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF7C4DFF),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ඔබට ඉගෙන ගැනීමට හැකි පාඩම්",
                          style: TextStyle(
                            fontSize: isTab ? 26 : 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ඔබගේ පාඨමාලා සඳහා පහත පාඩම් තෝරන්න",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats row
              if (!loading && errorText == null && lessons.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.video_library, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              '${lessons.length} පාඩම්',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_stories, size: 16, color: Colors.green),
                            SizedBox(width: 6),
                            Text(
                              'ඉගෙනීම දිගටම කරන්න',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Lessons grid/list
              Expanded(
                child: loading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF7C4DFF),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'පාඩම් පූරණය වේ...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : errorText != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 64,
                                  color: Colors.red.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'දෝෂයක් සිදු විය',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  errorText!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _loadLessons,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('නැවත උත්සහ කරන්න'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C4DFF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : lessons.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.video_library_outlined,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'පාඩම් නොමැත',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ඔබ සඳහා තවම පාඩම් එකතු කර නොමැත',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : crossAxisCount == 1
                                ? ListView.builder(
                                    itemCount: lessons.length,
                                    itemBuilder: (ctx, i) {
                                      final lesson = lessons[i];
                                      final subject = _subjectOf(lesson);
                                      final subjectColor = _getSubjectColor(subject);
                                      final subjectIcon = _getSubjectIcon(subject);
                                      
                                      return _buildLessonCard(
                                        lesson,
                                        subjectColor,
                                        subjectIcon,
                                      );
                                    },
                                  )
                                : GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      childAspectRatio: 0.85,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: lessons.length,
                                    itemBuilder: (ctx, i) {
                                      final lesson = lessons[i];
                                      final subject = _subjectOf(lesson);
                                      final subjectColor = _getSubjectColor(subject);
                                      final subjectIcon = _getSubjectIcon(subject);
                                      
                                      return _buildLessonCard(
                                        lesson,
                                        subjectColor,
                                        subjectIcon,
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

  Widget _buildLessonCard(dynamic lesson, Color subjectColor, IconData subjectIcon) {
    final title = _titleOf(lesson);
    final subject = _subjectOf(lesson);
    final grade = _gradeOf(lesson);
    final description = _descriptionOf(lesson);
    final hasVideo = (lesson['videoUrl'] as String?)?.isNotEmpty ?? false;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: hasVideo ? () => _openLessonVideo(lesson) : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with subject icon and grade
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: subjectColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      subjectIcon,
                      color: subjectColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.isNotEmpty ? subject : 'General',
                          style: TextStyle(
                            fontSize: 14,
                            color: subjectColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Grade $grade',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Video indicator
                  if (hasVideo)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Bottom row with play button if video available
              if (hasVideo)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openLessonVideo(lesson),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('නරඹන්න'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: subjectColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'වීඩියෝව සූදානම් වෙමින් පවතී',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}