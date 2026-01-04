import 'package:flutter/material.dart';
import '../../models/input_modes.dart';
import '../../components/input_aware_button.dart';
import '../../components/responsive_layout.dart';

/// Question content (Prashna tab)
/// Displays cards for different subjects to take quizzes
class QuestionContent extends StatelessWidget {
  final InputMode inputMode;

  const QuestionContent({super.key, required this.inputMode});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildSinhalaCard(context)),
          const SizedBox(height: 16),
          Expanded(child: _buildMathsCard(context)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildSinhalaCard(context)),
        const SizedBox(width: 20),
        Expanded(child: _buildMathsCard(context)),
      ],
    );
  }

  Widget _buildSinhalaCard(BuildContext context) {
    return _QuestionCard(
      label: "සිංහල ප්‍රශ්න",
      icon: Icons.menu_book_outlined,
      color: const Color(0xFF26A69A), // Teal/Green
      inputMode: inputMode,
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("සිංහල ප්‍රශ්න ළඟදීම!")));
      },
    );
  }

  Widget _buildMathsCard(BuildContext context) {
    return _QuestionCard(
      label: "ගණිත ප්‍රශ්න",
      icon: Icons.calculate_outlined,
      color: const Color(0xFF7E57C2), // Purple
      inputMode: inputMode,
      onTap: () => Navigator.pushNamed(context, ''),
    );
  }
}

//=====================================================
// Large Question Selection Card Widget
//=====================================================
class _QuestionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final InputMode inputMode;

  const _QuestionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.inputMode,
  });

  @override
  Widget build(BuildContext context) {
    // Determine sizing based on device type if needed, or use standard defaults
    final bool isMobile = Responsive.isMobile(context);
    final double titleSize = isMobile ? 24 : 28;
    final double iconSize = isMobile ? 60 : 70;

    return InputAwareButton(
      onTap: onTap,
      inputMode: inputMode,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "ප්‍රශ්න පත්‍ර ආරම්භ කරන්න",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
