import 'package:flutter/material.dart';
import '../../components/input_aware_button.dart';
import '../../models/input_modes.dart';

class GamesContent extends StatelessWidget {
  final InputMode inputMode;

  const GamesContent({super.key, required this.inputMode});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 cards per row
        crossAxisSpacing: isTablet ? 18 : 14,
        mainAxisSpacing: isTablet ? 18 : 14,
        childAspectRatio: isTablet ? 0.85 : 0.75, // Adjust card proportions
      ),
      itemCount: 12, // Number of games
      itemBuilder: (context, index) {
        return _GameCard(
          index: index,
          inputMode: inputMode,
          onTap: () {
            // TODO: open game $index
          },
        );
      },
    );
  }
}

// ================= GAME CARD =================

class _GameCard extends StatelessWidget {
  final int index;
  final VoidCallback onTap;
  final InputMode inputMode;

  const _GameCard({
    required this.index,
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

    // Shift colors slightly from learn page or keep same logic
    final cardColor = colors[index % colors.length];
    final labelColor = labelColors[index % labelColors.length];

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
                      Icons.videogame_asset_rounded, // Game icon
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
                        "Game ${index + 1}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
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
                      "Fun Game ${index + 1}",
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
