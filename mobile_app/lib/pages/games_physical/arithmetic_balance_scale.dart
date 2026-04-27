import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/input_modes.dart';
import '../../components/input_aware_button.dart';

/// Arithmetic Balance Scale Game
/// Designed for Grade 4-5 students to practice mental arithmetic and early algebra.
/// Optimized for Eye Gaze, Dwell, and Voice input.
class ArithmeticBalanceScale extends StatefulWidget {
  final InputMode inputMode;

  const ArithmeticBalanceScale({super.key, required this.inputMode});

  @override
  State<ArithmeticBalanceScale> createState() => _ArithmeticBalanceScaleState();
}

class _ArithmeticBalanceScaleState extends State<ArithmeticBalanceScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _scaleRotation;

  // Game State
  int _currentLevel = 1;
  static const int _totalLevels = 5;
  int _correctAttempts = 0;
  int _totalAttempts = 0;

  int? _leftValue;
  String? _operator;
  int? _rightValue;
  int? _totalSum;
  int? _missingValue; // The value that should be in the box
  int? _selectedValue; // Currently selected number from options
  int? _placedValue; // Value placed in the box
  bool _isSuccess = false;
  List<int> _options = [];

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleRotation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _generateLevel();
  }

  void _generateLevel() {
    setState(() {
      _placedValue = null;
      _selectedValue = null;
      _isSuccess = false;

      // Difficulty increases with levels
      int maxVal = 10 + (_currentLevel * 5);

      // Decide operator: Levels 1-2 (+) , 3-5 (+ or -)
      if (_currentLevel <= 2) {
        _operator = '+';
        _leftValue = _random.nextInt(maxVal) + 5;
        _rightValue = _random.nextInt(maxVal) + 5;
        _totalSum = _leftValue! + _rightValue!;
      } else {
        _operator = _random.nextBool() ? '+' : '-';
        if (_operator == '+') {
          _leftValue = _random.nextInt(maxVal) + 5;
          _rightValue = _random.nextInt(maxVal) + 5;
          _totalSum = _leftValue! + _rightValue!;
        } else {
          // Ensure positive result for subtraction
          _totalSum = _random.nextInt(maxVal) + 5;
          _leftValue = _totalSum! + _random.nextInt(maxVal) + 1;
          _rightValue = _leftValue! - _totalSum!;
        }
      }

      // Decide which one is missing
      int sideToHide = _random.nextInt(2);
      if (sideToHide == 0) {
        _missingValue = _leftValue;
        _leftValue = null;
      } else {
        _missingValue = _rightValue;
        _rightValue = null;
      }

      // Generate 5 options
      _options = [_missingValue!];
      while (_options.length < 5) {
        int opt = _random.nextInt(maxVal * 2) + 1;
        if (!_options.contains(opt)) {
          _options.add(opt);
        }
      }
      _options.shuffle();
    });

    // Tilt the scale to the left (result side is heavier initially)
    _rotationController.animateTo(1.0);
  }

  void _handleOptionSelection(int value, {bool isVoice = false}) {
    if (_isSuccess) return;
    setState(() {
      _selectedValue = value;
    });

    // AUTO-SLOTTING: If selected via voice, automatically try to place it
    if (isVoice ||
        widget.inputMode == InputMode.voiceControl ||
        widget.inputMode == InputMode.hybrid) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _selectedValue == value) {
          _handlePlaceValue();
        }
      });
    }
  }

  void _handlePlaceValue() {
    if (_selectedValue == null || _isSuccess) return;

    setState(() {
      _totalAttempts++;
      _placedValue = _selectedValue;
      if (_placedValue == _missingValue) {
        _isSuccess = true;
        _correctAttempts++;
        _selectedValue = null;
        _rotationController.animateTo(0.5); // Balance
        _showLevelResultDialog(true);
      } else {
        // Wrong answer: lock it and show result
        _isSuccess = true; // Prevents further changes to this level
        _selectedValue = null;
        _rotationController.animateTo(1.0); // Keep it tilted
        _showLevelResultDialog(false);
      }
    });
  }

  void _showLevelResultDialog(bool isCorrect) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    bool isGameFinished = _currentLevel >= _totalLevels;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: isCorrect
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        title: Center(
          child: Text(
            isCorrect
                ? (isGameFinished
                      ? "අභියෝගය අවසන්! (Finished!)"
                      : "ඉතා හොඳයි! (Well Done!)")
                : "නැවත උත්සාහ කරමු! (Nice Try!)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
              fontSize: 24,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect
                  ? (isGameFinished ? Icons.emoji_events : Icons.star)
                  : Icons.sentiment_dissatisfied,
              size: 80,
              color: isCorrect ? Colors.orange : Colors.redAccent,
            ),
            const SizedBox(height: 20),
            Text(
              isCorrect ? "නිවැරදි පිළිතුර:" : "නිවැරදි පිළිතුර වන්නේ:",
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
            Text(
              "$_totalSum = ${(_leftValue ?? _missingValue)} $_operator ${(_rightValue ?? _missingValue)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (!isGameFinished)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(
                  "මට්ටම: $_currentLevel / $_totalLevels",
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ),
          ],
        ),
        actions: [
          Center(
            child: InputAwareButton(
              onTap: () {
                Navigator.pop(context);
                if (isGameFinished) {
                  _showProgressReport();
                } else {
                  setState(() {
                    _currentLevel++;
                  });
                  _generateLevel();
                }
              },
              inputMode: widget.inputMode,
              voiceLabel: isGameFinished ? "අවසන්" : "ඊළඟ",
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: isGameFinished
                      ? Colors.blue
                      : (isCorrect ? Colors.green : Colors.orange),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  isGameFinished ? "ප්‍රගති වාර්තාව බලන්න" : "ඊළඟ අභියෝගය",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showProgressReport() {
    double accuracy = (_totalAttempts > 0)
        ? (_correctAttempts / _totalAttempts) * 100
        : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "ක්‍රීඩා ප්‍රගතිය", // Game Progress
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4527A0),
              ),
            ),
            const Divider(),
            const SizedBox(height: 20),
            _buildStatRow(
              "නිවැරදි පිළිතුරු",
              "$_correctAttempts / $_totalLevels",
              Colors.green,
            ),
            _buildStatRow("මුළු උත්සාහයන්", "$_totalAttempts", Colors.orange),
            _buildStatRow(
              "නිවැරදි ප්‍රතිශතය",
              "${accuracy.toStringAsFixed(1)}%",
              Colors.blue,
            ),
            const SizedBox(height: 30),
            InputAwareButton(
              onTap: () => Navigator.pop(context),
              inputMode: widget.inputMode,
              voiceLabel: "ඉවත් වන්න",
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4527A0),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "අහවරයි", // Finished/Done
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => Navigator.pop(context)); // Return to main menu
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Parent provides background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "තැරාදිය සමබර කරමු", // Let's balance the scale
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4527A0),
                    ),
                  ),
                  Text(
                    "හිස් කොටුවට ගැලපෙන අගය තෝරා තැරාදිය මත තබන්න", // Choose matching value and place on scale
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF4527A0).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Game Area (Scale)
            Expanded(
              flex: 5,
              child: Center(
                child: AnimatedBuilder(
                  animation: _scaleRotation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _scaleRotation.value,
                      child: _buildScaleUI(),
                    );
                  },
                ),
              ),
            ),

            // Options Area
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "අගයන් තෝරන්න (Select Value)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: _options
                            .map((val) => _buildOptionCard(val))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Scale Beam
        Container(
          width: 320,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),

        // The Buckets/Pans
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left Pan (Result Side)
            _buildPan(
              child: Text(
                "$_totalSum",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4527A0),
                ),
              ),
              label: "මුළු එකතුව", // Total Sum
              color: Colors.blue.shade100,
            ),

            const SizedBox(width: 80),

            // Right Pan (Equation Side)
            _buildPan(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _leftValue == null
                      ? _buildTargetBox()
                      : _buildValueCard(_leftValue!),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _operator ?? "+",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  _rightValue == null
                      ? _buildTargetBox()
                      : _buildValueCard(_rightValue!),
                ],
              ),
              label: "සමීකරණය", // Equation
              color: Colors.orange.shade100,
              isTarget: true,
            ),
          ],
        ),

        // Scale Base (Not rotated)
        // We handle this by nesting inside another column outside the rotation if needed,
        // but for "kids theme" simple is better.
      ],
    );
  }

  Widget _buildPan({
    required Widget child,
    required String label,
    required Color color,
    bool isTarget = false,
  }) {
    return Column(
      children: [
        // Ropes
        Container(width: 2, height: 40, color: Colors.grey.shade600),

        // Pan
        Container(
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(60),
            ),
            border: Border.all(color: Colors.black26, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetBox() {
    return InputAwareButton(
      onTap: _handlePlaceValue,
      inputMode: widget.inputMode,
      showVoiceIndex: false,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _placedValue != null
              ? (_isSuccess ? Colors.green.shade100 : Colors.red.shade100)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedValue != null ? Colors.blue : Colors.black26,
            width: _selectedValue != null ? 3 : 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: _placedValue != null
              ? Text(
                  "$_placedValue",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Icon(Icons.help_outline, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildValueCard(int val) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Center(
        child: Text(
          "$val",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildOptionCard(int value) {
    bool isSelected = _selectedValue == value;
    return InputAwareButton(
      onTap: () => _handleOptionSelection(value),
      inputMode: widget.inputMode,
      voiceLabel: value.toString(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7E57C2) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.purple.withOpacity(0.4)
                  : Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "$value",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
