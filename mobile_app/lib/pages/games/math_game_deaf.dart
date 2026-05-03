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
import '../../services/sign_game_api.dart';
import '../../session/session.dart';

/// =======================
/// Unified Question Model + Bank (Levels 1, 2, 4)
/// =======================
class MathQuestion {
  final String text;
  final int answer;
  const MathQuestion(this.text, this.answer);
}

class QuestionBank {
  static final _rng = Random();

  /// Detects the level based on the answer to send to the backend
  static int detectLevel(int answer) {
    if (answer >= 1 && answer <= 10) return 1;
    if (answer >= 11 && answer <= 20) return 2;
    // Level 3 omitted for mobile (21-44)
    if (answer >= 75 && answer <= 100) return 4;
    return 1; // Fallback
  }

  /// Dynamically generates a math question whose answer is always in [1, 10].
  /// Uses addition, subtraction, and multiplication with randomised operands
  /// so that no two rounds feel the same.
  static MathQuestion randomQuestion({int difficultyLevel = 1}) {
    // Pick an answer first, then build the question around it
    final answer = _rng.nextInt(10) + 1; // 1..10
    final op = _rng.nextInt(3); // 0: +, 1: -, 2: ×

    if (difficultyLevel == 2) {
      // Level 2: Harder operands (10-20) but answer is still 1-10
      if (op == 0) {
        // Addition: small + small = answer
        final a = _rng.nextInt(answer) + 1;
        final b = answer - a;
        return MathQuestion("$a + $b = ?", answer);
      } else if (op == 1) {
        // Subtraction: a - b = answer, where a is between 11-20
        final b = _rng.nextInt(10) + 1; // 1..10
        final a = answer + b; // Will be between 2..20
        return MathQuestion("$a - $b = ?", answer);
      } else {
        // Division (instead of multiplication) for Level 2
        // a / b = answer => a = answer * b
        final b = _rng.nextInt(3) + 2; // 2..4 (small divisors)
        final a = answer * b;
        return MathQuestion("$a ÷ $b = ?", answer);
      }
    } else {
      // Level 1: Basic
      if (op == 0) {
        // Addition: a + b = answer, where a >= 1
        final a = _rng.nextInt(answer) + 1; // 1..answer
        final b = answer - a;
        return MathQuestion("$a + $b = ?", answer);
      } else if (op == 1) {
        // Subtraction: a - b = answer, where b >= 0, a <= 20
        final b = _rng.nextInt(11); // 0..10
        final a = answer + b;
        return MathQuestion("$a - $b = ?", answer);
      } else {
        // Multiplication: a × b = answer (pick a valid factor pair)
        final factors = <List<int>>[];
        for (int f = 1; f <= answer; f++) {
          if (answer % f == 0) factors.add([f, answer ~/ f]);
        }
        final pair = factors[_rng.nextInt(factors.length)];
        return MathQuestion("${pair[0]} × ${pair[1]} = ?", answer);
      }
    }
  }

  static List<MathQuestion> buildLevel(int count, {int difficultyLevel = 1}) {
    final list = <MathQuestion>[];
    while (list.length < count) {
      list.add(randomQuestion(difficultyLevel: difficultyLevel));
    }
    return list;
  }
}

/// =======================
/// MAIN GAME PAGE
/// =======================
class MathGameDeaf extends StatefulWidget {
  const MathGameDeaf({super.key, required List<CameraDescription> cameras});

  @override
  State<MathGameDeaf> createState() => _MathGameDeafState();
}

class _MathGameDeafState extends State<MathGameDeaf> {
  List<MathQuestion> _questions = [];
  final List<MathQuestion> _wrongQuestions = [];
  final List<Map<String, dynamic>> _questionHistory = [];

  /// Track how many times each question has been retried (max 2 retries)
  final Map<MathQuestion, int> _retryCount = {};

  bool _started = false;
  int _index = 0;
  int _difficultyLevel = 1;
  bool _isLoadingLevel = false;

  bool _checked = false;
  bool _isCorrect = false;
  int? _predicted;
  double? _confidence;
  String? _errorMsg;

  bool get _levelFinished => _index >= _questions.length;
  MathQuestion get _currentQ => _questions[_index];

  @override
  void initState() {
    super.initState();
    _fetchLevelAndStart();
  }

  Future<void> _fetchLevelAndStart() async {
    setState(() => _isLoadingLevel = true);
    final token = Session.token;
    if (token != null) {
      final level = await SignGameApi.getLevel(token, 'hearing');
      setState(() {
        _difficultyLevel = level;
        _isLoadingLevel = false;
        _questions = QuestionBank.buildLevel(10, difficultyLevel: level);
      });
    } else {
      setState(() {
        _isLoadingLevel = false;
        _questions = QuestionBank.buildLevel(10);
      });
    }
  }

  void _resetForNextQuestion() {
    _checked = false;
    _isCorrect = false;
    _predicted = null;
    _confidence = null;
    _errorMsg = null;
  }

  void _startLevel() {
    setState(() {
      _questions = QuestionBank.buildLevel(10, difficultyLevel: _difficultyLevel);
      _wrongQuestions.clear();
      _retryCount.clear();
      _questionHistory.clear();
      _started = true;
      _index = 0;
      _resetForNextQuestion();
    });
  }

  void _goNext() {
    if (!_checked) return;
    
    // If wrong, save it for the summary screen
    if (!_isCorrect) {
      if (!_wrongQuestions.contains(_currentQ)) {
        _wrongQuestions.add(_currentQ);
      }
    }
    
    setState(() {
      _index++;
      if (_levelFinished) {
        _saveHistory();
      } else {
        _resetForNextQuestion();
      }
    });
  }

  Future<void> _saveHistory() async {
    final token = Session.token;
    if (token == null || _questionHistory.isEmpty) return;

    final correctCount = _questionHistory.where((q) => q['isCorrect'] == true).length;
    final totalCount = _questionHistory.length;

    final result = await SignGameApi.saveHistory(
      token: token,
      disabilityType: 'hearing',
      difficultyLevel: _difficultyLevel,
      totalQuestions: totalCount,
      correctCount: correctCount,
      questions: _questionHistory,
    );

    if (result['success'] == true) {
      final xpGained = result['xpGained'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Round Finished! You earned $xpGained XP 🎉',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: xpGained > 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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

      // CORRECT MATH CONNECTION: 
      _isCorrect = (result.prediction != null && result.prediction == expected);

      _questionHistory.add({
        'questionText': _currentQ.text,
        'correctAnswer': expected,
        'userAnswer': result.prediction,
        'isCorrect': _isCorrect,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLevel) {
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
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
                        '/hearing_games_dashboard',
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
                    "ඔබ අභියෝගය සම්පූර්ණ කළා",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.deepPurple.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ප්‍රශ්න ${_questions.length}න් ${_questions.length - _wrongQuestions.length}ක් නිවැරදියි",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  if (_wrongQuestions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "වැරදි පිළිතුරු:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Column(
                          children: _wrongQuestions.map((q) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              q.text.replaceAll('?', q.answer.toString()),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D1B69),
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ],
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
                            onTap: _startLevel,
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
    final displayLevel = QuestionBank.detectLevel(q.answer);

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
                      '/hearing_games_dashboard',
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
                        "මට්ටම $displayLevel",
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
                          onTap: _checked ? _goNext : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: _checked
                                  ? (_isCorrect
                                      ? const LinearGradient(
                                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                                        ))
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
                if (!_checked)
                  Text(
                    "පිළිතුර සඳහා සංඥාව ලබා දෙන්න",
                    style: TextStyle(
                      color: Colors.blue.withOpacity(0.8),
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
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                size: 40,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "පිළිතුරක් බලාපොරොත්තුවෙන්...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1976D2),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isCorrect) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "නිවැරදියි!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "ඔබේ සංඥාව: $_predicted",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 50,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "වැරදියි",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "හඳුනාගත් සංඥාව: $_predicted",
            style: TextStyle(
              fontSize: 16,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "නැවත උත්සාහ කරන්න!",
            style: TextStyle(
              fontSize: 15,
              color: Colors.red.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// SIGN CAPTURE PAGE 
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

      // FRONT camera for better self-recording
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
      
      // Changed to 4 seconds to match the Level2 improvement 
      await Future.delayed(const Duration(seconds: 4));
      
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
    final uri = Uri.parse("${widget.apiBaseUrl}/api/models/hearing-impairment/predict-video");
    final req = http.MultipartRequest("POST", uri);

    req.files.add(
      await http.MultipartFile.fromPath(
        "video",
        videoPath,
        contentType: MediaType('video', 'mp4'), 
      ),
    );

    // Send the correct expected value (handled purely here)
    req.fields["expected"] = widget.expectedAnswer.toString();
    
    // Auto detect level from the expected answer and send it
    int calculatedLevel = QuestionBank.detectLevel(widget.expectedAnswer);
    req.fields["level"] = calculatedLevel.toString();

    try {
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode != 200) {
        return _CaptureResult(error: "Server Error: ${resp.body}");
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        return _CaptureResult(error: "වලංගු නොවන ප්‍රතිචාරය");
      }

      if (decoded["success"] == false) {
        return _CaptureResult(error: decoded["message"] ?? "Failed to process video");
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
    } catch (e) {
      return _CaptureResult(error: "Network error: $e");
    }
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
