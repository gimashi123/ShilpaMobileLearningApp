import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ✅ Profile tab index
  // 0 Home, 1 පාඩම්, 2 Games, 3 ප්‍රශ්න, 4 Profile
  final int selectedTab = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ================= TOP TITLE =================
              const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // ================= PROFILE AVATAR =================
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7AF2D6),
                      Color(0xFFB6FF8F),
                    ],
                  ),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 16),

              // ================= USER NAME =================
              const Text(
                "Student Name",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "student@email.com",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              // ================= OPTIONS =================
              _ProfileItem(
                icon: Icons.edit,
                text: "Edit Profile",
                onTap: () {},
              ),
              _ProfileItem(
                icon: Icons.lock,
                text: "Change Password",
                onTap: () {},
              ),
              _ProfileItem(
                icon: Icons.settings,
                text: "Settings",
                onTap: () {},
              ),
              _ProfileItem(
                icon: Icons.logout,
                text: "Logout",
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= PROFILE ITEM =================
class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ProfileItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
