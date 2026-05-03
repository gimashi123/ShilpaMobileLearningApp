import re

with open('mobile_app/lib/pages/quiz/quiz_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Update constructor
code = re.sub(
    r"class QuizScreen extends StatefulWidget \{[\s\S]*?const QuizScreen\(\{super\.key, required this\.grade, required this\.type\}\);",
    "class QuizScreen extends StatefulWidget {\n  final String operation;\n  const QuizScreen({super.key, required this.operation});",
    code
)

# 2. Imports
code = code.replace(
    "import 'package:mobile_app/models/quiz.dart';",
    "import 'dart:math';\nimport 'package:mobile_app/services/sign_game_api.dart';\nimport 'package:mobile_app/session/session.dart';"
)
code = code.replace("import 'package:mobile_app/services/quiz_api.dart';", "")

# 3. State variables
code = re.sub(
    r"List<Quiz> quizzes = \[\];",
    "List<Map<String, dynamic>> quizzes = [];\n  List<Map<String, dynamic>> answersHistory = [];\n  int _level = 1;\n  int _xpGained = 0;",
    code
)

# 4. loadQuizzes -> loadLevelAndGenerate
new_load_func = """
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
    
    for (int i = 0; i < 10; i++) {
      int a = 0, b = 0, ans = 0;
      int minAns = level == 1 ? 1 : 10;
      int maxAns = level == 1 ? 10 : 30;

      if (operation == 'add') {
        ans = minAns + random.nextInt(maxAns - minAns + 1);
        a = random.nextInt(ans + 1);
        b = ans - a;
      } else if (operation == 'sub') {
        ans = minAns + random.nextInt(maxAns - minAns + 1);
        b = random.nextInt(maxAns + 1);
        a = ans + b;
      } else if (operation == 'mul') {
        ans = minAns + random.nextInt(maxAns - minAns + 1);
        List<int> factors = [];
        for (int f = 1; f <= ans; f++) {
          if (ans % f == 0) factors.add(f);
        }
        a = factors[random.nextInt(factors.length)];
        b = ans ~/ a;
      } else if (operation == 'div') {
        ans = minAns + random.nextInt(maxAns - minAns + 1);
        b = 1 + random.nextInt(5);
        a = ans * b;
      }

      String symbol = operation == 'add' ? '+' : operation == 'sub' ? '-' : operation == 'mul' ? '×' : '÷';

      quizzes.add({
        'id': i.toString(),
        'question': '$a $symbol $b = ?',
        'correctAnswer': ans,
      });
    }
  }
"""
code = re.sub(r"Future<void> loadQuizzes\(\) async \{[\s\S]*?void _showFriendlyErrorDialog\(\) \{[\s\S]*?\}\n      \),\n    \);\n  \}", new_load_func + "\n  void _showFriendlyErrorDialog() {\n    showDialog(\n      context: context,\n      barrierDismissible: false,\n      builder: (ctx) => AlertDialog(\n        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),\n        title: const Row(\n          children: [\n            Text('🌟 ', style: TextStyle(fontSize: 28)),\n            Text('Oopsie!'),\n          ],\n        ),\n        content: const Text(\n          'We couldn\\'t find any quizzes right now.\\n'\n              'Don\\'t worry, let\\'s try again together! ✨',\n          style: TextStyle(fontSize: 16, height: 1.5),\n        ),\n        actions: [\n          TextButton(\n            onPressed: () {\n              Navigator.pop(ctx);\n              Navigator.pop(context);\n            },\n            style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),\n            child: const Text('Go Back'),\n          ),\n          ElevatedButton(\n            onPressed: () {\n              Navigator.pop(ctx);\n              setState(() => loading = true);\n              loadQuizzes();\n            },\n            style: ElevatedButton.styleFrom(\n              backgroundColor: Colors.deepPurple,\n              foregroundColor: Colors.white,\n              shape: RoundedRectangleBorder(\n                borderRadius: BorderRadius.circular(24),\n              ),\n            ),\n            child: const Text('Try Again ✨'),\n          ),\n        ],\n      ),\n    );\n  }", code)


# 5. Check Answer
new_check = """
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
      'qIndex': currentIndex,
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
        final res = await SignGameApi.saveHistory(
          token: token,
          disabilityType: dType,
          difficultyLevel: _level,
          totalQuestions: quizzes.length,
          correctCount: score,
          questions: answersHistory,
          source: 'quiz'
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
"""
code = re.sub(r"Future<void> checkAnswerAndNext\(\) async \{[\s\S]*?    \} catch \(e\) \{\n      setState\(\(\) \{\n        feedback = \"😅 Oops! Connection issue\. Try again\?\";\n        isProcessing = false;\n      \}\);\n    \}\n  \}", new_check.strip(), code)

# 6. Update the references to quiz
code = code.replace("quiz.id", "quiz['id']")
code = code.replace("quiz.question", "quiz['question']")

# 7. Add XP gained to final screen
# Search for Row with percentage and accuracy
xp_ui = """
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
"""
code = code.replace("const SizedBox(height: 15),", xp_ui, 1)

with open('mobile_app/lib/pages/quiz/quiz_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
