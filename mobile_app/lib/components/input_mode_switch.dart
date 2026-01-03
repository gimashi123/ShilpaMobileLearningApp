import 'package:flutter/material.dart';
import '../models/input_modes.dart';
import 'input_aware_button.dart';

class InputModeSwitch extends StatelessWidget {
  final InputMode selectedMode;
  final ValueChanged<InputMode> onChanged;

  const InputModeSwitch({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFD1C4E9).withOpacity(0.3), // Soft lavender
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          _ModeChip(
            label: "Standard",
            icon: Icons.fingerprint_rounded,
            mode: InputMode.standard,
            currentMode: selectedMode,
            isSelected: selectedMode == InputMode.standard,
            onTap: () => onChanged(InputMode.standard),
          ),
          const SizedBox(width: 8),
          _ModeChip(
            label: "Dwell",
            icon: Icons.touch_app_rounded,
            mode: InputMode.dwellTouch,
            currentMode: selectedMode,
            isSelected: selectedMode == InputMode.dwellTouch,
            onTap: () => onChanged(InputMode.dwellTouch),
          ),
          const SizedBox(width: 8),
          _ModeChip(
            label: "Eye Gaze",
            icon: Icons.visibility_rounded,
            mode: InputMode.eyeGaze,
            currentMode: selectedMode,
            isSelected: selectedMode == InputMode.eyeGaze,
            onTap: () => onChanged(InputMode.eyeGaze),
          ),
          const SizedBox(width: 8),
          _ModeChip(
            label: "Voice",
            icon: Icons.mic_rounded,
            mode: InputMode.voiceControl,
            currentMode: selectedMode,
            isSelected: selectedMode == InputMode.voiceControl,
            onTap: () => onChanged(InputMode.voiceControl),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final InputMode mode;
  final InputMode currentMode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.mode,
    required this.currentMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InputAwareButton(
        inputMode: currentMode,
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6A1B9A) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6A1B9A).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 26,
                color: isSelected ? Colors.white : const Color(0xFF4527A0),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF4527A0),
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
