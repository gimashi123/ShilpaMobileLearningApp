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
import 'package:mobile_app/components/gaze_cursor.dart';
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
  bool _isCalibrated = false;
  OverlayEntry? _interactionOverlay;

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

    final bool needsGaze =
        (mode == InputMode.eyeGaze || mode == InputMode.hybrid);

    // If switching TO a Gaze-based mode and not calibrated, go to calibration
    if (needsGaze && !_isCalibrated) {
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
        if (mode == InputMode.hybrid) _startVoiceControl();
      } else {
        // User cancelled or failed calibration
        return;
      }
    } else {
      setState(() => _inputMode = mode);

      if (mode == InputMode.eyeGaze) {
        _startGazeTracking();
      } else if (mode == InputMode.voiceControl) {
        _startVoiceControl();
      } else if (mode == InputMode.hybrid) {
        _startGazeTracking();
        _startVoiceControl();
      }
    }
  }

  void _startGazeTracking() async {
    await _eyeTrackingService.startTracking();
    _gazeSubscription?.cancel();
    _gazeSubscription = _eyeTrackingService.gazeStream.listen((data) {});

    // Show Global Interaction Overlay (Cursor + Voice indicator)
    _showInteractionOverlay();
  }

  void _showInteractionOverlay() {
    _hideInteractionOverlay();
    _interactionOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          const GazeCursor(),
          if (_inputMode == InputMode.voiceControl ||
              _inputMode == InputMode.hybrid)
            const Positioned(bottom: 100, right: 30, child: VoiceIndicator()),
        ],
      ),
    );
    Overlay.of(context).insert(_interactionOverlay!);
  }

  void _hideInteractionOverlay() {
    _interactionOverlay?.remove();
    _interactionOverlay = null;
  }

  void _stopGazeTracking() async {
    _hideInteractionOverlay();
    _gazeSubscription?.cancel();
    _gazeSubscription = null;
    await _eyeTrackingService.stopTracking();
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
    if (_inputMode == InputMode.voiceControl ||
        _inputMode == InputMode.hybrid) {
      SpeechService.instance.stopListening();
    }
  }

  void _processVoiceCommand(String text) {
    print("Voice Heard: $text");
    final command = VoiceCommandParser.parse(text);

    // Broadcast the command to the global interaction bus
    // This allows components (like InputAwareButton) to react to "Select"
    // while being hovered by gaze.
    InteractionStatusService().emitVoiceCommand(command);

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

        // --- Interaction Fusion Commands ---
        case VoiceCommand.select:
        case VoiceCommand.confirm:
          // These are primarily handled by focused components via the stream.
          // We can provide a brief global confirmation feedback here.
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

    // Show feedback snackbar for navigation/mode commands
    if (command != VoiceCommand.unknown &&
        command != VoiceCommand.select &&
        command != VoiceCommand.confirm) {
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
          if ((_inputMode == InputMode.eyeGaze ||
                  _inputMode == InputMode.hybrid) &&
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
          // Handled by _interactionOverlay (OverlayEntry)

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
          // Cursor is now handled by _cursorOverlay (OverlayEntry)
          // ensuring it stays visible on top of any pushed routes.
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
        return _inputMode == InputMode.hybrid
            ? "තෝරා ගැනීමට කියන්න හෝ ඇසිපිය හෙළන්න" // Say or Blink to select
            : "තෝරා ගැනීමට ඇසිපිය හෙළන්න";
      case InteractionState.waitingConfirmation:
        return "තහවුරු කිරීමට නැවත ඇසිපිය හෙළන්න";
      case InteractionState.confirmed:
        return "සාර්ථකව තෝරා ගන්නා ලදී";
      default:
        return "";
    }
  }

  String _getGuidanceSubtitle() {
    switch (_currentInteraction?.state) {
      case InteractionState.hovering:
        return _inputMode == InputMode.hybrid
            ? "Say 'Select' or Blink to confirm this item"
            : "Blink once to select this item";
      case InteractionState.waitingConfirmation:
        return "Blink once more within 2 seconds...";
      case InteractionState.confirmed:
        return "Selection confirmed!";
      default:
        return "";
    }
  }
}
