import 'package:flutter/material.dart';
import 'package:mobile_app/session/session.dart';
import '../../models/input_modes.dart';
import '../../components/input_mode_switch.dart';
import '../../components/common_header.dart';
import 'dashboard_content.dart';
import 'learn_content.dart';
import 'games_content.dart';
import 'profile_content.dart';
import 'calibration_screen.dart';
import '../../services/eye_tracking_service.dart';
import '../../services/speech_service.dart';
import '../../services/voice_command_parser.dart';
import '../../components/voice_indicator.dart';
import 'dart:async';

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

  // --- Eye Gaze State ---
  final _eyeTrackingService = EyeTrackingService();
  StreamSubscription? _gazeSubscription;
  double _gazeX = -100;
  double _gazeY = -100;
  bool _isCalibrated = false;

  @override
  void initState() {
    super.initState();
    // Load from Session (set at login)
    userName = Session.userName ?? "Student";
    disabilityType = Session.disabilityType ?? "Not Set";
  }

  void _handleInputModeChange(InputMode mode) async {
    // Stop any existing special input services
    _stopGazeTracking();
    _stopVoiceControl();

    // If switching TO Eye Gaze and not calibrated, go to calibration
    if (mode == InputMode.eyeGaze && !_isCalibrated) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CalibrationScreen()),
      );

      if (result == true) {
        setState(() {
          _isCalibrated = true;
          _inputMode = mode;
        });
        _startGazeTracking();
      } else {
        // User cancelled or failed calibration, revert mode
        return;
      }
    } else if (mode == InputMode.eyeGaze && _isCalibrated) {
      setState(() => _inputMode = mode);
      _startGazeTracking();
    } else if (mode == InputMode.voiceControl) {
      setState(() => _inputMode = mode);
      _startVoiceControl();
    } else {
      // Switching to standard or dwell
      setState(() => _inputMode = mode);
    }
  }

  void _startGazeTracking() async {
    await _eyeTrackingService.startTracking();
    _gazeSubscription?.cancel();
    _gazeSubscription = _eyeTrackingService.gazeStream.listen((data) {
      if (mounted) {
        setState(() {
          _gazeX = data.x;
          _gazeY = data.y;
        });
      }
    });
  }

  void _stopGazeTracking() async {
    _gazeSubscription?.cancel();
    _gazeSubscription = null;
    await _eyeTrackingService.stopTracking();
    if (mounted) {
      setState(() {
        _gazeX = -100;
        _gazeY = -100;
      });
    }
  }

  // --- Voice Control Logic ---
  void _startVoiceControl() {
    SpeechService.instance.setCommandListener((text) {
      if (mounted) {
        _processVoiceCommand(text);
      }
    });
    SpeechService.instance.startListening();
  }

  void _stopVoiceControl() {
    if (_inputMode == InputMode.voiceControl) {
      SpeechService.instance.stopListening();
    }
  }

  void _processVoiceCommand(String text) {
    print("Voice Heard: $text");
    final command = VoiceCommandParser.parse(text);

    setState(() {
      switch (command) {
        case VoiceCommand.navigateHome:
          _selectedTab = 0;
          break;
        case VoiceCommand.navigateLearn:
          _selectedTab = 1;
          break;
        case VoiceCommand.navigateGames:
          _selectedTab = 2;
          break;
        case VoiceCommand.navigateProfile:
          _selectedTab = 3;
          break;
        case VoiceCommand.navigateBack:
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            _selectedTab = 0; // Fallback to home
          }
          break;
        case VoiceCommand.unknown:
          // maybe show a "Didn't catch that" toast
          break;
      }
    });

    // Show feedback snackbar
    if (command != VoiceCommand.unknown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("හඳුනාගත් විධානය: $text"),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.teal.withOpacity(0.8),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopGazeTracking();
    _stopVoiceControl();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                            onChanged: _handleInputModeChange,
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

          // =====================================================
          // EYE GAZE CURSOR OVERLAY
          // =====================================================
          if (_inputMode == InputMode.eyeGaze)
            Positioned(
              left: _gazeX - 15,
              top: _gazeY - 15,
              child: IgnorePointer(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // =====================================================
          // VOICE CONTROL INDICATOR OVERLAY
          // =====================================================
          if (_inputMode == InputMode.voiceControl)
            const Positioned(bottom: 30, right: 30, child: VoiceIndicator()),
        ],
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
