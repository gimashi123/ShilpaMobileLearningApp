import 'package:flutter/material.dart';
import '../../components/input_aware_button.dart';
import '../../models/input_modes.dart';
import '../../components/responsive_layout.dart';
import '../../services/voice_focus_service.dart';
import '../games_physical/arithmetic_balance_scale.dart';
import '../games_physical/sinhala_word_sorter.dart';

/// Games content (Games tab)
class GamesContent extends StatefulWidget {
  final InputMode inputMode;
  final String? forcedSubject; // New: allow forcing a specific subject

  const GamesContent({super.key, required this.inputMode, this.forcedSubject});

  @override
  State<GamesContent> createState() => _GamesContentState();
}

class _GamesContentState extends State<GamesContent> {
  late String _selectedSubject;

  @override
  void initState() {
    super.initState();
    // Use forcedSubject if provided, otherwise default to Sinhala
    _selectedSubject = widget.forcedSubject ?? 'Sinhala';
  }

  // Mock Data for Games
  final List<Map<String, dynamic>> _allGames = [
    {'title': 'Noun vs Verb Sorting', 'subject': 'Sinhala', 'id': 102},
    {'title': 'Arithmetic Balance Scale', 'subject': 'Maths', 'id': 101},
  ];

  @override
  Widget build(BuildContext context) {
    // Responsive Layout Logic
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);
    final int crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);

    // Filter games based on selected subject (case-insensitive and robust)
    final filteredGames = _allGames.where((game) {
      final gameSub = (game['subject'] as String).toLowerCase();
      final targetSub = _selectedSubject.toLowerCase();
      
      // Basic match
      if (gameSub == targetSub) return true;
      
      // Handle Math vs Maths
      if ((gameSub == 'math' || gameSub == 'maths') && 
          (targetSub == 'math' || targetSub == 'maths')) {
        return true;
      }
      
      return false;
    }).toList();

    return Column(
      children: [
        // ===== SUBJECT TOGGLE SECTION (Hide if subject is forced) =====
        if (widget.forcedSubject == null)
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
                    crossAxisCount: crossAxisCount,
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
                        if (game['id'] == 101) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  leading: InputAwareButton(
                                    onTap: () => Navigator.pop(context),
                                    inputMode: widget.inputMode,
                                    showVoiceIndex: false,
                                    child: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Color(0xFF4527A0),
                                    ),
                                  ),
                                  title: Text(
                                    game['title'] as String,
                                    style: const TextStyle(
                                      color: Color(0xFF4527A0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                body: ArithmeticBalanceScale(
                                  inputMode: widget.inputMode,
                                ),
                                extendBodyBehindAppBar: true,
                              ),
                            ),
                          );
                        } else if (game['id'] == 102) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  leading: InputAwareButton(
                                    onTap: () => Navigator.pop(context),
                                    inputMode: widget.inputMode,
                                    showVoiceIndex: false,
                                    child: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Color(0xFF4527A0),
                                    ),
                                  ),
                                  title: Text(
                                    game['title'] as String,
                                    style: const TextStyle(
                                      color: Color(0xFF4527A0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                body: SinhalaWordSorter(
                                  inputMode: widget.inputMode,
                                ),
                                extendBodyBehindAppBar: true,
                              ),
                            ),
                          );
                        }
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
