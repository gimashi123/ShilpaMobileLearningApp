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
                  onTap: () => setState(() => _selectedSubject = 'Sinhala'),
                  inputMode: widget.inputMode,
                  borderRadius: BorderRadius.circular(25),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: _selectedSubject == 'Sinhala'
                          ? const Color(0xFFAB47BC) // Pink/Purple
                          : Colors.transparent,
                      boxShadow: _selectedSubject == 'Sinhala'
                          ? [
                              BoxShadow(
                                color: const Color(0xFFAB47BC).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "සිංහල",
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
                  onTap: () => setState(() => _selectedSubject = 'Maths'),
                  inputMode: widget.inputMode,
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
                      "ගණිතය",
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

        // ===== GAMES GRID =====
        Expanded(
          child: filteredGames.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videogame_asset_off_rounded,
                        size: 80,
                        color: const Color(0xFF4527A0).withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No games found for\n$_selectedSubject",
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
                    crossAxisCount: isTablet ? 4 : 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
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

// ================= GAME CARD (VIBRANT REDESIGN) =================

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
    // Subject-based base colors
    final baseColor = subject == 'Maths'
        ? const Color(0xFF7E57C2)
        : const Color(0xFFAB47BC); // Games tend to use the Pink/Purple combo

    // Slight variations for grid visual interest
    final cardColor = Color.lerp(baseColor, Colors.white, (id % 3) * 0.05)!;

    return InputAwareButton(
      borderRadius: BorderRadius.circular(25),
      onTap: onTap,
      inputMode: inputMode,
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
              child: const Icon(
                Icons.sports_esports_outlined,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
            const SizedBox(height: 8),
            // Play Label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                Text(
                  "Play",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
