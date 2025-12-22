import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget {
  final int selectedTab; // 0 Home, 1 පාඩම්, 2 Games, 3 ප්‍රශ්න, 4 Profile


    //final disabilityType = Session.disabilityType;

  const TopNavBar({super.key, required this.selectedTab});

  void _navigate(BuildContext context, int index) {
    if (index == selectedTab) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home_hearing');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/hearing_lessons');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/games');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/quizhear');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Settings
        // Container(
        //   width: 78,
        //   height: 58,
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(14),
        //     border: Border.all(color: Colors.black, width: 3),
        //   ),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: const [
        //       Icon(Icons.settings, size: 30),
        //       SizedBox(width: 6),
        //       Icon(Icons.arrow_drop_down, size: 30, color: Colors.redAccent),
        //     ],
        //   ),
        // ),
        const SizedBox(width: 14),

        // Tabs
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
              children: [
                _TabBtn("Home", selectedTab == 0, () => _navigate(context, 0)),
                _TabBtn("පාඩම්", selectedTab == 1, () => _navigate(context, 1)),
                _TabBtn("Games", selectedTab == 2, () => _navigate(context, 2)),
                _TabBtn(
                  "ප්‍රශ්න",
                  selectedTab == 3,
                  () => _navigate(context, 3),
                ),
                _TabBtn(
                  "Profile",
                  selectedTab == 4,
                  () => _navigate(context, 4),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Avatar
        // Container(
        //   width: 62,
        //   height: 62,
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     border: Border.all(color: Colors.black, width: 3),
        //     gradient: const LinearGradient(
        //       colors: [Color(0xFF7AF2D6), Color(0xFFB6FF8F)],
        //     ),
        //   ),
        //   child: const Icon(Icons.person, size: 34),

        // ),
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