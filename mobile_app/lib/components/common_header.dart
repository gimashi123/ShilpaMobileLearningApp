import 'package:flutter/material.dart';
import 'input_aware_button.dart';
import '../models/input_modes.dart';
import 'responsive_layout.dart';

class CommonHeader extends StatelessWidget {
  final String userName;
  final InputMode inputMode;
  final int selectedTab; // 0: Home, 1: Learn, 2: Games, 3: Profile
  final Function(int) onTabChanged;

  const CommonHeader({
    super.key,
    required this.userName,
    required this.inputMode,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Header: Profile Info with Gradient Background
        Container(
          padding: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF6A1B9A),
                Color(0xFF42A5F5),
              ], // Deep Purple to Blue
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A1B9A).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: Responsive.isMobile(context) ? 50 : 64,
                height: Responsive.isMobile(context) ? 50 : 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color: const Color(0xFF6A1B9A),
                  size: Responsive.isMobile(context) ? 30 : 40,
                ),
              ),
              SizedBox(width: Responsive.isMobile(context) ? 12 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "සාදරයෙන් පිළිගනිමු", // Welcome in Sinhala
                      style: TextStyle(
                        fontSize: Responsive.isMobile(context) ? 14 : 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: Responsive.isMobile(context) ? 20 : 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: Responsive.isMobile(context) ? 24 : 28,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Navigation Bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFD1C4E9).withOpacity(0.4), // Soft lavender
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavTab(
                icon: Icons.home_rounded,
                label: "Home",
                isSelected: selectedTab == 0,
                inputMode: inputMode,
                onTap: () => onTabChanged(0),
              ),
              _NavTab(
                icon: Icons.school_rounded,
                label: "පාඩම්",
                isSelected: selectedTab == 1,
                inputMode: inputMode,
                onTap: () => onTabChanged(1),
              ),
              _NavTab(
                icon: Icons.games_rounded,
                label: "Games",
                isSelected: selectedTab == 2,
                inputMode: inputMode,
                onTap: () => onTabChanged(2),
              ),
              _NavTab(
                icon: Icons.quiz_rounded,
                label: "ප්‍රශ්න",
                isSelected: selectedTab == 3,
                inputMode: inputMode,
                onTap: () => onTabChanged(3),
              ),
              _NavTab(
                icon: Icons.person_rounded,
                label: "Profile",
                isSelected: selectedTab == 4,
                inputMode: inputMode,
                onTap: () => onTabChanged(4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final InputMode inputMode;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.inputMode,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive scaling
    final bool isMobile = Responsive.isMobile(context);
    final double paddingH = isMobile ? 4 : 12;
    final double paddingV = isMobile ? 8 : 12;
    final double iconSize = isMobile ? 24 : 28;
    final double fontSize = isMobile ? 11 : 14;

    Widget content = SizedBox(
      height: isMobile ? 65 : 80,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: paddingV, horizontal: paddingH),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A1B9A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6A1B9A).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF4527A0),
              size: iconSize,
            ),
            if (!isMobile || isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF4527A0),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Expanded(
      child: InputAwareButton(
        onTap: onTap,
        inputMode: inputMode,
        showVoiceIndex: false,
        child: content,
      ),
    );
  }
}
