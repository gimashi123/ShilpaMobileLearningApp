import 'package:flutter/material.dart';
import '../../components/input_aware_button.dart';
import '../../models/input_modes.dart';

/// Games content (Games tab)
class GamesContent extends StatefulWidget {
  final InputMode inputMode;

  const GamesContent({super.key, required this.inputMode});

  @override
  State<GamesContent> createState() => _GamesContentState();
}

class _GamesContentState extends State<GamesContent> {
  String _selectedSubject = 'Sinhala'; // Default subject

  // Mock Data for Games
  final List<Map<String, dynamic>> _allGames = [
    {'title': 'Sinhala Word Puzzle', 'subject': 'Sinhala', 'id': 1},
    {'title': 'Maths Addition Quest', 'subject': 'Maths', 'id': 2},
    {'title': 'Sinhala Letter Match', 'subject': 'Sinhala', 'id': 3},
    {'title': 'Maths Shapes Adventure', 'subject': 'Maths', 'id': 4},
    {'title': 'Sinhala Grammar Quiz', 'subject': 'Sinhala', 'id': 5},
    {'title': 'Maths Subtraction Hero', 'subject': 'Maths', 'id': 6},
    {'title': 'Sinhala Story Maker', 'subject': 'Sinhala', 'id': 7},
    {'title': 'Maths Multiplication Race', 'subject': 'Maths', 'id': 8},
    {'title': 'Sinhala Vocabulary Fun', 'subject': 'Sinhala', 'id': 9},
    {'title': 'Maths Division Master', 'subject': 'Maths', 'id': 10},
    {'title': 'Sinhala Poetry Game', 'subject': 'Sinhala', 'id': 11},
    {'title': 'Maths Fractions Explorer', 'subject': 'Maths', 'id': 12},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    // Filter games based on selected subject
    final filteredGames = _allGames.where((game) {
      return game['subject'] == _selectedSubject;
    }).toList();

    return Column(
      children: [
        // ===== SUBJECT TOGGLE SECTION =====
        Container(
          height: 56,
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              // SINHALA TAB
              Expanded(
                child: InputAwareButton(
                  onTap: () => setState(() => _selectedSubject = 'Sinhala'),
                  inputMode: widget.inputMode,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: _selectedSubject == 'Sinhala'
                          ? Colors.orangeAccent
                          : Colors.transparent,
                      boxShadow: _selectedSubject == 'Sinhala'
                          ? [
                              BoxShadow(
                                color: Colors.orangeAccent.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Sinhala",
                      style: TextStyle(
                        color: _selectedSubject == 'Sinhala'
                            ? Colors.black87
                            : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // MATHS TAB
              Expanded(
                child: InputAwareButton(
                  onTap: () => setState(() => _selectedSubject = 'Maths'),
                  inputMode: widget.inputMode,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: _selectedSubject == 'Maths'
                          ? Colors.blueAccent
                          : Colors.transparent,
                      boxShadow: _selectedSubject == 'Maths'
                          ? [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Maths",
                      style: TextStyle(
                        color: _selectedSubject == 'Maths'
                            ? Colors.black87
                            : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ===== GAMES GRID =====
        Expanded(
          child: filteredGames.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videogame_asset_off_rounded,
                        size: 64,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No games found for $_selectedSubject",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 cards per row
                    crossAxisSpacing: isTablet ? 18 : 14,
                    mainAxisSpacing: isTablet ? 18 : 14,
                    childAspectRatio: isTablet ? 0.85 : 0.75,
                  ),
                  itemCount: filteredGames.length,
                  itemBuilder: (context, index) {
                    final game = filteredGames[index];
                    return _GameCard(
                      id: game['id'] as int,
                      title: game['title'] as String,
                      subject: game['subject'] as String,
                      inputMode: widget.inputMode,
                      onTap: () {
                        // TODO: Start game logic
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ================= GAME CARD =================

class _GameCard extends StatelessWidget {
  final int id;
  final String title;
  final String subject;
  final VoidCallback onTap;
  final InputMode inputMode;

  const _GameCard({
    required this.id,
    required this.title,
    required this.subject,
    required this.onTap,
    required this.inputMode,
  });

  @override
  Widget build(BuildContext context) {
    // Varied colors for different cards
    final colors = [
      const Color(0xFFE5B6FF), // Light purple
      const Color(0xFFFFE5B6), // Light orange
      const Color(0xFFB6FFB6), // Light green
      const Color(0xFFFFB6C1), // Light pink
      const Color(0xFFB6E5FF), // Light blue
      const Color(0xFFFFFFB6), // Light yellow
    ];

    final labelColors = [
      const Color(0xFFBA68C8), // Purple
      const Color(0xFFFFB74D), // Orange
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFF69B4), // Hot pink
      const Color(0xFF4FC3F7), // Sky blue
      const Color(0xFFFFD54F), // Yellow
    ];

    final cardColor = colors[id % colors.length];
    final labelColor = labelColors[id % labelColors.length];

    return InputAwareButton(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      inputMode: inputMode,
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
                      Icons.videogame_asset_rounded,
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
                        subject,
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
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: Colors.black.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Play Now",
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
