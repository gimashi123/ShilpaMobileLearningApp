import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/pages/profile/edit_profile.dart';
import 'package:mobile_app/pages/profile/progress_report_screen.dart';
import 'package:mobile_app/services/auth_api.dart';
import 'package:mobile_app/session/session.dart';
import 'package:mobile_app/models/input_modes.dart';
import 'package:mobile_app/services/adaptive_dwell_service.dart';
import 'package:mobile_app/components/input_aware_button.dart';

class ProfileScreen extends StatefulWidget {
  final InputMode?
  inputMode; // Added to support physical disability interaction settings

  const ProfileScreen({super.key, this.inputMode});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  String? errorText;

  Map<String, dynamic>? me;

  // Animation controllers
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Initialize animation
    _waveAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Start the animation
    _waveController.repeat(reverse: true);

    _loadMe();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    try {
      final token = Session.token;
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          loading = false;
          errorText = "Ready to sign in?";
        });
        return;
      }

      final url = Uri.parse("${AuthApi.baseUrl}/api/me");

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          loading = false;
          errorText = "Couldn't reach your profile. Let's try again!";
        });
        return;
      }

      final decoded = jsonDecode(res.body);

      Map<String, dynamic> data;
      if (decoded is Map<String, dynamic>) {
        final d = decoded["data"];
        if (d is Map<String, dynamic>) {
          data = d;
        } else {
          data = decoded;
        }
      } else {
        throw Exception("Invalid response format");
      }

      if (!mounted) return;
      setState(() {
        me = data;
        loading = false;
        errorText = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorText = "Oops! Something unexpected happened.";
      });
    }
  }

  void _navigateToHomeByDisabilityType() {
    final disabilityType = (me?["disabilityType"] ?? "").toString().toLowerCase();
    
    if (disabilityType.isEmpty) {
      // If no disability type, go back normally
      Navigator.pop(context);
      return;
    }
    
    // Navigate to the appropriate home screen
    switch (disabilityType) {
      case 'visual':
        Navigator.pushReplacementNamed(context, '/home_visual');
        break;
      case 'hearing':
        Navigator.pushReplacementNamed(context, '/home_hearing');
        break;
      case 'physical':
        Navigator.pushReplacementNamed(context, '/home_physical');
        break;
      case 'cognitive':
        Navigator.pushReplacementNamed(context, '/home_cognitive');
        break;
      default:
        // If disability type doesn't match, go back normally
        Navigator.pop(context);
        break;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  String _getRandomEncouragement() {
    final messages = [
      "You're doing amazing things! 🌟",
      "Keep shining bright! ✨",
      "Today is your day! 💫",
      "You're making progress! 🌱",
      "Believe in yourself! 💝",
      "You've got this! 💪",
    ];
    return messages[DateTime.now().second % messages.length];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 233, 51, 236).withOpacity(0.2),
                const Color.fromARGB(255, 169, 24, 189).withOpacity(0.2),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _waveAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 10, 102, 80),
                          Color(0xFFB6FF8F),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text('✨', style: TextStyle(fontSize: 50)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Warming up your profile...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _getRandomEncouragement(),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7AF2D6)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (errorText != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF7AF2D6).withOpacity(0.1),
                const Color(0xFFB6FF8F).withOpacity(0.1),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('😊', style: TextStyle(fontSize: 50)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Connection hiccup!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          loading = true;
                          errorText = null;
                        });
                        _loadMe();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7AF2D6),
                        foregroundColor: const Color(0xFF2C3E50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Try Again ', style: TextStyle(fontSize: 16)),
                          Text('✨', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/newlogin');
                      },
                      child: const Text(
                        'Sign in instead →',
                        style: TextStyle(
                          color: Color(0xFF7AF2D6),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final name = (me?["name"] ?? "Wonderful You").toString();
    final email = (me?["email"] ?? "").toString();
    final disabilityType = (me?["disabilityType"] ?? "").toString();
    final isCognitive = disabilityType.toLowerCase() == "cognitive";

    int signGameXp = 0;
    if (me?["signGameXp"] != null) {
      if (me!["signGameXp"] is num) {
        signGameXp = (me!["signGameXp"] as num).toInt();
      } else if (me!["signGameXp"] is String) {
        signGameXp = int.tryParse(me!["signGameXp"]) ?? 0;
      }
    }
    final signGameLevel = signGameXp >= 1000 ? 2 : 1;
    final xpProgress = (signGameXp / 1000).clamp(0.0, 1.0);

    final dynamic studentRaw = me?["student"];
    final Map<String, dynamic>? studentObj =
        (studentRaw is Map<String, dynamic>) ? studentRaw : null;

    final grade = (studentObj?["grade"] ?? "").toString();
    final age = (studentObj?["age"] ?? "").toString();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 191, 29, 223).withOpacity(0),
              const Color.fromARGB(255, 191, 29, 223).withOpacity(0),
              const Color.fromARGB(255, 191, 29, 223).withOpacity(0),
            ],
            stops: const [0.0, 0.3, 0.7],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header with back button and greeting
                  Row(
                    children: [
                      // Back button - always visible to allow returning home
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7AF2D6).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: _navigateToHomeByDisabilityType,
                            color: const Color(0xFF2C3E50),
                            iconSize: 24,
                            tooltip: 'Back to Home',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name.split(' ').first,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7AF2D6).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Text('⭐', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 4),
                            Text(
                              'Learner',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Avatar with gentle animation
                  ScaleTransition(
                    scale: _waveAnimation,
                    child: Stack(
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7AF2D6), Color(0xFFB6FF8F)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7AF2D6).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfilePage(),
                                ),
                              );
                              if (changed == true) {
                                setState(() => loading = true);
                                _loadMe();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Color(0xFF7AF2D6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name and email with style
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      email,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats/Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (grade.isNotEmpty)
                        _buildInfoChip(
                          icon: '📚',
                          label: 'Grade $grade',
                          color: const Color(0xFF7AF2D6).withOpacity(0.2),
                        ),
                      if (age.isNotEmpty)
                        _buildInfoChip(
                          icon: '🎂',
                          label: '$age years',
                          color: const Color(0xFFB6FF8F).withOpacity(0.2),
                        ),
                      if (disabilityType.isNotEmpty)
                        _buildInfoChip(
                          icon: '💝',
                          label: disabilityType,
                          color: Colors.pink.withOpacity(0.1),
                        ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // XP Progress Card
                  Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text('🏆', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Level $signGameLevel',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$signGameXp / 1000 XP',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: xpProgress,
                              minHeight: 12,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7AF2D6)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            signGameLevel == 1 
                              ? 'Reach 1000 XP to unlock harder questions!' 
                              : 'You are at the maximum level! Amazing work! 🎉',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Quote of the day
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7AF2D6).withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7AF2D6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '💭',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quote of the day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getRandomEncouragement(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Menu items
                  _buildMenuItem(
                    icon: Icons.bar_chart_rounded,
                    text: 'My Progress',
                    subtitle: 'View your learning achievements',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProgressReportScreen(),
                        ),
                      );
                    },
                    gradientColors: const [
                      Color(0xFF6A11CB),
                      Color(0xFF2575FC),
                    ],
                  ),

                  _buildMenuItem(
                    icon: Icons.edit_rounded,
                    text: 'Edit Profile',
                    subtitle: 'Update your information',
                    onTap: () async {
                      final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                      if (changed == true) {
                        setState(() => loading = true);
                        _loadMe();
                      }
                    },
                    gradientColors: const [
                      Color(0xFF7AF2D6),
                      Color(0xFFB6FF8F),
                    ],
                  ),

                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    text: 'Sign Out',
                    subtitle: 'See you again soon!',
                    onTap: () => _showLogoutDialog(),
                    gradientColors: const [Colors.red, Colors.orange],
                  ),

                  const SizedBox(height: 20),

                  // App version
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> gradientColors,
    bool useInputAware = false, // Added to support gaze interaction reset
  }) {
    final body = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: gradientColors.first.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: useInputAware
          ? InputAwareButton(
              inputMode: widget.inputMode ?? InputMode.standard,
              onTap: onTap,
              child: body,
            )
          : body,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👋', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ready to go?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Come back soon to continue your learning journey!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Stay'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Session.token = null; // Clear session
                        Navigator.pop(ctx);
                        Navigator.pushReplacementNamed(context, '/newlogin');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
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