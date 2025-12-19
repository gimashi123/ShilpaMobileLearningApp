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
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
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
            currentMode: selectedMode,
            isSelected: selectedMode == InputMode.dwellTouch,
            onTap: () => onChanged(InputMode.dwellTouch),
          ),
          _ModeChip(
            label: "Eye gaze",
            icon: Icons.visibility,
            mode: InputMode.eyeGaze,
            currentMode: selectedMode,
            isSelected: selectedMode == InputMode.eyeGaze,
            onTap: () => onChanged(InputMode.eyeGaze),
          ),
          _ModeChip(
            label: "Voice",
            icon: Icons.mic,
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
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: InputAwareButton(
          inputMode: currentMode,
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withOpacity(0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? cs.primary : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
