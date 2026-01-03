import 'package:flutter/material.dart';
import '../models/input_modes.dart';
import 'input_aware_button.dart';

class InputModeSwitch extends StatefulWidget {
  final InputMode selectedMode;
  final ValueChanged<InputMode> onChanged;

  const InputModeSwitch({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  State<InputModeSwitch> createState() => _InputModeSwitchState();
}

class _InputModeSwitchState extends State<InputModeSwitch>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectMode(InputMode mode) {
    widget.onChanged(mode);
    _toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Collapsible List of Options
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0, // Expand from bottom up
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOption(InputMode.voiceControl, "Voice"),
              const SizedBox(height: 12),
              _buildOption(InputMode.eyeGaze, "Eye Gaze"),
              const SizedBox(height: 12),
              _buildOption(InputMode.dwellTouch, "Dwell"),
              const SizedBox(height: 12),
              _buildOption(InputMode.standard, "Standard"),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Main Toggle Button (Floating Rounded Button)
        InputAwareButton(
          inputMode: widget.selectedMode,
          onTap: _toggleMenu,
          borderRadius: BorderRadius.circular(30), // Fully rounded circle
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _isOpen
                  ? Icons.close_rounded
                  : _getIconForMode(widget.selectedMode),
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(InputMode mode, String label) {
    final bool isSelected = widget.selectedMode == mode;

    return InputAwareButton(
      inputMode: widget.selectedMode,
      onTap: () => _selectMode(mode), // Clicking option selects it
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF6A1B9A), width: 2)
              : Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // Layout: [Name] [Icon] - User requested "name right side of the icon"
        // Wait: "shows as a dropdown Icon and the name right side of the icon"
        // Standard: [Icon] [Name]. My previous thought was: Icon on left, Name on right.
        // Let's stick to [Icon] [Name] as that's standard and "right side of the icon" implies Icon is to the left.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              _getIconForMode(mode),
              color: isSelected
                  ? const Color(0xFF6A1B9A)
                  : Colors.grey.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF6A1B9A)
                    : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMode(InputMode mode) {
    switch (mode) {
      case InputMode.standard:
        return Icons.fingerprint_rounded;
      case InputMode.dwellTouch:
        return Icons.touch_app_rounded;
      case InputMode.eyeGaze:
        return Icons.visibility_rounded;
      case InputMode.voiceControl:
        return Icons.mic_rounded;
    }
  }
}
