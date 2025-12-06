import 'package:flutter/material.dart';
import '../models/input_modes.dart'; // <-- where you declared InputMode enum

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
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _ModeChip(
            label: "Dwell",
            icon: Icons.touch_app,
            mode: InputMode.dwellTouch,
            isSelected: selectedMode == InputMode.dwellTouch,
            onTap: () => onChanged(InputMode.dwellTouch),
          ),
          _ModeChip(
            label: "Eye gaze",
            icon: Icons.visibility,
            mode: InputMode.eyeGaze,
            isSelected: selectedMode == InputMode.eyeGaze,
            onTap: () => onChanged(InputMode.eyeGaze),
          ),
          _ModeChip(
            label: "Voice",
            icon: Icons.mic,
            mode: InputMode.voiceControl,
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
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? cs.primary : Colors.black54,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? cs.primary : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
