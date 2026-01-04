import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/top_nav_bar.dart';

class VisualQuizDashboard extends StatelessWidget {
  const VisualQuizDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ✅ TOP NAV BAR (selected = 3)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TopNavBar(
                selectedTab: 3,
                onTapTab: (int index) {
                  // Your TopNavBar already navigates internally using _navigate().
                  // This callback is required only because constructor requires it.
                },
                highContrast: false,
                fontSize: 18,
                title: "ප්‍රශ්න",
              ),
            ),

            const SizedBox(height: 16),

            // ✅ TWO CARDS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _CardItem(
                      title: "ගණිත ප්‍රශ්න",
                      icon: Icons.calculate,
                      onTap: () {
                        Navigator.pushNamed(context, '/quiz');
                      },
                    ),
                    _CardItem(
                      title: "සිංහල ප්‍රශ්න",
                      icon: Icons.book,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Coming soon!")),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CardItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.deepPurple),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
