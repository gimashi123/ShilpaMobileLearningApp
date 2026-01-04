import 'package:flutter/material.dart';

class AvailableGamesPage extends StatelessWidget {
  const AvailableGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final games = <GameItem>[
      GameItem(
        title: "More or Less",
        subtitle: "Compare quantities",
        icon: Icons.compare_arrows,
        routeName: "/visual_more_or_less_game",
      ),
      GameItem(
        title: "Number Match",
        subtitle: "Logic & patterns",
        icon: Icons.numbers,
        routeName: "/math_quick_game",
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Available Games"), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: GridView.builder(
            itemCount: games.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final g = games[index];
              return _GameCard(
                item: g,
                onTap: () {
                  // If you're using named routes:
                  Navigator.pushNamed(context, g.routeName);

                  // OR if you want direct widget navigation,
                  // replace routeName with a builder and use:
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => g.page));
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/* ------------------ MODEL ------------------ */
class GameItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;

  const GameItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeName,
  });
}

/* ------------------ CARD UI ------------------ */
class _GameCard extends StatelessWidget {
  final GameItem item;
  final VoidCallback onTap;

  const _GameCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  size: 26,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "Open",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
