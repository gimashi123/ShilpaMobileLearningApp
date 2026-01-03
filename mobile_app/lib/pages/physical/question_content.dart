import 'package:flutter/material.dart';
import '../../models/input_modes.dart';
import '../../components/input_aware_button.dart';

/// Question content (Prashna tab)
/// Displays cards for different subjects to take quizzes
class QuestionContent extends StatelessWidget {
  final InputMode inputMode;

  const QuestionContent({super.key, required this.inputMode});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 400).clamp(0.85, 1.5);

    return Column(
      children: [
        // =====================================================
        // VIBRANT CARDS ROW (Responsive & Scalable)
        // =====================================================
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SINHALA QUESTIONS CARD
              Expanded(
                child: _QuestionCard(
                  label: "සිංහල ප්‍රශ්න",
                  icon: Icons.menu_book_outlined,
                  color: const Color(0xFF26A69A), // Teal/Green
                  inputMode: inputMode,
                  scale: scale,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("සිංහල ප්‍රශ්න ළඟදීම!")),
                    );
                  },
                ),
              ),
              SizedBox(width: 16 * scale),
              // MATHS QUESTIONS CARD
              Expanded(
                child: _QuestionCard(
                  label: "ගණිත ප්‍රශ්න",
                  icon: Icons.calculate_outlined,
                  color: const Color(0xFF7E57C2), // Purple
                  inputMode: inputMode,
                  scale: scale,
                  onTap: () => Navigator.pushNamed(context, '/quiz'),
                ),
              ),
            ],
          ),
        ),
      ],
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
  final double scale;

  const _QuestionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.inputMode,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20 * scale),
      child: InputAwareButton(
        onTap: onTap,
        inputMode: inputMode,
        borderRadius: BorderRadius.circular(40 * scale),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(40 * scale),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 20 * scale,
                offset: Offset(0, 12 * scale),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(25 * scale),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 70 * scale, color: Colors.white),
              ),
              SizedBox(height: 30 * scale),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0 * scale),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30 * scale,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10 * scale),
              Text(
                "ප්‍රශ්න පත්‍ර ආරම්භ කරන්න",
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
