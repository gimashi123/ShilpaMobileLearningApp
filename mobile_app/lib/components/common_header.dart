import 'dart:async';
import 'package:flutter/material.dart';
import '../models/input_modes.dart';

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
        // Container(
        //   padding: const EdgeInsets.all(16),
        //   decoration: BoxDecoration(
        //     gradient: const LinearGradient(
        //       begin: Alignment.centerLeft,
        //       end: Alignment.centerRight,
        //       colors: [
        //         Color(0xFF6A1B9A),
        //         Color(0xFF42A5F5),
        //       ], // Deep Purple to Blue
        //     ),
        //     borderRadius: BorderRadius.circular(30),
        //     border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        //     boxShadow: [
        //       BoxShadow(
        //         color: const Color(0xFF6A1B9A).withOpacity(0.3),
        //         blurRadius: 15,
        //         offset: const Offset(0, 8),
        //       ),
        //     ],
        //   ),
        //   child: Row(
        //     children: [
        //       Container(
        //         width: 64,
        //         height: 64,
        //         decoration: BoxDecoration(
        //           color: Colors.white,
        //           shape: BoxShape.circle,
        //           boxShadow: [
        //             BoxShadow(
        //               color: Colors.black.withOpacity(0.1),
        //               blurRadius: 8,
        //             ),
        //           ],
        //         ),
        //         child: const Icon(
        //           Icons.person,
        //           color: Color(0xFF6A1B9A),
        //           size: 40,
        //         ),
        //       ),
        //       const SizedBox(width: 20),
        //       Expanded(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             const Text(
        //               "සාදරයෙන් පිළිගනිමු", // Welcome in Sinhala
        //               style: TextStyle(
        //                 fontSize: 16,
        //                 color: Colors.white70,
        //                 fontWeight: FontWeight.w500,
        //               ),
        //             ),
        //             Text(
        //               userName,
        //               style: const TextStyle(
        //                 fontSize: 28,
        //                 fontWeight: FontWeight.w900,
        //                 color: Colors.white,
        //                 letterSpacing: 0.5,
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //       Container(
        //         decoration: BoxDecoration(
        //           color: Colors.white.withOpacity(0.1),
        //           shape: BoxShape.circle,
        //         ),
        //         child: IconButton(
        //           onPressed: () {},
        //           icon: const Icon(
        //             Icons.settings_outlined,
        //             color: Colors.white,
        //             size: 28,
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
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

class _NavTab extends StatefulWidget {
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
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  Timer? _dwellTimer;
  Offset? _touchPosition;

  @override
  void dispose() {
    _dwellTimer?.cancel();
    super.dispose();
  }

  void _handleDwellStart(Offset localPosition) {
    setState(() {
      _touchPosition = localPosition;
    });

    _dwellTimer?.cancel();
    _dwellTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        widget.onTap();
        _resetDwell();
      }
    });
  }

  void _handleDwellUpdate(Offset localPosition) {
    if (_touchPosition != null) {
      setState(() {
        _touchPosition = localPosition;
      });
    }
  }

  void _resetDwell() {
    _dwellTimer?.cancel();
    if (mounted) {
      setState(() {
        _touchPosition = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: widget.isSelected ? const Color(0xFF6A1B9A) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.isSelected
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
        children: [
          Icon(
            widget.icon,
            color: widget.isSelected ? Colors.white : const Color(0xFF4527A0),
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w600,
              color: widget.isSelected ? Colors.white : const Color(0xFF4527A0),
            ),
          ),
        ],
      ),
    );

    // If not dwell mode, behave like a standard GestureDetector
    if (widget.inputMode != InputMode.dwellTouch) {
      return Expanded(
        child: GestureDetector(onTap: widget.onTap, child: content),
      );
    }

    // Dwell interaction - same as InputAwareButton but without visual feedback
    return Expanded(
      child: Listener(
        onPointerDown: (event) => _handleDwellStart(event.localPosition),
        onPointerMove: (event) => _handleDwellUpdate(event.localPosition),
        onPointerUp: (_) => _resetDwell(),
        onPointerCancel: (_) => _resetDwell(),
        behavior: HitTestBehavior.opaque,
        child: content,
        // No Stack with CustomPaint - this is the only difference from InputAwareButton
      ),
    );
  }
}
