import 'package:flutter/material.dart';
import '../../models/input_modes.dart';
import '../../components/input_aware_button.dart';

/// Dashboard content (Home tab)
class DashboardContent extends StatelessWidget {
  final InputMode inputMode;

  const DashboardContent({super.key, required this.inputMode});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // =====================================================
        // VIBRANT CARDS ROW (Responsive & Scalable)
        // =====================================================
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BigVerticalCard(
                  label: "ගණිතය",
                  icon: Icons.calculate_outlined,
                  color: const Color(0xFF7E57C2), // Purple
                  inputMode: inputMode,
                  onTap: () => Navigator.pushNamed(context, '/math_lessons'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigVerticalCard(
                  label: "සිංහල",
                  icon: Icons.menu_book_outlined,
                  color: const Color(0xFF26A69A), // Green/Teal
                  inputMode: inputMode,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("සිංහල පාඩම් ළඟදීම!")),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigVerticalCard(
                  label: "ප්‍රශ්න",
                  icon: Icons.help_outline_rounded,
                  color: const Color(0xFFFF5252), // Red/Coral
                  inputMode: inputMode,
                  onTap: () => Navigator.pushNamed(context, '/quiz'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigVerticalCard(
                  label: "GAMES",
                  icon: Icons.sports_esports_outlined,
                  color: const Color(0xFFAB47BC), // Pink/Purple
                  inputMode: inputMode,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Games sections coming soon!"),
                      ),
                    );
                  },
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
// Large Vertical Card Widget
//=====================================================
class _BigVerticalCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final InputMode inputMode;

  const _BigVerticalCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.inputMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InputAwareButton(
        onTap: onTap,
        inputMode: inputMode,
        borderRadius: BorderRadius.circular(35),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
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
