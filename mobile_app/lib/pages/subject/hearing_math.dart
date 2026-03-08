import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ✅ Use your real Session class
import 'package:mobile_app/session/session.dart';

/// ====== CONFIG ======
/// Android Emulator -> 10.0.2.2
/// Real phone -> http://<PC_IP>:3000
const String baseUrl = "http://10.0.2.2:3000";

/// operation codes expected by backend
enum Op { add, sub, mul, div }

String opToCode(Op op) {
  switch (op) {
    case Op.add:
      return "ADD";
    case Op.sub:
      return "SUB";
    case Op.mul:
      return "MUL";
    case Op.div:
      return "DIV";
  }
}

String opSymbol(Op op) {
  switch (op) {
    case Op.add:
      return "+";
    case Op.sub:
      return "-";
    case Op.mul:
      return "×";
    case Op.div:
      return "÷";
  }
}

/// ====== MODELS ======
class QuizQuestion {
  final String id; // "0".."9"
  final int a;
  final int b;

  QuizQuestion({required this.id, required this.a, required this.b});

  factory QuizQuestion.fromJson(Map<String, dynamic> j) {
    return QuizQuestion(
      id: j["id"].toString(),
      a: (j["a"] as num).toInt(),
      b: (j["b"] as num).toInt(),
    );
  }
}

class UserAnswer {
  final String qId;
  final int? value;
  final int timeMs;

  UserAnswer({required this.qId, required this.value, required this.timeMs});

  Map<String, dynamic> toJson() => {
        "id": qId,
        "userAnswer": value,
        "timeMs": timeMs,
      };
}

class StartQuizResponse {
  final String attemptId;
  final String operation;
  final List<QuizQuestion> questions;

  StartQuizResponse({
    required this.attemptId,
    required this.operation,
    required this.questions,
  });

  factory StartQuizResponse.fromJson(Map<String, dynamic> j) {
    return StartQuizResponse(
      attemptId: j["attemptId"].toString(),
      operation: j["operation"].toString(),
      questions: (j["questions"] as List)
          .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubmitQuizResponse {
  final int correctCount;
  final int score;

  SubmitQuizResponse({required this.correctCount, required this.score});

  factory SubmitQuizResponse.fromJson(Map<String, dynamic> j) {
    return SubmitQuizResponse(
      correctCount: (j["correctCount"] as num).toInt(),
      score: (j["score"] as num).toInt(),
    );
  }
}

/// ====== API SERVICE ======
class QuizApi {
  static Future<StartQuizResponse> startQuiz({
    required String userId,
    required Op op,
  }) async {
    final url = Uri.parse("$baseUrl/api/quizzes/start");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "operation": opToCode(op),
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Start quiz failed: ${res.statusCode} ${res.body}");
    }
    return StartQuizResponse.fromJson(jsonDecode(res.body));
  }

  static Future<SubmitQuizResponse> submitQuiz({
    required String userId,
    required String attemptId,
    required List<UserAnswer> answers,
  }) async {
    final url = Uri.parse("$baseUrl/api/quizzes/$attemptId/submit");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "answers": answers.map((a) => a.toJson()).toList(),
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Submit failed: ${res.statusCode} ${res.body}");
    }
    return SubmitQuizResponse.fromJson(jsonDecode(res.body));
  }

  static Future fetchRandomQuizzes({required String grade, required String type}) async {}

  static Future checkAnswer({required String quizId, required String userAnswer}) async {}
}

/// ====== APP ENTRY WIDGET ======
class MathQuizApp extends StatelessWidget {
  const MathQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Math Quiz",
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const OperationSelectPage());
        }

        if (settings.name == '/quiz') {
          final op = settings.arguments as Op;
          return MaterialPageRoute(builder: (_) => QuizPagehearing(op: op));
        }

        if (settings.name == '/result') {
          final args = settings.arguments as ResultArgs;
          return MaterialPageRoute(
            builder: (_) => ResultPage(
              op: args.op,
              correctCount: args.correctCount,
              score: args.score,
            ),
          );
        }

        return MaterialPageRoute(builder: (_) => const OperationSelectPage());
      },
    );
  }
}

/// ====== UI: Operation Select ======
class OperationSelectPage extends StatelessWidget {
  const OperationSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Quiz Type")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _OpBtn(op: Op.add),
            _OpBtn(op: Op.sub),
            _OpBtn(op: Op.mul),
            _OpBtn(op: Op.div),
            const SizedBox(height: 16),
            const Text(
              "Each quiz = 10 questions\nQuestions are random and score is saved in database.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OpBtn extends StatelessWidget {
  final Op op;
  const _OpBtn({required this.op});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/quiz', arguments: op);
          },
          child: Text(
            "Start ${opSymbol(op)} Quiz",
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

/// ====== UI: Quiz Page ======
class QuizPagehearing extends StatefulWidget {
  final Op op;
  const QuizPagehearing({super.key, required this.op});

  @override
  State<QuizPagehearing> createState() => _QuizPagehearingState();
}

class _QuizPagehearingState extends State<QuizPagehearing> {
  bool loading = true;
  String? error;

  String attemptId = "";
  List<QuizQuestion> questions = [];

  int index = 0;
  final TextEditingController answerCtrl = TextEditingController();

  final List<UserAnswer> answers = [];
  final Stopwatch sw = Stopwatch();

  @override
  void initState() {
    super.initState();
    _start();
  }

  String _requireUserId() {
    final uid = Session.userId; // ✅ should be set at login
    if (uid == null || uid.trim().isEmpty) {
      throw Exception("Session.userId is empty. Login first and save userId.");
    }
    return uid.trim();
  }

  Future<void> _start() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final uid = _requireUserId();
      final resp = await QuizApi.startQuiz(userId: uid, op: widget.op);

      attemptId = resp.attemptId;
      questions = resp.questions;

      index = 0;
      answers.clear();
      answerCtrl.clear();

      sw.reset();
      sw.start();

      setState(() => loading = false);
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _nextOrSubmit() async {
    if (questions.isEmpty) return;

    final q = questions[index];
    final timeMs = sw.elapsedMilliseconds;

    int? val;
    final raw = answerCtrl.text.trim();
    if (raw.isNotEmpty) val = int.tryParse(raw);

    answers.add(UserAnswer(qId: q.id, value: val, timeMs: timeMs));

    answerCtrl.clear();
    sw.reset();
    sw.start();

    if (index < questions.length - 1) {
      setState(() => index++);
      return;
    }

    sw.stop();
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final uid = _requireUserId();
      final result = await QuizApi.submitQuiz(
        userId: uid,
        attemptId: attemptId,
        answers: answers,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: ResultArgs(
          op: widget.op,
          correctCount: result.correctCount,
          score: result.score,
        ),
      );
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    answerCtrl.dispose();
    sw.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text("${opSymbol(widget.op)} Quiz")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text("${opSymbol(widget.op)} Quiz")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text("Error:\n$error"),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _start,
                  child: const Text("Retry"),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final q = questions[index];

    return Scaffold(
      appBar: AppBar(title: Text("${opSymbol(widget.op)} Quiz")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "Question ${index + 1} / ${questions.length}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Center(
                child: Text(
                  "${q.a}  ${opSymbol(widget.op)}  ${q.b}  =  ?",
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: answerCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Your answer (integer)",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _nextOrSubmit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _nextOrSubmit,
                child: Text(index == questions.length - 1 ? "Submit" : "Next"),
              ),
            ),
            const Spacer(),
            Text(
              "Tip: Division should be integer-based (backend generate like that).",
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ====== UI: Result ======
class ResultArgs {
  final Op op;
  final int correctCount;
  final int score;

  ResultArgs({required this.op, required this.correctCount, required this.score});
}

class ResultPage extends StatelessWidget {
  final Op op;
  final int correctCount;
  final int score;

  const ResultPage({
    super.key,
    required this.op,
    required this.correctCount,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = (correctCount / 10).clamp(0.0, 1.0);
    final bool excellent = correctCount >= 8;
    final Color accent = excellent ? Colors.amber.shade700 : Colors.blue.shade700;
    final String title = excellent ? "Excellent!" : (correctCount >= 5 ? "Well done!" : "Keep Practicing");

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Result"),
        backgroundColor: accent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.12), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 18),
            // Big card with summary
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: accent,
                      child: Icon(
                        excellent ? Icons.emoji_events : Icons.check_circle,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${opSymbol(op)} Quiz Finished",
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("Correct", style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 6),
                            Text(
                              "$correctCount / 10",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("Score", style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 6),
                            Text(
                              "$score",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(
                          value: pct,
                          minHeight: 10,
                          color: accent,
                          backgroundColor: accent.withOpacity(0.18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${(pct * 100).round()}% correct",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text("Retake Same Quiz"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/quiz', arguments: op);
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: accent),
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                },
                child: const Text("Back to Quiz Types"),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
