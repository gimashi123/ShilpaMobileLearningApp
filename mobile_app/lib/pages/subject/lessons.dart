import 'package:flutter/material.dart';

class Lesson {
  final String id;
  final String title;
  final String description;
  final String duration;
  bool completed;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    this.completed = false,
  });
}

class LessonsPage extends StatefulWidget {
  const LessonsPage({Key? key}) : super(key: key);

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  final List<Lesson> _lessons = List.generate(
    8,
    (i) => Lesson(
      id: 'lesson_$i',
      title: 'Lesson ${i + 1}',
      description: 'This is a short description for lesson ${i + 1}.',
      duration: '${10 + i * 5} min',
      completed: i % 3 == 0,
    ),
  );

  String _query = '';

  List<Lesson> get _filteredLessons {
    if (_query.isEmpty) return _lessons;
    final q = _query.toLowerCase();
    return _lessons.where((l) {
      return l.title.toLowerCase().contains(q) ||
          l.description.toLowerCase().contains(q);
    }).toList();
  }

  void _toggleCompleted(Lesson lesson) {
    setState(() {
      lesson.completed = !lesson.completed;
    });
  }

  void _addDummyLesson() {
    final index = _lessons.length + 1;
    setState(() {
      _lessons.insert(
        0,
        Lesson(
          id: 'lesson_new_$index',
          title: 'New Lesson $index',
          description: 'A freshly added dummy lesson.',
          duration: '12 min',
          completed: false,
        ),
      );
    });
  }

  void _showLessonDetails(Lesson lesson) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lesson.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lesson.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer, size: 16),
                const SizedBox(width: 6),
                Text(lesson.duration),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16),
                const SizedBox(width: 6),
                Text(lesson.completed ? 'Completed' : 'Not completed'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _toggleCompleted(lesson);
              Navigator.of(context).pop();
            },
            child: Text(lesson.completed ? 'Mark not completed' : 'Mark completed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search lessons',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _filteredLessons.isEmpty
                ? const Center(child: Text('No lessons found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = _filteredLessons[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: lesson.completed ? Colors.green : Colors.blue,
                              child: Icon(
                                lesson.completed ? Icons.check : Icons.book,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(lesson.title),
                            subtitle: Text(lesson.description),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(lesson.duration, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _toggleCompleted(lesson),
                                  child: Icon(
                                    lesson.completed ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: lesson.completed ? Colors.green : null,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _showLessonDetails(lesson),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDummyLesson,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}