import 'package:flutter/material.dart';
import 'package:mobile_app/session/session.dart';

class NavItem {
  final String label;
  final String route;
  const NavItem({required this.label, required this.route});
}

class TopNavBar extends StatelessWidget {
  /// selectedTab is the index of the *visible* items list
  final int selectedTab;

  const TopNavBar({super.key, required this.selectedTab});

  List<NavItem> _buildItems() {
    final type = (Session.disabilityType ?? "").toLowerCase();

    // Common items for everyone
    final common = <NavItem>[
      const NavItem(label: "Profile", route: "/profile"),
    ];

    // Disability-specific items
    switch (type) {
      case "hearing":
        return [
          const NavItem(label: "Home", route: "/home_hearing"),
          const NavItem(label: "පාඩම්", route: "/hearing_lessons"),
          const NavItem(label: "Games", route: "/games_hearing"),
          const NavItem(label: "ප්‍රශ්න", route: "/quizhear"),
          ...common,
        ];

      case "visual":
        return [
          const NavItem(label: "Home", route: "/home_visual"),
          const NavItem(label: "පාඩම්", route: "/visual_lessons"),
          const NavItem(label: "Games ", route: "/games_visual"),
          const NavItem(label: "ප්‍රශ්න", route: "/quizvisual"),
          ...common,
        ];

      case "physical":
        return [
          const NavItem(label: "Home", route: "/home_physical"),
          const NavItem(label: "පාඩම්", route: "/physical_lessons"),
          const NavItem(label: "Games", route: "/games_physical"),
          const NavItem(label: "ප්‍රශ්න", route: "/quizphysical"),
          ...common,
        ];

      case "cognitive":
        return [
          const NavItem(label: "Home", route: "/home_cognitive"),
          const NavItem(label: "පාඩම්", route: "/cognitive_lessons"),
          const NavItem(label: "Games", route: "/games_cognitive"),
          const NavItem(label: "ප්‍රශ්න", route: "/quizcognitive"),
          ...common,
        ];

      default:
        // Fallback if disabilityType is missing/unknown
        return [
          const NavItem(label: "Home", route: "/home"),
          const NavItem(label: "Profile", route: "/profile"),
        ];
    }
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    // Safety if selectedTab is out of range
    final safeSelected = selectedTab.clamp(0, items.length - 1);

    return Row(
      children: [
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 58,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFCDB6FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i];
                return _TabBtn(item.label, i == safeSelected, () {
                  if (i == safeSelected) return;
                  _navigate(context, item.route);
                });
              }),
            ),
          ),
        ),
        const SizedBox(width: 14),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _TabBtn(this.text, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF7E57C2), Color(0xFFAB47BC)],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: Colors.black, width: 2) : null,
          ),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
