import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_api.dart';
import 'package:mobile_app/session/session.dart';
import '../../models/input_modes.dart';
import '../../components/responsive_layout.dart';
import '../../services/adaptive_dwell_service.dart';
import '../../components/input_aware_button.dart';

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
              fontWeight: FontWeight.w900,
              color: Color(0xFF4527A0), // Deep Purple for legibility
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Student",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54, // Muted black for role
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Disability Type Badge (FETCHED FROM BACKEND)
          _isLoading
              ? const SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4527A0),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFD1C4E9,
                    ).withOpacity(0.4), // Soft Lavender
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF9575CD).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.accessibility_new_rounded,
                        color: Color(0xFF4527A0),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _getDisabilityLabel(displayType),
                        style: const TextStyle(
                          color: Color(0xFF4527A0),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 32),
          // Profile Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Responsive.isTablet(context)
                ? GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      _buildStatCard(
                        icon: Icons.school_rounded,
                        title: "Lessons Completed",
                        value: "12",
                        color: const Color(0xFF7E57C2),
                      ),
                      _buildStatCard(
                        icon: Icons.games_rounded,
                        title: "Games Played",
                        value: "8",
                        color: const Color(0xFF66BB6A),
                      ),
                      _buildStatCard(
                        icon: Icons.quiz_rounded,
                        title: "Quizzes Taken",
                        value: "5",
                        color: const Color(0xFFFFB74D),
                      ),
                      _buildStatCard(
                        icon: Icons.star_rounded,
                        title: "Total Points",
                        value: "450",
                        color: const Color(0xFFFF69B4),
                      ),
                    ],
                  )
                : Column(
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
          const SizedBox(height: 32),

          // ================= Interaction Settings (Adaptive Reset) =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    "අන්තර්ක්‍රියා සැකසුම් (Interaction Settings)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4527A0),
                    ),
                  ),
                ),
                InputAwareButton(
                  inputMode: widget.inputMode,
                  onTap: () async {
                    await AdaptiveDwellService().resetToDefault();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ප්‍රතිස්ථාපනය කරන්න (Reset Speed)",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4527A0),
                                ),
                              ),
                              Text(
                                "ප්‍රතිචාර කාලය මුල් තත්වයට පත් කරයි",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

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
