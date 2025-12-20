import 'package:flutter/material.dart';
import 'package:mobile_app/session/session.dart';
import '../../models/input_modes.dart';
import '../../components/input_mode_switch.dart';
import '../../components/common_header.dart';
import 'dashboard_content.dart';
import 'learn_content.dart';
import 'games_content.dart';
import 'profile_content.dart';

/// Main screen that holds the navigation bar and switches between content pages
/// This ensures we have ONE navigation bar and shared input mode state
class PhysicalMainScreen extends StatefulWidget {
  const PhysicalMainScreen({super.key});

  @override
  State<PhysicalMainScreen> createState() => _PhysicalMainScreenState();
}

class _PhysicalMainScreenState extends State<PhysicalMainScreen> {
  String userName = "";
  String disabilityType = "";
  InputMode _inputMode =
      InputMode.standard; // Default to standard mode, not dwell
  int _selectedTab = 0; // 0: Home, 1: Learn, 2: Games, 3: Profile

  @override
  void initState() {
    super.initState();
    // Load from Session (set at login)
    userName = Session.userName ?? "Student";
    disabilityType = Session.disabilityType ?? "Not Set";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Color.fromARGB(255, 55, 35, 58),
              Color(0xFFFFF8E1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // COMMON HEADER WITH NAVIGATION (SHARED ACROSS ALL TABS)
                // =====================================================
                CommonHeader(
                  userName: userName,
                  inputMode: _inputMode,
                  selectedTab: _selectedTab,
                  onTabChanged: (index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // =====================================================
                // INPUT MODE SWITCH (Only show on Home tab)
                // =====================================================
                if (_selectedTab == 0)
                  Column(
                    children: [
                      InputModeSwitch(
                        selectedMode: _inputMode,
                        onChanged: (mode) {
                          setState(() {
                            _inputMode = mode;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // =====================================================
                // CONTENT AREA (SWITCHES BASED ON SELECTED TAB)
                // =====================================================
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the content based on selected tab
  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return DashboardContent(inputMode: _inputMode);
      case 1:
        return LearnContent(inputMode: _inputMode);
      case 2:
        return GamesContent(inputMode: _inputMode);
      case 3:
        return ProfileContent(
          userName: userName,
          disabilityType: disabilityType,
          inputMode: _inputMode,
        );
      default:
        return DashboardContent(inputMode: _inputMode);
    }
  }
}
