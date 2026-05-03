import 'package:flutter/material.dart';
import '../../models/input_modes.dart';
import '../../components/input_aware_button.dart';
import '../../components/responsive_layout.dart';

/// Dashboard content (Home tab)
class DashboardContent extends StatelessWidget {
  final InputMode inputMode;
  final Function(String subject)? onNavigateToLearn;

  const DashboardContent({
    super.key,
    required this.inputMode,
    this.onNavigateToLearn,
  });

  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
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
                  onTap: () {
                    if (onNavigateToLearn != null) {
                      onNavigateToLearn!("Maths");
                    }
                  },
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
                    if (onNavigateToLearn != null) {
                      onNavigateToLearn!("Sinhala");
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("සිංහල පාඩම් ළඟදීම!")),
                      );
                    }
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ප්‍රශ්න පත්‍ර ළඟදීම!")),
                    );
                  },
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

  Widget _buildMobileLayout(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        _BigVerticalCard(
          label: "ගණිතය",
          icon: Icons.calculate_outlined,
          color: const Color(0xFF7E57C2), // Purple
          inputMode: inputMode,
          onTap: () {
            if (onNavigateToLearn != null) {
              onNavigateToLearn!("Maths");
            }
          },
        ),
        _BigVerticalCard(
          label: "සිංහල",
          icon: Icons.menu_book_outlined,
          color: const Color(0xFF26A69A), // Green/Teal
          inputMode: inputMode,
          onTap: () {
            if (onNavigateToLearn != null) {
              onNavigateToLearn!("Sinhala");
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("සිංහල පාඩම් ළඟදීම!")));
            }
          },
        ),
        _BigVerticalCard(
          label: "ප්‍රශ්න",
          icon: Icons.help_outline_rounded,
          color: const Color(0xFFFF5252), // Red/Coral
          inputMode: inputMode,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("ප්‍රශ්න පත්‍ර ළඟදීම!")),
            );
          },
        ),
        _BigVerticalCard(
          label: "GAMES",
          icon: Icons.sports_esports_outlined,
          color: const Color(0xFFAB47BC), // Pink/Purple
          inputMode: inputMode,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Games sections coming soon!")),
            );
          },
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
        voiceLabel: label,
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
                padding: EdgeInsets.all(Responsive.isMobile(context) ? 14 : 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: Responsive.isMobile(context) ? 36 : 50,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: Responsive.isMobile(context) ? 12 : 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.isMobile(context) ? 18 : 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
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
