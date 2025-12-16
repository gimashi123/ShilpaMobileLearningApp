import 'package:flutter/material.dart';

class LearnContent extends StatefulWidget {
  const LearnContent({super.key});

  @override
  State<LearnContent> createState() => _LearnContentState();
}

class _LearnContentState extends State<LearnContent> {
  // Filter States
  String _selectedSubject = 'Sinhala'; // Default
  String _selectedGrade = 'Grade 3'; // Default

  final List<String> _subjects = ['Sinhala', 'Maths'];
  final List<String> _grades = ['Grade 3', 'Grade 4', 'Grade 5'];

  // Mock Data
  final List<Map<String, dynamic>> _allLessons = [
    {
      'title': 'Sinhala Letters',
      'subject': 'Sinhala',
      'grade': 'Grade 3',
      'index': 0,
    },
    {
      'title': 'Basic Addition',
      'subject': 'Maths',
      'grade': 'Grade 3',
      'index': 1,
    },
    {
      'title': 'Sinhala Words',
      'subject': 'Sinhala',
      'grade': 'Grade 4',
      'index': 2,
    },
    {
      'title': 'Subtraction',
      'subject': 'Maths',
      'grade': 'Grade 4',
      'index': 3,
    },
    {
      'title': 'Sinhala Reading',
      'subject': 'Sinhala',
      'grade': 'Grade 5',
      'index': 4,
    },
    {
      'title': 'Multiplication',
      'subject': 'Maths',
      'grade': 'Grade 5',
      'index': 5,
    },
    {'title': 'Vowels', 'subject': 'Sinhala', 'grade': 'Grade 3', 'index': 6},
    {'title': 'Shapes', 'subject': 'Maths', 'grade': 'Grade 3', 'index': 7},
    {
      'title': 'Essay Writing',
      'subject': 'Sinhala',
      'grade': 'Grade 5',
      'index': 8,
    },
    {'title': 'Division', 'subject': 'Maths', 'grade': 'Grade 5', 'index': 9},
    // Add more dummy data to ensure filters work visibly
    {
      'title': 'Colors (Sin)',
      'subject': 'Sinhala',
      'grade': 'Grade 3',
      'index': 10,
    },
    {'title': 'Counting', 'subject': 'Maths', 'grade': 'Grade 3', 'index': 11},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    // Filter Logic
    final filteredLessons = _allLessons.where((lesson) {
      return lesson['subject'] == _selectedSubject &&
          lesson['grade'] == _selectedGrade;
    }).toList();

    return Column(
      children: [
        // ===== FILTERS SECTION =====
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Subject Filter
                _buildFilterGroup(
                  "Subject",
                  _subjects,
                  _selectedSubject,
                  (val) => setState(() => _selectedSubject = val),
                ),

                const SizedBox(width: 24),

                // Grade Filter
                _buildFilterGroup(
                  "Grade",
                  _grades,
                  _selectedGrade,
                  (val) => setState(() => _selectedGrade = val),
                  isGrade: true,
                ),
              ],
            ),
          ),
        ),

        // ===== CONTENT GRID =====
        Expanded(
          child: filteredLessons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No lessons found for\n$_selectedSubject - $_selectedGrade",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 31, 31, 31),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 cards per row
                    crossAxisSpacing: isTablet ? 18 : 14,
                    mainAxisSpacing: isTablet ? 18 : 14,
                    childAspectRatio: isTablet ? 0.85 : 0.75,
                  ),
                  itemCount: filteredLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = filteredLessons[index];
                    return _LearnCard(
                      index: lesson['index'] as int,
                      title: lesson['title'] as String,
                      grade: lesson['grade'] as String,
                      subject: lesson['subject'] as String,
                      onTap: () {
                        // TODO: open lesson
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterGroup(
    String label,
    List<String> options,
    String selectedValue,
    Function(String) onSelected, {
    bool isGrade = false,
  }) {
    return Row(
      children: [
        Text(
          "$label:",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ...options.map((option) {
          final isSelected = option == selectedValue;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false, // Cleaner look
              label: Text(
                option,
                style: TextStyle(
                  // Use a darker purple for better readability on white
                  color: isSelected ? const Color(0xFF4527A0) : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSelected(option);
              },
              elevation: 0,
              pressElevation: 0,
              // Transparent with white border when unselected
              backgroundColor: Colors.transparent,
              selectedColor: Colors.white,
              // Add white border to unselected, no border to selected
              side: isSelected
                  ? const BorderSide(color: Colors.transparent, width: 0)
                  : const BorderSide(color: Colors.white, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ================= LEARN CARD =================

class _LearnCard extends StatelessWidget {
  final int index;
  final String title;
  final String grade;
  final String subject;
  final VoidCallback onTap;

  const _LearnCard({
    required this.index,
    required this.title,
    required this.grade,
    required this.subject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Varied colors for different cards
    final colors = [
      const Color(0xFFFFB6C1), // Light pink
      const Color(0xFFB6E5FF), // Light blue
      const Color(0xFFB6FFB6), // Light green
      const Color(0xFFFFE5B6), // Light orange
      const Color(0xFFE5B6FF), // Light purple
      const Color(0xFFFFFFB6), // Light yellow
    ];

    final labelColors = [
      const Color(0xFFFF69B4), // Hot pink
      const Color(0xFF4FC3F7), // Sky blue
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFBA68C8), // Purple
      const Color(0xFFFFD54F), // Yellow
    ];

    final cardColor = colors[index % colors.length];
    final labelColor = labelColors[index % labelColors.length];

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // -------- IMAGE/ICON AREA --------
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          labelColor.withOpacity(0.3),
                          labelColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      subject == 'Maths'
                          ? Icons.calculate_rounded
                          : Icons.menu_book_rounded,
                      size: 48,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: labelColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        grade,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -------- TITLE AREA --------
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 14,
                          color: Colors.black.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Start Learning",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
