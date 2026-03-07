import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/input_modes.dart';
import '../../components/input_aware_button.dart';

/// Sinhala Noun vs Verb Sorting Game (නාමපද සහ ක්‍රියාපද)
/// Designed for Grade 4-5 students to practice Sinhala grammar.
/// Optimized for Eye Gaze, Dwell, and Voice input.
class SinhalaWordSorter extends StatefulWidget {
  final InputMode inputMode;

  const SinhalaWordSorter({super.key, required this.inputMode});

  @override
  State<SinhalaWordSorter> createState() => _SinhalaWordSorterState();
}

class _SinhalaWordSorterState extends State<SinhalaWordSorter> {
  // Game Categories
  static const String categoryNoun = "නාමපද"; // Nouns
  static const String categoryVerb = "ක්‍රියාපද"; // Verbs

  // Word Data
  final List<Map<String, String>> _allWords = [
    {"word": "අම්මා", "type": categoryNoun},
    {"word": "පොත", "type": categoryNoun},
    {"word": "පාසල", "type": categoryNoun},
    {"word": "අලියා", "type": categoryNoun},
    {"word": "ගස", "type": categoryNoun},
    {"word": "පෑන", "type": categoryNoun},
    {"word": "දුවනවා", "type": categoryVerb},
    {"word": "කනවා", "type": categoryVerb},
    {"word": "බොනවා", "type": categoryVerb},
    {"word": "ලියනවා", "type": categoryVerb},
    {"word": "බලනවා", "type": categoryVerb},
    {"word": "නානවා", "type": categoryVerb},
    {"word": "මල්", "type": categoryNoun},
    {"word": "සිනාසෙනවා", "type": categoryVerb},
    {"word": "පනිනවා", "type": categoryVerb},
    {"word": "අහස", "type": categoryNoun},
  ];

  // Game State
  late Map<String, String> _currentWord;
  String? _selectedCategory; // User's selection (for picked word)
  bool _isSuccess = false;
  int _score = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateNewWord();
  }

  void _generateNewWord() {
    setState(() {
      _currentWord = _allWords[_random.nextInt(_allWords.length)];
      _isSuccess = false;
      _selectedCategory = null;
    });
  }

  void _handleSort(String category) {
    if (_isSuccess) return;

    setState(() {
      _selectedCategory = category;
      if (category == _currentWord['type']) {
        _isSuccess = true;
        _score += 10;
        _showSuccessDialog();
      } else {
        // Wrong answer feedback
        _showFailureFeedback();
      }
    });
  }

  void _showFailureFeedback() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "නැවත උත්සාහ කරන්න! (Try Again!)",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(bottom: 100, left: 50, right: 50),
      ),
    );
  }

  void _showSuccessDialog() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: const Color(0xFFF1F8E9),
        title: Center(
          child: Column(
            children: [
              const Icon(Icons.stars, size: 70, color: Colors.amber),
              const SizedBox(height: 10),
              Text(
                "'${_currentWord['word']}' යනු ${_currentWord['type']}කි", // word is a type
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        content: const Text(
          "ඉතා හොඳයි! ඔබ නිවැරදිව තෝරා ගත්තා.", // Very good! You chose correctly.
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Center(
            child: InputAwareButton(
              onTap: () {
                Navigator.pop(context);
                _generateNewWord();
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "ඊළඟ වචනය", // Next word
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Score Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        "ලකුණු: $_score", // Score
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const Text(
                      "වචන බෙදමු", // Let's sort words
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Word Card to Sort
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "මෙම වචනය කුමන වර්ගයට අයත්ද?", // To which type does this word belong?
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 30,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF6A1B9A),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6A1B9A).withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          _currentWord['word']!,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4A148C),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Target Bins
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    // Noun Bin
                    Expanded(
                      child: _buildBin(
                        label: categoryNoun,
                        icon: Icons.person_outline,
                        color: Colors.blue.shade400,
                        onTap: () => _handleSort(categoryNoun),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Verb Bin
                    Expanded(
                      child: _buildBin(
                        label: categoryVerb,
                        icon: Icons.directions_run,
                        color: Colors.orange.shade400,
                        onTap: () => _handleSort(categoryVerb),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBin({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InputAwareButton(
      onTap: onTap,
      inputMode: widget.inputMode,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 15),
            Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "මෙහි තබන්න", // Place here
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
