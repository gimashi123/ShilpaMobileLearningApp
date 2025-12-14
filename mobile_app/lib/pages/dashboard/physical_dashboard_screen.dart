import 'package:flutter/material.dart';
import '../../components/input_mode_switch.dart';
import '../../models/input_modes.dart';

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

    // Card size
    final cardWidth = isTablet ? 420.0 : 320.0;
    final cardHeight = isTablet ? 260.0 : 215.0;

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
                        onChanged: (i) => setState(() => _tabIndex = i),
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

              const SizedBox(height: 18),

              // ===== CONTENT (Cards row like UI) =====
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 18),
                    itemBuilder: (context, index) {
                      // You can switch card label based on tabIndex later if you want.
                      final label = (index == 2) ? "Games" : "Learn";

                      return _ModuleCard(
                        width: cardWidth,
                        height: cardHeight,
                        label: label,
                        onTap: () {
                          // TODO: Navigate based on card
                        },
                      );
                    },
                  ),
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

/// ===== Big module card like your UI =====
/// Runs without images: uses a placeholder.
/// Later: replace the placeholder with Image.asset(...)
class _ModuleCard extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.width,
    required this.height,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ===== IMAGE AREA (placeholder for now) =====
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Text(
                        "IMAGE PLACEHOLDER",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    // ✅ Later, replace the Container above with this:
                    // Positioned.fill(
                    //   child: Image.asset(
                    //     "assets/your_image.png",
                    //     fit: BoxFit.cover,
                    //   ),
                    // ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64FF6A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== TEXT LINES AREA (as in UI) =====
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _FakeLineRow(),
                    SizedBox(height: 8),
                    _FakeLineRow(),
                    SizedBox(height: 8),
                    _FakeLineRow(),
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

class _FakeLineRow extends StatelessWidget {
  const _FakeLineRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _Line(w: 38),
        SizedBox(width: 10),
        _Line(w: 38),
        SizedBox(width: 10),
        _Line(w: 38),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final double w;
  const _Line({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
