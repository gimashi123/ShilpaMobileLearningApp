import 'package:flutter/material.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  int _tabIndex = 1; // 0=Home, 1=Learn, 2=Games, 3=Profile

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    final padding = isTablet ? 18.0 : 14.0;
    final topBarHeight = isTablet ? 64.0 : 56.0;
    final tabHeight = isTablet ? 52.0 : 46.0;

    return Scaffold(
      backgroundColor: const Color(0xFF6E4BC6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              // ================= TOP BAR =================
              SizedBox(
                height: topBarHeight,
                child: Row(
                  children: [
                    _TopIconButton(
                      icon: Icons.settings,
                      onTap: () {
                        // TODO: open settings
                      },
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: _SegmentedTabs(
                        height: tabHeight,
                        selectedIndex: _tabIndex,
                        onChanged: (index) {
                          setState(() => _tabIndex = index);
                          // TODO: navigation
                          // 0 -> HomePage
                          // 1 -> LearnPage (current)
                          // 2 -> GamesPage
                          // 3 -> ProfilePage
                        },
                        tabs: const ["Home", "Learn", "Games", "Profile"],
                      ),
                    ),

                    const SizedBox(width: 10),

                    _AvatarButton(
                      onTap: () {
                        // TODO: go to profile
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ================= CONTENT =================
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _LearnCard(
                      onTap: () {
                        // TODO: open lesson
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= UI COMPONENTS =================

class _SegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  const _SegmentedTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFCDB7FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black54, width: 2),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = index == selectedIndex;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF8A2BE2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: selected
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black54, width: 2),
        ),
        child: Icon(icon, size: 26),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AvatarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF7FE8FF),
          border: Border.all(color: Colors.black54, width: 2),
        ),
        child: const Icon(Icons.person, size: 26),
      ),
    );
  }
}

// ================= LEARN CARD =================

class _LearnCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LearnCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // -------- IMAGE PLACEHOLDER --------
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Text(
                      "IMAGE HERE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  // 👉 Later replace above Container with:
                  // Image.asset(
                  //   "assets/learn_image.png",
                  //   width: double.infinity,
                  //   fit: BoxFit.cover,
                  // ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64FF6A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Text(
                        "Learn",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -------- TEXT PLACEHOLDER --------
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _FakeLine(),
                    SizedBox(height: 8),
                    _FakeLine(),
                    SizedBox(height: 8),
                    _FakeLine(),
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

class _FakeLine extends StatelessWidget {
  const _FakeLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
