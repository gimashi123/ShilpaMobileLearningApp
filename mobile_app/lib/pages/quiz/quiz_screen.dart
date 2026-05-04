import 'package:flutter/material.dart';
import 'dart:math';
import 'package:mobile_app/services/sign_game_api.dart';
import 'package:mobile_app/services/quiz_api.dart';
import 'package:mobile_app/session/session.dart';


class QuizScreen extends StatefulWidget {
  final String operation;
  const QuizScreen({super.key, required this.operation});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> quizzes = [];
  List<Map<String, dynamic>> answersHistory = [];
  int _level = 1;
  int _xpGained = 0;
  int currentIndex = 0;
  int score = 0;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool loading = true;
  bool showFinal = false;
  bool isProcessing = false;
  bool canProceed = false;

  String? feedback;
  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatAnimation;

  @override
  void initState() {
    super.initState();
    loadQuizzes();

    // Heartbeat animation for encouragement
    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _heartbeatAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );

    // Listen to text changes to enable button
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != canProceed) {
        setState(() {
          canProceed = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _heartbeatController.dispose();
    super.dispose();
  }

  Future<void> loadQuizzes() async {
    try {
      final token = Session.token ?? "";
      final dType = Session.disabilityType ?? "hearing";
      
      _level = await SignGameApi.getLevel(token, dType);
      _generateQuestions(_level, widget.operation);

      setState(() {
        loading = false;
      });

      if (quizzes.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          FocusScope.of(context).requestFocus(_focusNode);
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (mounted) {
        _showFriendlyErrorDialog();
      }
    }
  }

  void _generateQuestions(int level, String operation) {
    quizzes.clear();
    answersHistory.clear();
    final random = Random();

    // Reduce to 5 questions as requested
    for (int i = 0; i < 5; i++) {
      int a = 0, b = 0, ans = 0;

      if (operation == 'add') {
        if (level == 1) {
          // Level 1: sum up to 10
          ans = 1 + random.nextInt(10);
          a = random.nextInt(ans + 1);
          b = ans - a;
        } else {
          // Level 2+: sum up to 30 or more
          ans = 10 + random.nextInt(21 + (level * 5));
          a = random.nextInt(ans + 1);
          b = ans - a;
        }
      } else if (operation == 'sub') {
        if (level == 1) {
          // Level 1: 1-digit subtraction
          a = 1 + random.nextInt(9); // 1..9
          b = random.nextInt(a + 1); // 0..a
          ans = a - b;
        } else {
          // Level 2+: larger numbers
          a = 10 + random.nextInt(21 + (level * 5));
          b = random.nextInt(a + 1);
          ans = a - b;
        }
      } else if (operation == 'mul') {
        // multiplier is fixed based on level (e.g. x2 for level 1)
        b = level + 1;
        // a is random, e.g. 1x2, 2x2, 3x2...
        a = 1 + random.nextInt(10 + (level * 2));
        ans = a * b;
      } else if (operation == 'div') {
        // divisor is fixed based on level (e.g. /2 for level 1)
        b = level + 1;
        // ans is random, so a is always a multiple of b
        ans = 1 + random.nextInt(10 + (level * 2));
        a = ans * b;
      }

      String symbol =
          operation == 'add' ? '+' : operation == 'sub' ? '-' : operation == 'mul' ? '×' : '÷';

      quizzes.add({
        'id': i.toString(),
        'question': '$a $symbol $b = ?',
        'correctAnswer': ans,
      });
    }
  }

  void _showFriendlyErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Row(
          children: [
            Text('🌟 ', style: TextStyle(fontSize: 28)),
            Text('Oopsie!'),
          ],
        ),
        content: const Text(
          'We couldn\'t find any quizzes right now.\n'
              'Don\'t worry, let\'s try again together! ✨',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => loading = true);
              loadQuizzes();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Try Again ✨'),
          ),
        ],
      ),
    );
  }

  Future<void> checkAnswerAndNext() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    final currentQuiz = quizzes[currentIndex];
    final userAnswer = int.tryParse(_controller.text.trim());
    final correctAns = currentQuiz["correctAnswer"];
    final isCorrect = userAnswer == correctAns;

    answersHistory.add({
      'questionText': currentQuiz["question"],
      'userAnswer': userAnswer,
      'correctAnswer': correctAns,
      'isCorrect': isCorrect,
    });

    setState(() {
      if (isCorrect) {
        score++;
        feedback = "ඔබගේ පිළිතුර නිවැරදි ✨";
      } else {
        feedback = "ඔබගේ පිළිතුර වැරදි! නිවැරදි පිළිතුර: $correctAns";
      }
    });

    await Future.delayed(const Duration(milliseconds: 1800));

    if (currentIndex < quizzes.length - 1) {
      setState(() {
        currentIndex++;
        feedback = null;
        _controller.clear();
        canProceed = false;
        isProcessing = false;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    } else {
      // Save to backend!
      try {
        final token = Session.token ?? "";
        final dType = Session.disabilityType ?? "hearing";
        final res = await QuizApi.saveHistory(
          token: token,
          disabilityType: dType,
          difficultyLevel: _level,
          totalQuestions: quizzes.length,
          correctCount: score,
          questions: answersHistory,
        );
        
        setState(() {
          _xpGained = res['xpGained'] ?? 0;
          showFinal = true;
          isProcessing = false;
        });
      } catch (e) {
        setState(() {
          showFinal = true;
          isProcessing = false;
        });
      }
    }
  }

  String _getEncouragementMessage() {
    if (quizzes.isEmpty) return '';

    final progress = currentIndex / quizzes.length;
    if (progress < 0.3) return "You're doing great! 💪";
    if (progress < 0.6) return "Keep going! You've got this! 🌟";
    if (progress < 0.9) return "Almost there! Amazing effort! ✨";
    return "Final question! You're a star! ⭐";
  }

  String _getScoreMessage() {
    final percentage = quizzes.isEmpty
        ? 0
        : (score / quizzes.length * 100).round();
    if (percentage >= 90) return "Outstanding! 🌟";
    if (percentage >= 70) return "Great job! 💫";
    if (percentage >= 50) return "Good effort! ✨";
    return "Keep practicing! You'll shine! 💪";
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade50, Colors.pink.shade50],
            ),
          ),
          child: Center(
            child: Column(
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
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('✨', style: TextStyle(fontSize: 50)),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Warming up your brain...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Getting questions ready for you',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (showFinal) {
      final percentage = quizzes.isEmpty
          ? 0
          : (score / quizzes.length * 100).round();

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.deepPurple.shade50, Colors.pink.shade50],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Celebration animation
                    ScaleTransition(
                      scale: _heartbeatAnimation,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            percentage >= 70 ? '🎉' : '✨',
                            style: const TextStyle(fontSize: 70),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getScoreMessage(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$score',
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              Text(
                                ' / ${quizzes.length}',
                                style: TextStyle(
                                  fontSize: 32,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 15),
                          if (_xpGained != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: _xpGained > 0 ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _xpGained > 0 ? '+ $_xpGained XP ✨' : '$_xpGained XP',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _xpGained > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${percentage}%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'accuracy',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Encouragement
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            percentage >= 70
                                ? '⭐ Brilliant work!'
                                : percentage >= 50
                                ? '💫 Good job!'
                                : '🌱 Keep growing!',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            percentage >= 70
                                ? '🎓'
                                : percentage >= 50
                                ? '📚'
                                : '🌻',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              side: BorderSide(
                                color: Colors.deepPurple.shade200,
                              ),
                            ),
                            child: const Text('🏠 Home'),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                currentIndex = 0;
                                score = 0;
                                showFinal = false;
                                loading = true;
                              });
                              loadQuizzes();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                            ),
                            child: const Text('🔄 Play Again'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final quiz = quizzes[currentIndex];
    final progress = (currentIndex + 1) / quizzes.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade50, Colors.pink.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.deepPurple,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),

                        // Score badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Text('⭐ ', style: TextStyle(fontSize: 16)),
                              Text(
                                '$score',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Progress bar with love
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple,
                                  Colors.purpleAccent.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Question counter with personality
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Question ${currentIndex + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'of ${quizzes.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Encouragement message
                    Text(
                      _getEncouragementMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Question with cute styling
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.deepPurple.shade200,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            quiz['question'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Answer input with personality
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '💭 Your answer',
                            labelStyle: const TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 16,
                            ),
                            hintText: 'Type your answer here...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Colors.deepPurple,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.deepPurple,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Feedback with animation
                        if (feedback != null)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: 1.0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: feedback!.contains('✨')
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: feedback!.contains('✨')
                                      ? Colors.green.shade200
                                      : Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    feedback!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: feedback!.contains('✨')
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Next button with personality
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: (!canProceed || isProcessing)
                                ? null
                                : checkAnswerAndNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: canProceed ? 5 : 0,
                            ),
                            child: isProcessing
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Checking...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentIndex == quizzes.length - 1
                                      ? 'ප්‍රශ්න අවසන්  '
                                      : 'පිළිතුර පරික්ෂා කරන්න ',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}