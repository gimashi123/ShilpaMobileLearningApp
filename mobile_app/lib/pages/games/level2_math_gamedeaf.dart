import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/AppConfig.dart';



/// =======================
/// Question Model + Bank
/// =======================
class L2Question {
  final String text;
  final int answer; // 11..20
  const L2Question(this.text, this.answer);
}
class L2QuestionBank {

  static final _rng = Random();

  static L2Question randomQuestion() {

    final op = _rng.nextInt(3); // 0:+ 1:- 2:*

    // ------------------
    // ADDITION
    // ------------------
    if (op == 0) {

      final ans = _rng.nextInt(10) + 11; // 11..20
      final a = _rng.nextInt(ans - 1) + 1;
      final b = ans - a;

      return L2Question("$a + $b = ?", ans);
    }

    // ------------------
    // SUBTRACTION
    // ------------------
    if (op == 1) {

      final ans = _rng.nextInt(10) + 11; // 11..20
      final b = _rng.nextInt(9) + 1;
      final a = ans + b;

      return L2Question("$a - $b = ?", ans);
    }

    // ------------------
    // MULTIPLICATION
    // ------------------

    const pairs = [
      [3,4], [3,5], [3,6],
      [4,3], [4,4], [4,5],
      [5,3], [5,4],
      [6,2], [7,2], [8,2], [9,2], [10,2]
    ];

    final p = pairs[_rng.nextInt(pairs.length)];

    final a = p[0];
    final b = p[1];
    final ans = a * b;

    if (ans >= 11 && ans <= 20) {
      return L2Question("$a × $b = ?", ans);
    }

    return randomQuestion();
  }

  static List<L2Question> buildLevel(int count) {

    final list = <L2Question>[];

    while (list.length < count) {
      list.add(randomQuestion());
    }

    return list;
  }
}

/// =======================
/// MAIN GAME PAGE
/// =======================
class Level2MathGameDeaf extends StatefulWidget {
  const Level2MathGameDeaf({super.key, required List<CameraDescription> cameras});

  @override
  State<Level2MathGameDeaf> createState() => _Level2MathGameDeafState();
}

class _Level2MathGameDeafState extends State<Level2MathGameDeaf> {
  final List<L2Question> _questions = L2QuestionBank.buildLevel(10);

  bool _started = false;
  int _index = 0;

  bool _checked = false;
  bool _isCorrect = false;
  int? _predicted;
  double? _confidence;
  String? _errorMsg;

  bool get _levelFinished => _index >= _questions.length;
  L2Question get _currentQ => _questions[_index];

  void _resetForNextQuestion() {
    _checked = false;
    _isCorrect = false;
    _predicted = null;
    _confidence = null;
    _errorMsg = null;
  }

  void _startLevel() {
    setState(() {
      _started = true;
      _index = 0;
      _resetForNextQuestion();
    });
  }

  void _goNext() {
    if (!_checked || !_isCorrect) return;
    setState(() {
      _index++;
      if (!_levelFinished) _resetForNextQuestion();
    });
  }

  Future<void> _checkUsingSign() async {
    setState(() => _errorMsg = null);

    final expected = _currentQ.answer;

    final result = await Navigator.push<_CaptureResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureSignPage(
          expectedAnswer: expected,
          apiBaseUrl: AppConfig.apiBaseUrl,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _checked = true;

      if (result.error != null) {
        _errorMsg = result.error;
        _isCorrect = false;
        _predicted = null;
        _confidence = null;
        return;
      }

      _predicted = result.prediction;
      _confidence = result.confidence;

      // ✅ CORRECT MATH CONNECTION (don't trust API success flag)
      _isCorrect = (result.prediction != null && result.prediction == expected);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF667EEA).withOpacity(0.15),
                const Color(0xFF764BA2).withOpacity(0.12),
                const Color(0xFFFFF8E1).withOpacity(0.95),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                    Column(
                    children: [
                      Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home_hearing',
                        (route) => false,
                        ),
                        icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color.fromARGB(255, 18, 18, 18),
                          size: 35,
                        ),
                        ),
                      ),
                      ),
                      Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                        colors: [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
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
                        children: [
                        const Icon(
                          Icons.games_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "ගණිත අභියෝගය",
                          style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                            blurRadius: 4,
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            ),
                          ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "මට්ටම 2",
                          style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        ],
                      ),
                      ),
                    ],
                    ),
                  const SizedBox(height: 32),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.touch_app, color: Color(0xFF6A11CB)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "ඔබගේ අත්සනෙන් පිළිතුරු දෙන්න",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D1B69),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionItem("1", "ගණිත ප්‍රශ්නයක් දක්වනු ඇත"),
                        const SizedBox(height: 12),
                        _buildInstructionItem("2", "වීඩියෝ කැමරාව විවෘත කරන්න"),
                        const SizedBox(height: 12),
                        _buildInstructionItem("3", "අංකය සංඥා භාෂාවෙන් පෙන්වන්න"),
                        const SizedBox(height: 12),
                        _buildInstructionItem("4", "පිළිතුර පරීක්ෂා කර ඊළඟට යන්න"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Start Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B00FF).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: _startLevel,
                        borderRadius: BorderRadius.circular(18),
                        splashColor: Colors.white.withOpacity(0.3),
                        highlightColor: Colors.white.withOpacity(0.2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "පටන් ගන්න",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "ප්‍රශ්න 10ක්",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_levelFinished) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF11998E).withOpacity(0.15),
                const Color(0xFF38EF7D).withOpacity(0.12),
                const Color(0xFFFFF8E1).withOpacity(0.95),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Trophy
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "සුභ පැතුම්! 🎉",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D1B69),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "ඔබ මට්ටම 1 සම්පූර්ණ කළා",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.deepPurple.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ප්‍රශ්න ${_questions.length}ක්ම නිවැරදියි",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => setState(() => _started = false),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.replay_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "නැවත උත්සාහ කරන්න",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.home_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "මුල් පිටුව",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final q = _currentQ;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF667EEA).withOpacity(0.15),
              const Color(0xFF764BA2).withOpacity(0.12),
              const Color(0xFFFFF8E1).withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Progress Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    ),
                  ],
                  ),
                  child: Row(
                  children: [
                    IconButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home_hearing',
                      (route) => false,
                    ),
                    icon: Container(
                      decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF2D1B69),
                      size: 24,
                      ),
                    ),
                    ),
                    Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        "මට්ටම 2",
                        style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        "ප්‍රශ්න ${_index + 1} / ${_questions.length}",
                        style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D1B69),
                        ),
                      ),
                      ],
                    ),
                    ),
                    Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      "${(_index / _questions.length * 100).toInt()}%",
                      style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1976D2),
                      ),
                    ),
                    ),
                  ],
                  ),
                ),
                const SizedBox(height: 24),

                // Question Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.question_mark_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "ගණිත ප්‍රශ්නය",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        q.text,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black26,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white30, height: 20),
                      const Text(
                        "අංකය සංඥා භාෂාවෙන් පෙන්වන්න",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Result Area
                Expanded(
                  child: _buildResultArea(expected: q.answer),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _checkUsingSign,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.videocam_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "සංඥාවෙන් පරීක්ෂා කරන්න",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_checked && _isCorrect)
                                ? const Color(0xFF4CAF50).withOpacity(0.4)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: (_checked && _isCorrect) ? _goNext : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: (_checked && _isCorrect)
                                  ? const LinearGradient(
                                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.shade400,
                                        Colors.grey.shade500,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "ඊළඟ",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_checked || !_isCorrect)
                  Text(
                    "නිවැරදි පිළිතුරක් අවශ්‍යයි",
                    style: TextStyle(
                      color: Colors.red.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2D1B69),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultArea({required int expected}) {
    if (_errorMsg != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              "දෝෂයක් ඇති විය",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (!_checked) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.1),
                width: 4,
              ),
            ),
            child: const Icon(
              Icons.back_hand_rounded,
              size: 60,
              color: Color(0xFF6A11CB),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "ඔබගේ සංඥාව පරීක්ෂා කරන්න",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "පිළිතුර: ?",
            style: TextStyle(
              fontSize: 18,
              color: Colors.deepPurple.withOpacity(0.7),
            ),
          ),
        ],
      );
    }

    if (_isCorrect) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "නිවැරදියි! ✅",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black26,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "අපේක්ෂිත:",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        "$expected",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "හඳුනාගත්තේ:",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        "${_predicted ?? "-"}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_confidence != null)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "විශ්වාසනීයත්වය:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        "${(_confidence! * 100).toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: _confidence!.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Icon(
              Icons.cancel_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "වැරදියි! ❌",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black26,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "අපේක්ෂිත පිළිතුර:",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      "$expected",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ඔබ පෙන්වූයේ:",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      "${_predicted ?? "-"}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_confidence != null)
            Text(
              "විශ්වාසනීයත්වය: ${(_confidence! * 100).toStringAsFixed(1)}%",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Text(
              "නැවත උත්සාහ කරන්න. ඔබට පුළුවන්! 💪",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// CAPTURE PAGE (CAMERA) - RECORD 3s VIDEO
/// =======================
class CaptureSignPage extends StatefulWidget {
  final int expectedAnswer;
  final String apiBaseUrl;

  const CaptureSignPage({
    super.key,
    required this.expectedAnswer,
    required this.apiBaseUrl,
  });

  @override
  State<CaptureSignPage> createState() => _CaptureSignPageState();
}

class _CaptureSignPageState extends State<CaptureSignPage> {
  CameraController? _controller;

  bool _loading = true;
  bool _sending = false;
  bool _isRecording = false;

  String? _error;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// --------------------------------
  /// Initialize Camera
  /// --------------------------------
  Future<void> _initCamera() async {
    try {
      final permission = await Permission.camera.request();

      if (!permission.isGranted) {
        setState(() {
          _error = "Camera permission required";
          _loading = false;
        });
        return;
      }

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _error = "No camera available";
          _loading = false;
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = "Camera init failed: $e";
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// --------------------------------
  /// Countdown → Record → Upload
  /// --------------------------------
  Future<void> _startCountdown() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _sending = true;
      _countdown = 3;
      _error = null;
    });

    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    try {
      setState(() {
        _isRecording = true;
        _countdown = 0;
      });

      await Future.delayed(const Duration(milliseconds: 300));
      await _controller!.startVideoRecording();
      await Future.delayed(const Duration(seconds: 4));

      final XFile video = await _controller!.stopVideoRecording();

      setState(() => _isRecording = false);

      await Future.delayed(const Duration(milliseconds: 300));

      final result = await _uploadVideo(video.path);

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _sending = false;
        _isRecording = false;
      });
    }
  }

  /// --------------------------------
  /// Upload Video to API
  /// --------------------------------
  Future<_CaptureResult> _uploadVideo(String videoPath) async {
    // ✅ Mobile app goes via the Node.js backend → /api/models/...
    final uri = Uri.parse(
      "${widget.apiBaseUrl}/api/models/hearing-impairment/predict-video",
    );

    try {
      final request = http.MultipartRequest("POST", uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          "video",
          videoPath,
          contentType: MediaType("video", "mp4"),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        return _CaptureResult(error: "API error ${response.statusCode}");
      }

      final decoded = jsonDecode(response.body);

      final rawPred = decoded["prediction"];
      final int? prediction =
          rawPred is int ? rawPred : int.tryParse("$rawPred");

      final rawConf = decoded["confidence"];
      final double? confidence =
          rawConf is num ? rawConf.toDouble() : double.tryParse("$rawConf");

      return _CaptureResult(
        prediction: prediction,
        confidence: confidence,
      );
    } catch (e) {
      return _CaptureResult(error: e.toString());
    }
  }

  /// --------------------------------
  /// UI
  /// --------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.deepPurple,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Record Sign",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Answer: ${widget.expectedAnswer}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            /// CAMERA PREVIEW
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            CameraPreview(_controller!),

                            // countdown overlay
                            if (_sending && !_isRecording)
                              Container(
                                width: 120,
                                height: 120,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _countdown > 0 ? "$_countdown" : "🎬",
                                    style: const TextStyle(
                                      fontSize: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                            // recording indicator
                            if (_isRecording)
                              const Icon(
                                Icons.fiber_manual_record,
                                color: Colors.red,
                                size: 70,
                              ),
                          ],
                        ),
            ),

            /// RECORD BUTTON
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _startCountdown,
                icon: const Icon(Icons.videocam),
                label: const Text(
                  "Record Sign",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// result returned back to game page
class _CaptureResult {
  final int? prediction;
  final double? confidence;
  final bool? isCorrect;
  final String? error;

  _CaptureResult({
    this.prediction,
    this.confidence,
    this.isCorrect,
    this.error,
  });
}