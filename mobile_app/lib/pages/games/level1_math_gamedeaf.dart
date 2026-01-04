import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';

/// ✅ CHANGE THIS to your PC IP (same Wi-Fi)
const String kApiBaseUrl = "http://192.168.1.176:8000";

/// =======================
/// Question Model + Bank
/// =======================
class L1Question {
  final String text;
  final int answer; // 1..10
  const L1Question(this.text, this.answer);
}

class L1QuestionBank {
  static final _rng = Random();

  static L1Question randomQuestion() {
    final op = _rng.nextInt(4); // 0:+ 1:- 2:* 3:/

    if (op == 0) {
      final a = _rng.nextInt(10) + 1;
      final b = _rng.nextInt(10 - a + 1);
      final ans = a + b;
      return L1Question("$a + $b = ?", ans);
    }

    if (op == 1) {
      final a = _rng.nextInt(10) + 1;
      final b = _rng.nextInt(a);
      final ans = a - b;
      return L1Question("$a - $b = ?", ans);
    }

    if (op == 2) {
      const pairs = [
        [1, 1],[1, 2],[1, 3],[1, 4],[1, 5],[1, 6],[1, 7],[1, 8],[1, 9],[1, 10],
        [2, 1],[2, 2],[2, 3],[2, 4],[2, 5],
        [3, 1],[3, 2],[3, 3],
        [4, 1],[4, 2],
        [5, 1],[5, 2],
        [6, 1],[7, 1],[8, 1],[9, 1],[10, 1],
      ];
      final p = pairs[_rng.nextInt(pairs.length)];
      final a = p[0], b = p[1];
      final ans = a * b;
      return L1Question("$a × $b = ?", ans);
    }

    final ans = _rng.nextInt(10) + 1;
    final divisor = _rng.nextInt(9) + 1;
    final dividend = ans * divisor;
    return L1Question("$dividend ÷ $divisor = ?", ans);
  }

  static List<L1Question> buildLevel(int count) {
    final list = <L1Question>[];
    while (list.length < count) {
      list.add(randomQuestion());
    }
    return list;
  }
}

/// =======================
/// MAIN GAME PAGE
/// =======================
class Level1MathGameDeaf extends StatefulWidget {
  const Level1MathGameDeaf({super.key, required List<CameraDescription> cameras});

  @override
  State<Level1MathGameDeaf> createState() => _Level1MathGameDeafState();
}

class _Level1MathGameDeafState extends State<Level1MathGameDeaf> {
  final List<L1Question> _questions = L1QuestionBank.buildLevel(10);

  bool _started = false;
  int _index = 0;

  bool _checked = false;
  bool _isCorrect = false;
  int? _predicted;
  double? _confidence;
  String? _errorMsg;

  bool get _levelFinished => _index >= _questions.length;
  L1Question get _currentQ => _questions[_index];

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
          apiBaseUrl: kApiBaseUrl,
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
                          "මට්ටම 1",
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
                        "මට්ටම 1",
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
  String? _error;
  bool _sending = false;
  bool _isRecording = false;
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _error = "කැමරා අවසරය අවශ්‍යයි";
          _loading = false;
        });
        return;
      }

      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _error = "මෙම උපාංගයේ කැමරාවක් නොමැත";
          _loading = false;
        });
        return;
      }

      // ✅ FRONT camera for better self-recording
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      setState(() {
        _controller = controller;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = "කැමරාව ආරම්භ කිරීමට නොහැකි විය: $e";
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _sending = true;
      _error = null;
      _countdown = 3;
    });

    // Countdown
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _countdown = i - 1);
    }

    // Start recording
    try {
      setState(() => _isRecording = true);
      await _controller!.startVideoRecording();
      
      // Record for 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      
      final XFile video = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);

      final res = await _uploadToApi(videoPath: video.path);

      if (!mounted) return;
      Navigator.pop(context, res);
    } catch (e) {
      setState(() {
        _error = "$e";
        _sending = false;
        _isRecording = false;
      });
    }
  }

  Future<_CaptureResult> _uploadToApi({required String videoPath}) async {
    final uri = Uri.parse("${widget.apiBaseUrl}/api/hearing-impairment/predict-video");
    final req = http.MultipartRequest("POST", uri);

    final bytes = await File(videoPath).readAsBytes();

    req.files.add(
      http.MultipartFile.fromBytes(
        "video",
        bytes,
        filename: "capture.mp4",
        contentType: MediaType("video", "mp4"),
      ),
    );

    req.fields["expected"] = widget.expectedAnswer.toString();

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      return _CaptureResult(error: "API ${resp.statusCode}: ${resp.body}");
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      return _CaptureResult(error: "වලංගු නොවන ප්‍රතිචාරය");
    }

    final rawPred = decoded["prediction"];
    final int? predInt = (rawPred is int) ? rawPred : int.tryParse("$rawPred");

    final rawConf = decoded["confidence"];
    final double? conf = (rawConf is num) ? rawConf.toDouble() : double.tryParse("$rawConf");

    return _CaptureResult(
      prediction: predInt,
      confidence: conf,
      isCorrect: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF667EEA).withOpacity(0.15),
              const Color(0xFF764BA2).withOpacity(0.12),
              Colors.black.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _sending ? null : () => Navigator.pop(context),
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "සංඥාව පටිගත කරන්න",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "පිළිතුර: ?",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Camera Preview
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.videocam_off_rounded,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Color(0xFF6A11CB),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "ආපසු යන්න",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_controller != null)
                                CameraPreview(_controller!),
                              if (_sending && !_isRecording)
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _countdown > 0 ? "$_countdown" : "🎬",
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_isRecording)
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.fiber_manual_record,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),

              // Controls
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                ),
                child: Column(
                  children: [
                    if (!_sending)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _startCountdown,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
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
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "පටිගත කරන්න",
                                    style: TextStyle(
                                      fontSize: 20,
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
                    if (_sending)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: _isRecording
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.fiber_manual_record,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "පටිගත වෙමින්...",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  "යොමු කරමින්...",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_rounded,
                                  size: 18, color: Colors.yellow),
                              SizedBox(width: 8),
                              Text(
                                "උපදෙස්:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• ඔබගේ අත පැහැදිලිව දක්වන්න\n"
                            "• ආලෝකය යහපත් අයුරින් ඇති බවට වග බලා ගන්න\n"
                            "• පසුබිම සරලව තබා ගන්න",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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