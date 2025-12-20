import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_api.dart';
import 'package:mobile_app/session/session.dart';
import '../../models/input_modes.dart';

/// Profile content (Profile tab)
/// Fetches the latest data from backend to ensure accuracy
class ProfileContent extends StatefulWidget {
  final String userName;
  final String disabilityType;
  final InputMode inputMode;

  const ProfileContent({
    super.key,
    required this.userName,
    required this.disabilityType,
    required this.inputMode,
  });

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  String? _backendDisabilityType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestProfile();
  }

  Future<void> _fetchLatestProfile() async {
    try {
      final token = Session.token;
      if (token == null) return;

      final profile = await AuthApi.fetchProfile(token);
      if (mounted) {
        setState(() {
          _backendDisabilityType = profile['disabilityType'];
          _isLoading = false;
        });
        // Update session just in case it changed
        Session.disabilityType = _backendDisabilityType;
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback to widget prop if backend fetch fails or is loading
    final displayType = _backendDisabilityType ?? widget.disabilityType;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Profile Avatar
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            child: const Icon(Icons.person, size: 60, color: Colors.deepPurple),
          ),
          const SizedBox(height: 16),
          // User Name
          Text(
            widget.userName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Student",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Disability Type Badge (FETCHED FROM BACKEND)
          _isLoading
              ? const SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.accessibility_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getDisabilityLabel(displayType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 32),
          // Profile Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildStatCard(
                  icon: Icons.school_rounded,
                  title: "Lessons Completed",
                  value: "12",
                  color: const Color(0xFF7E57C2),
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.games_rounded,
                  title: "Games Played",
                  value: "8",
                  color: const Color(0xFF66BB6A),
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.quiz_rounded,
                  title: "Quizzes Taken",
                  value: "5",
                  color: const Color(0xFFFFB74D),
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.star_rounded,
                  title: "Total Points",
                  value: "450",
                  color: const Color(0xFFFF69B4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisabilityLabel(String type) {
    switch (type.toLowerCase()) {
      case 'physical':
        return 'PHYSICAL DISABILITY';
      case 'visual':
        return 'VISUAL DISABILITY';
      case 'hearing':
        return 'HEARING DISABILITY';
      case 'cognitive':
        return 'COGNITIVE DISABILITY';
      default:
        return '${type.toUpperCase()} DISABILITY';
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
