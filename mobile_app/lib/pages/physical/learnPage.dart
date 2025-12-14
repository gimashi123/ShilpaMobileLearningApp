import 'package:flutter/material.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  int _tabIndex = 1; // 0=Home, 1=Learn, 2=Games, 3=Profile

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    final padding = isTablet ? 18.0 : 14.0;
    final topBarHeight = isTablet ? 64.0 : 56.0;
    final tabHeight = isTablet ? 52.0 : 46.0;

    return Scaffold(
      backgroundColor: const Color(0xFF6E4BC6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              // ================= TOP BAR =================
              SizedBox(
                height: topBarHeight,
                child: Row(
                  children: [
                    _TopIconButton(
                      icon: Icons.settings,
                      onTap: () {
                        // TODO: open settings
                      },
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: _SegmentedTabs(
                        height: tabHeight,
                        selectedIndex: _tabIndex,
                        onChanged: (index) {
                          // Navigate back to Home (Dashboard) when Home tab is tapped
                          if (index == 0) {
                            Navigator.pop(context);
                          } else {
                            setState(() => _tabIndex = index);
                            // TODO: Add navigation for other tabs
                            // 1 -> LearnPage (current)
                            // 2 -> GamesPage
                            // 3 -> ProfilePage
                          }
                        },
                        tabs: const ["Home", "Learn", "Games", "Profile"],
                      ),
                    ),

                    const SizedBox(width: 10),

                    _AvatarButton(
                      onTap: () {
                        // TODO: go to profile
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ================= CONTENT =================
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 cards per row
                    crossAxisSpacing: isTablet ? 18 : 14,
                    mainAxisSpacing: isTablet ? 18 : 14,
                    childAspectRatio: isTablet
                        ? 0.85
                        : 0.75, // Adjust card proportions
                  ),
                  itemCount: 12, // Increased to show more cards
                  itemBuilder: (context, index) {
                    return _LearnCard(
                      index: index,
                      onTap: () {
                        // TODO: open lesson $index
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

// ================= UI COMPONENTS =================

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
        color: const Color(0xFFCDB7FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black54, width: 2),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = index == selectedIndex;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(index),
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
                  tabs[index],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : Colors.black,
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

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black54, width: 2),
        ),
        child: Icon(icon, size: 26),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AvatarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF7FE8FF),
          border: Border.all(color: Colors.black54, width: 2),
        ),
        child: const Icon(Icons.person, size: 26),
      ),
    );
  }
}

// ================= LEARN CARD =================

class _LearnCard extends StatelessWidget {
  final int index;
  final VoidCallback onTap;

  const _LearnCard({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Varied colors for different cards to make it more engaging
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
                      Icons.school_rounded,
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
                        "Lesson ${index + 1}",
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
                      "Topic ${index + 1}",
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
