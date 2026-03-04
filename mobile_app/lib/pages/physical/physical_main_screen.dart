import 'package:flutter/material.dart';
import 'package:mobile_app/session/session.dart';
import '../../services/interaction_status_service.dart';
import '../../models/input_modes.dart';
import '../../components/input_mode_switch.dart';
import '../../components/common_header.dart';
import 'dashboard_content.dart';
import 'learn_content.dart';
import 'games_content.dart';
import 'question_content.dart';
import 'profile_content.dart';
import 'calibration_screen.dart';
import '../../services/eye_tracking_service.dart';
import '../../services/speech_service.dart';
import '../../services/voice_command_parser.dart';
import '../../components/voice_indicator.dart';
import '../../services/adaptive_dwell_service.dart';
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

  // --- Eye Gaze & Dwell State ---
  final _eyeTrackingService = EyeTrackingService();
  final _adaptiveDwellService = AdaptiveDwellService();
  InteractionStatus? _currentInteraction;
  StreamSubscription? _interactionSubscription;
  StreamSubscription? _gazeSubscription;
  StreamSubscription? _adaptationSubscription;
  double _gazeX = -100;
  double _gazeY = -100;
  bool _isGazeStable = false;
  bool _isCalibrated = false;

  @override
  void initState() {
    super.initState();
    // Load from Session (set at login)
    userName = Session.userName ?? "Student";
    disabilityType = Session.disabilityType ?? "Not Set";

    // Initialize Adaptive Dwell Logic
    _adaptiveDwellService.init();
    _adaptationSubscription = _adaptiveDwellService.adaptationStream.listen((
      event,
    ) {
      if (mounted) {
        _showAdaptationFeedback(event);
      }
    });

    _initInteractionListener();
  }

  void _initInteractionListener() {
    _interactionSubscription = InteractionStatusService().statusStream.listen((
      status,
    ) {
      if (mounted) {
        setState(() => _currentInteraction = status);
      }
    });
  }

  void _showAdaptationFeedback(DwellAdaptationEvent event) {
    final bool isFaster = event.direction == AdaptationDirection.decreased;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isFaster ? Icons.speed : Icons.accessibility_new,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFaster
                        ? "අන්තර්ක්‍රියා වේගවත් කරන ලදී"
                        : "අන්තර්ක්‍රියා ස්ථායී කරන ලදී",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "නව කාලය: ${event.newValue.toStringAsFixed(1)}s (කලින්: ${event.oldValue.toStringAsFixed(1)}s)",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isFaster
            ? Colors.green.shade700
            : Colors.blue.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: "හරි",
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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
          _isGazeStable = data.isStable; // Track stability
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
        case VoiceCommand.navigateQuiz:
          _selectedTab = 3;
          break;
        case VoiceCommand.navigateProfile:
          _selectedTab = 4;
          break;
        case VoiceCommand.navigateBack:
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            _selectedTab = 0; // Fallback to home
          }
          break;

        // --- Input Mode Switching ---
        case VoiceCommand.setModeStandard:
          _handleInputModeChange(InputMode.standard);
          break;
        case VoiceCommand.setModeDwell:
          _handleInputModeChange(InputMode.dwellTouch);
          break;
        case VoiceCommand.setModeEyeGaze:
          _handleInputModeChange(InputMode.eyeGaze);
          break;
        case VoiceCommand.setModeVoice:
          _handleInputModeChange(InputMode.voiceControl);
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
    _adaptationSubscription?.cancel();
    _interactionSubscription?.cancel();
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF3E5F5), // Light Lavender
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
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
                    // CONTENT AREA (SWITCHES BASED ON SELECTED TAB)
                    // =====================================================
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ),
          ),

          // =====================================================
          // TOP GUIDANCE / CONFIRMATION BAR
          // =====================================================
          if (_inputMode == InputMode.eyeGaze &&
              _currentInteraction != null &&
              _currentInteraction!.state != InteractionState.none)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: _getGuidanceColor(),
                      borderRadius: BorderRadius.circular(20),
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
                        Icon(_getGuidanceIcon(), color: Colors.white, size: 28),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getGuidanceTitle(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              Text(
                                _getGuidanceSubtitle(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_currentInteraction!.state ==
                            InteractionState.blinkDetected)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // =====================================================
          // VOICE CONTROL INDICATOR OVERLAY
          // =====================================================
          if (_inputMode == InputMode.voiceControl)
            const Positioned(bottom: 100, right: 30, child: VoiceIndicator()),

          // =====================================================
          // INPUT MODE SWITCH FAB (Floating Action Button style)
          // =====================================================
          Positioned(
            bottom: 30,
            right: 20,
            child: InputModeSwitch(
              selectedMode: _inputMode,
              onChanged: _handleInputModeChange,
            ),
          ),

          // =====================================================
          // EYE GAZE CURSOR OVERLAY (Moved to bottom for Z-Index)
          // =====================================================
          if (_inputMode == InputMode.eyeGaze)
            Positioned(
              left: _gazeX - (_isGazeStable ? 12 : 15),
              top: _gazeY - (_isGazeStable ? 12 : 15),
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isGazeStable ? 24 : 30,
                  height: _isGazeStable ? 24 : 30,
                  decoration: BoxDecoration(
                    color:
                        (_isGazeStable ? Colors.greenAccent : Colors.blueAccent)
                            .withOpacity(0.35),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isGazeStable
                          ? Colors.greenAccent
                          : Colors.blueAccent,
                      width: _isGazeStable ? 3 : 2,
                    ),
                    boxShadow: _isGazeStable
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _isGazeStable ? Colors.green : Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
        return QuestionContent(inputMode: _inputMode);
      case 4:
        return ProfileContent(
          userName: userName,
          disabilityType: disabilityType,
          inputMode: _inputMode,
        );
      default:
        return DashboardContent(inputMode: _inputMode);
    }
  }

  Color _getGuidanceColor() {
    switch (_currentInteraction?.state) {
      case InteractionState.hovering:
        return const Color(0xFF6E4BC6); // Purple
      case InteractionState.waitingConfirmation:
        return Colors.orange.shade800;
      case InteractionState.confirmed:
        return Colors.green.shade700;
      default:
        return Colors.blue;
    }
  }

  IconData _getGuidanceIcon() {
    switch (_currentInteraction?.state) {
      case InteractionState.hovering:
        return Icons.visibility_outlined;
      case InteractionState.waitingConfirmation:
        return Icons.ads_click; // Feedback for first click/blink
      case InteractionState.confirmed:
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  String _getGuidanceTitle() {
    switch (_currentInteraction?.state) {
      case InteractionState.hovering:
        return "තෝරා ගැනීමට ඇසිපිය හෙළන්න"; // Blink to select
      case InteractionState.waitingConfirmation:
        return "තහවුරු කිරීමට නැවත ඇසිපිය හෙළන්න"; // Blink again to confirm
      case InteractionState.confirmed:
        return "සාර්ථකව තෝරා ගන්නා ලදී"; // Successfully selected
      default:
        return "";
    }
  }

  String _getGuidanceSubtitle() {
    switch (_currentInteraction?.state) {
      case InteractionState.hovering:
        return "Blink once to select this item";
      case InteractionState.waitingConfirmation:
        return "Blink once more within 2 seconds...";
      case InteractionState.confirmed:
        return "Selection confirmed!";
      default:
        return "";
    }
  }
}
