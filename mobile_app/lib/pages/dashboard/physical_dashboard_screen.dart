import 'package:flutter/material.dart';
import '../../components/input_mode_switch.dart';
import '../../models/input_modes.dart';
import '../physical/learnPage.dart';

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
    final tabsHeight = isTablet ? 52.0 : 46.0;

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
              SizedBox(
                height: topBarHeight,
                child: Row(
                  children: [
                    _TopSquareIconButton(
                      icon: Icons.settings,
                      onTap: () {
                        // TODO: Settings
                      },
                    ),
                    const SizedBox(width: 10),

                    // Center segmented tabs
                    Expanded(
                      child: _SegmentedTabs(
                        height: tabsHeight,
                        selectedIndex: _tabIndex,
                        onChanged: (i) async {
                          // Don't navigate if already on Home
                          if (i == 0) {
                            setState(() => _tabIndex = 0);
                            return;
                          }

                          setState(() => _tabIndex = i);

                          // Navigate to LearnPage when Learn tab is tapped
                          if (i == 1) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LearnPage(),
                              ),
                            );
                            // Reset to Home tab when returning from Learn page
                            setState(() => _tabIndex = 0);
                          }
                          // TODO: Add navigation for other tabs (Games, Profile)
                        },
                        tabs: const ["Home", "Learn", "Games", "Profile"],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Right side: InputModeSwitch + Bell
                    // (Kept from your existing code, placed at top like requested)
                    SizedBox(
                      width: isTablet ? 280 : 220,
                      child: InputModeSwitch(
                        selectedMode: _selectedMode,
                        onChanged: _onInputModeChanged,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _TopSquareIconButton(
                      icon: Icons.notifications_outlined,
                      onTap: () {
                        // TODO: Notifications
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

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
                  padding: const EdgeInsets.only(
                    bottom: 8,
                  ), // Add bottom padding
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
                        // Navigate to LearnPage when a Learn card is tapped
                        if (item['type'] == 'Learn') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LearnPage(),
                            ),
                          );
                        }
                        // TODO: Add navigation for Games
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

/// ===== Segmented Tabs (Home / Learn / Games / Profile) =====
class _SegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  const _SegmentedTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFCDB7FF), // light purple bar
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.55), width: 2),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == selectedIndex;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF8A2BE2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: selected
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// ===== Simple square icon button (Settings / Bell) =====
class _TopSquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopSquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.55), width: 2),
        ),
        child: Icon(icon, size: 26, color: Colors.black87),
      ),
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
                padding: const EdgeInsets.all(14),
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

                    const SizedBox(height: 8),

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
                        const SizedBox(height: 6),
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
