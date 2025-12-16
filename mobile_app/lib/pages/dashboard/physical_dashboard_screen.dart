import 'package:flutter/material.dart';
import '../../components/common_header.dart';
import '../../models/input_modes.dart';
import '../physical/learnPage.dart';
import '../physical/profilePage.dart';
import '../physical/gamesPage.dart';

class PhysicalDashboardScreen extends StatefulWidget {
  const PhysicalDashboardScreen({super.key});

  @override
  State<PhysicalDashboardScreen> createState() =>
      _PhysicalDashboardScreenState();
}

class _PhysicalDashboardScreenState extends State<PhysicalDashboardScreen> {
  // Input mode switch (dwell / eye gaze / voice)
  InputMode _selectedMode = InputMode.dwellTouch;

  // Top segmented tabs (Home/Learn/Games/Profile)
  int _tabIndex = 0;

  void _onInputModeChanged(InputMode mode) {
    setState(() => _selectedMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Responsive values (phones + tablets)
    final isTablet = size.shortestSide >= 600;
    final pad = isTablet ? 18.0 : 14.0;

    final topBarHeight = isTablet ? 64.0 : 56.0;

    // Calculate available height for cards
    // Total height - SafeArea padding - top bar - spacing - section title
    final availableHeight =
        size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        (pad * 2) - // top and bottom padding
        topBarHeight -
        14 - // spacing after top bar
        36 - // section title height (text + padding)
        20; // bottom spacing buffer (increased for safety)

    // Card size - make height responsive to available space
    final cardWidth = isTablet ? 420.0 : 320.0;
    // Use 80% of available height to ensure no overflow
    final cardHeight = (availableHeight * 0.80).clamp(
      isTablet ? 220.0 : 180.0, // minimum height
      isTablet ? 280.0 : 240.0, // maximum height
    );

    return Scaffold(
      backgroundColor: const Color(0xFF6E4BC6), // purple base like design
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            children: [
              // ===== TOP BAR =====
              CommonHeader(
                selectedIndex: _tabIndex,
                inputMode: _selectedMode,
                onInputModeChanged: _onInputModeChanged,
                onTabChanged: (i) {
                  setState(() => _tabIndex = i);
                },
              ),

              const SizedBox(height: 14),

              Expanded(child: _buildContent(isTablet, cardWidth, cardHeight)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isTablet, double cardWidth, double cardHeight) {
    switch (_tabIndex) {
      case 0:
        return _HomeContent(
          isTablet: isTablet,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
        );
      case 1:
        // Learn Content
        return const LearnContent();
      case 2:
        // Games Content
        return const GamesContent();
      case 3:
        // Profile Content
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _HomeContent extends StatelessWidget {
  final bool isTablet;
  final double cardWidth;
  final double cardHeight;

  const _HomeContent({
    required this.isTablet,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ===== SECTION TITLE =====
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Continue Learning",
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ===== CONTENT (Cards row - Horizontal Scroll) =====
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8), // Add bottom padding
            itemCount: 6, // More cards to show ongoing activities
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              // Sample data for ongoing lessons and games
              final items = [
                {
                  'title': 'Alphabet Learning',
                  'type': 'Learn',
                  'progress': 0.65,
                  'icon': Icons.abc_rounded,
                },
                {
                  'title': 'Number Matching',
                  'type': 'Game',
                  'progress': 0.40,
                  'icon': Icons.numbers_rounded,
                },
                {
                  'title': 'Shape Recognition',
                  'type': 'Learn',
                  'progress': 0.85,
                  'icon': Icons.category_rounded,
                },
                {
                  'title': 'Color Puzzle',
                  'type': 'Game',
                  'progress': 0.30,
                  'icon': Icons.palette_rounded,
                },
                {
                  'title': 'Word Building',
                  'type': 'Learn',
                  'progress': 0.55,
                  'icon': Icons.spellcheck_rounded,
                },
                {
                  'title': 'Memory Game',
                  'type': 'Game',
                  'progress': 0.75,
                  'icon': Icons.psychology_rounded,
                },
              ];

              final item = items[index];

              return _ModuleCard(
                width: cardWidth,
                height: cardHeight,
                title: item['title'] as String,
                label: item['type'] as String,
                progress: item['progress'] as double,
                icon: item['icon'] as IconData,
                onTap: () {
                  // TODO: Handle card tap
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ===== Big module card with progress tracking =====
/// Shows ongoing lessons and games with completion percentage
class _ModuleCard extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final String label;
  final double progress; // 0.0 to 1.0
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.width,
    required this.height,
    required this.title,
    required this.label,
    required this.progress,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progress * 100).toInt();
    final isGame = label == 'Game';
    final badgeColor = isGame
        ? const Color(0xFFFFB74D)
        : const Color(0xFF64FF6A);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ===== IMAGE/ICON AREA =====
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Gradient background
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isGame
                              ? [
                                  const Color(0xFFFFE082),
                                  const Color(0xFFFFB74D),
                                ]
                              : [
                                  const Color(0xFFB2FF59),
                                  const Color(0xFF66BB6A),
                                ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: 64,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),

                  // Type badge (Learn/Game)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  // Progress percentage badge
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Circular progress indicator
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 0.7
                                    ? Colors.green
                                    : progress >= 0.4
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                          ),
                          // Percentage text
                          Text(
                            '$progressPercent%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== TITLE AND PROGRESS BAR AREA =====
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(color: Colors.grey.shade50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              '$progressPercent% Complete',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: progress >= 0.7
                                    ? Colors.green.shade700
                                    : progress >= 0.4
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Linear progress bar
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: progress >= 0.7
                                      ? [
                                          Colors.green.shade400,
                                          Colors.green.shade600,
                                        ]
                                      : progress >= 0.4
                                      ? [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600,
                                        ]
                                      : [
                                          Colors.red.shade400,
                                          Colors.red.shade600,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
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
