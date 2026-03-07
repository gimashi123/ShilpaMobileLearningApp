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

      // Grade 4-5 level addition/subtraction
      _leftValue = _random.nextInt(20) + 1;
      _rightValue = _random.nextInt(20) + 1;
      _operator = '+'; // Keep it simple for now as requested
      _totalSum = _leftValue! + _rightValue!;

      // Decide which one is missing (either left, right, or total)
      // For the balance scale, let's put equation on one side, result on other.
      // E.g. 7 + [] = 15 or [] + 8 = 15
      int sideToHide = _random.nextInt(2); // 0 or 1
      if (sideToHide == 0) {
        _missingValue = _leftValue;
        _leftValue = null;
      } else {
        _missingValue = _rightValue;
        _rightValue = null;
      }

      // Generate 4 options
      _options = [_missingValue!];
      while (_options.length < 5) {
        int opt = _random.nextInt(30) + 1;
        if (!_options.contains(opt)) {
          _options.add(opt);
        }
      }
      _options.shuffle();
    });

    // Tilt the scale to the left (result side is heavier initially)
    _rotationController.animateTo(1.0);
  }

  void _handleOptionSelection(int value) {
    if (_isSuccess) return;
    setState(() {
      _selectedValue = value;
    });
    // Feedback: Selected number might scale up or glow
  }

  void _handlePlaceValue() {
    if (_selectedValue == null || _isSuccess) return;

    setState(() {
      _placedValue = _selectedValue;
      if (_placedValue == _missingValue) {
        _isSuccess = true;
        _selectedValue = null;
        // Balance the scale
        _rotationController.animateTo(0.5); // Center
        _showSuccessAnimation();
      } else {
        // Wrong answer feedback
        // Tilt more to the "wrong" side? Or just flash red
        _shakeScale();
      }
    });
  }

  void _shakeScale() {
    // Visual feedback for wrong answer
    _rotationController
        .animateTo(1.0, duration: const Duration(milliseconds: 100))
        .then(
          (_) => _rotationController.animateTo(
            0.8,
            duration: const Duration(milliseconds: 100),
          ),
        )
        .then(
          (_) => _rotationController.animateTo(
            1.0,
            duration: const Duration(milliseconds: 100),
          ),
        );
  }

  void _showSuccessAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: const Color(0xFFE8F5E9),
        title: const Center(
          child: Text(
            "ඉතා හොඳයි! (Well Done!)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 24,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              "$_totalSum = ${(_leftValue ?? _placedValue)} $_operator ${(_rightValue ?? _placedValue)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Center(
            child: InputAwareButton(
              onTap: () {
                Navigator.pop(context);
                _generateLevel();
              },
              inputMode: widget.inputMode,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "ඊළඟ අභියෝගය", // Next Challenge
                  style: TextStyle(
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
