import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/pages/profile/edit_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_app/services/auth_api.dart';
import 'package:mobile_app/session/session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  String? errorText;

  Map<String, dynamic>? me;
  bool _enableAllActivities = Session.enableAllCognitiveActivities;

  @override
  void initState() {
    super.initState();
    _loadMe();
    _loadActivityPreference();
  }

  Future<void> _loadActivityPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(Session.enableAllActivitiesKey) ?? false;
    if (!mounted) return;
    setState(() {
      _enableAllActivities = enabled;
    });
    Session.enableAllCognitiveActivities = enabled;
  }

  Future<void> _setEnableAllActivities(bool value) async {
    setState(() {
      _enableAllActivities = value;
    });
    Session.enableAllCognitiveActivities = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Session.enableAllActivitiesKey, value);
  }

  Future<void> _loadMe() async {
    try {
      final token = Session.token;
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          loading = false;
          errorText = "Not logged in (Session.token is null/empty)";
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
          errorText = "Failed to load profile: ${res.statusCode}\n${res.body}";
        });
        return;
      }

      final decoded = jsonDecode(res.body);

      // ✅ Safe extraction (works for:
      // { success:true, data:{...} } OR just { ... }
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
        errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorText != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(errorText!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        loading = true;
                        errorText = null;
                      });
                      _loadMe();
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final name = (me?["name"] ?? "Student").toString();
    final email = (me?["email"] ?? "").toString();

    final disabilityType = (me?["disabilityType"] ?? "").toString();
    final isCognitive = disabilityType.toLowerCase() == "cognitive";

    final dynamic studentRaw = me?["student"];
    final Map<String, dynamic>? studentObj =
        (studentRaw is Map<String, dynamic>) ? studentRaw : null;

    final grade = (studentObj?["grade"] ?? "").toString();
    final age = (studentObj?["age"] ?? "").toString();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Profile",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7AF2D6), Color(0xFFB6FF8F)],
                  ),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.black),
              ),

              const SizedBox(height: 16),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              if (disabilityType.isNotEmpty ||
                  grade.isNotEmpty ||
                  age.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    [
                      if (disabilityType.isNotEmpty) "Type: $disabilityType",
                      if (grade.isNotEmpty) "Grade: $grade",
                      if (age.isNotEmpty) "Age: $age",
                    ].join("  •  "),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),

              const SizedBox(height: 30),

              if (isCognitive)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                      const Icon(Icons.tune, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Enable all activities",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: _enableAllActivities,
                        onChanged: _setEnableAllActivities,
                      ),
                    ],
                  ),
                ),
              _ProfileItem(
                icon: Icons.edit,
                text: "Edit Profile",
                onTap: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
              ),
              _ProfileItem(
                icon: Icons.lock,
                text: "Your Progress",
                onTap: () {},
              ),
              // _ProfileItem(
              //   icon: Icons.settings,
              //   text: "Settings",
              //   onTap: () {},
              // ),
              _ProfileItem(
                icon: Icons.logout,
                text: "Logout",
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/newlogin');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
