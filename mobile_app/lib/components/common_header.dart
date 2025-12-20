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
        // Top Row: Profile Avatar, User Name, Settings Icon
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              child: const Icon(Icons.person, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi, $userName 👋",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    "Ready to learn something new today?",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // Navigate to settings or show settings menu
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Navigation Bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                label: "Learn",
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
                icon: Icons.person_rounded,
                label: "Profile",
                isSelected: selectedTab == 3,
                inputMode: inputMode,
                onTap: () => onTabChanged(3),
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: widget.isSelected
            ? const LinearGradient(
                colors: [Color(0xFF7E57C2), Color(0xFFAB47BC)],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            color: widget.isSelected ? Colors.white : Colors.black54,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isSelected ? Colors.white : Colors.black54,
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
