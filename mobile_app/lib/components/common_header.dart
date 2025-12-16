import 'package:flutter/material.dart';
import '../models/input_modes.dart';
import '../services/auth_api.dart';

class CommonHeader extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final InputMode inputMode;
  final ValueChanged<InputMode> onInputModeChanged;

  const CommonHeader({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.inputMode,
    required this.onInputModeChanged,
  });

  String _getInputModeLabel(InputMode mode) {
    switch (mode) {
      case InputMode.dwellTouch:
        return 'Dwell & Touch';
      case InputMode.eyeGaze:
        return 'Eye Gaze';
      case InputMode.voiceControl:
        return 'Voice Control';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    final topBarHeight = isTablet ? 64.0 : 56.0;
    final tabsHeight = isTablet ? 52.0 : 46.0;

    return SizedBox(
      height: topBarHeight,
      child: Row(
        children: [
          // ===== SETTINGS DROPDOWN =====
          PopupMenuButton<InputMode>(
            offset: const Offset(0, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.black.withOpacity(0.2), width: 1),
            ),
            elevation: 4,
            onSelected: onInputModeChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                height: 32,
                child: Text(
                  "INPUT METHOD",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...InputMode.values.map((mode) {
                final isSelected = mode == inputMode;
                return PopupMenuItem(
                  value: mode,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? const Color(0xFF6E4BC6)
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getInputModeLabel(mode),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? Colors.black87 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black.withOpacity(0.55),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.settings,
                size: 26,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ===== NAVIGATION TABS =====
          Expanded(
            child: _SegmentedTabs(
              height: tabsHeight,
              selectedIndex: selectedIndex,
              onChanged: onTabChanged,
              tabs: const ["Home", "Learn", "Games", "Profile"],
            ),
          ),

          const SizedBox(width: 10),

          // ===== PROFILE PHOTO =====
          PopupMenuButton<String>(
            offset: const Offset(0, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.black.withOpacity(0.2), width: 1),
            ),
            elevation: 4,
            tooltip: 'Profile Options',
            onSelected: (value) {
              if (value == 'profile') {
                onTabChanged(3);
              } else if (value == 'logout') {
                try {
                  AuthApi.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/newlogin',
                    (route) => false,
                  );
                } catch (e) {
                  debugPrint("Logout error: $e");
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: const Color(0xFF6E4BC6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Log Out",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7FE8FF), // Light blue avatar bg
                border: Border.all(
                  color: Colors.black.withOpacity(0.55),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, size: 26, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

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
