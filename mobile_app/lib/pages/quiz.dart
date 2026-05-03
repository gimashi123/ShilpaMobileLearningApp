import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_app/widgets/top_nav_bar.dart';
import 'package:mobile_app/services/braille_pdf_service.dart';
import 'package:mobile_app/services/sign_game_api.dart';
import 'package:mobile_app/services/quiz_api.dart';
import 'package:mobile_app/session/session.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

enum OpType { add, sub, mul, div }

extension OpTypeExt on OpType {
  String get symbol {
    switch (this) {
      case OpType.add:
        return '+';
      case OpType.sub:
        return '-';
      case OpType.mul:
        return 'x';
      case OpType.div:
        return '/';
    }
  }

  String get name {
    switch (this) {
      case OpType.add:
        return 'එකතු කිරීම';
      case OpType.sub:
        return 'අඩු කිරීම';
      case OpType.mul:
        return 'ගුණ කිරීම';
      case OpType.div:
        return 'බෙදීම';
    }
  }

  Color get color {
    switch (this) {
      case OpType.add:
        return Colors.blue;
      case OpType.sub:
        return Colors.orange;
      case OpType.mul:
        return Colors.purple;
      case OpType.div:
        return Colors.teal;
    }
  }
}

class _QuizPageState extends State<QuizPage> {
  final Random _rand = Random();

  OpType? _selectedOp;

  int _a = 0, _b = 0;
  int _correctAnswer = 0;

  List<int> _options = [];
  int _score = 0;
  int _questionNumber = 0;
  final int _totalQuestions = 10;

  bool _answered = false;
  int? _chosenOption;

  int _level = 1;
  List<Map<String, dynamic>> answersHistory = [];

  // ✅ TTS only
  final FlutterTts _tts = FlutterTts();

  // swipe control
  Offset? _swipeStart;
  static const double _minSwipe = 45;

  // block swipes while speaking
  bool _ttsBusy = false;

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  Future<void> _setupTts() async {
    try {
      await _tts.setLanguage("si-LK");
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        if (!mounted) return;
        setState(() => _ttsBusy = true);
      });
      _tts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() => _ttsBusy = false);
      });
      _tts.setErrorHandler((msg) {
        if (!mounted) return;
        setState(() => _ttsBusy = false);
      });
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _stopSpeak() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _repeatVoiceIfPossible() async {
    if (_selectedOp == null) return;
    if (_options.length != 4) return;
    await _speakQuestionAndGuide();
  }

  Future<void> _selectOperation(OpType op) async {
    setState(() {
      _selectedOp = op;
      _score = 0;
      _questionNumber = 0;
      _answered = false;
      _chosenOption = null;
      answersHistory.clear();
    });

    try {
      final token = Session.token ?? "";
      final dType = Session.disabilityType ?? "visual";
      _level = await SignGameApi.getLevel(token, dType);
    } catch (_) {
      _level = 1;
    }

    _nextQuestion();
  }

  void _nextQuestion() {
    if (_selectedOp == null) return;

    setState(() {
      _questionNumber++;
      _answered = false;
      _chosenOption = null;
      _generateQuestion();
    });

    _speakQuestionAndGuide();
  }

  void _generateQuestion() {
    if (_selectedOp == null) return;
    
    if (_level == 1) {
      if (_selectedOp == OpType.add) {
        _correctAnswer = 1 + _rand.nextInt(10); 
        _a = _rand.nextInt(_correctAnswer + 1);
        _b = _correctAnswer - _a;
      } else if (_selectedOp == OpType.sub) {
        _a = 10 + _rand.nextInt(11); 
        _correctAnswer = 1 + _rand.nextInt(10); 
        _b = _a - _correctAnswer;
      } else if (_selectedOp == OpType.mul) {
        _correctAnswer = 1 + _rand.nextInt(10);
        List<int> factors = [];
        for (int f = 1; f <= _correctAnswer; f++) {
          if (_correctAnswer % f == 0) factors.add(f);
        }
        _a = factors[_rand.nextInt(factors.length)];
        _b = _correctAnswer ~/ _a;
      } else if (_selectedOp == OpType.div) {
        _correctAnswer = 1 + _rand.nextInt(10); 
        _b = 1 + _rand.nextInt(5); 
        _a = _correctAnswer * _b; 
      }
    } else {
      if (_selectedOp == OpType.add) {
        _correctAnswer = 10 + _rand.nextInt(21); 
        _a = _rand.nextInt(_correctAnswer + 1);
        _b = _correctAnswer - _a;
      } else if (_selectedOp == OpType.sub) {
        _correctAnswer = 10 + _rand.nextInt(21); 
        _b = _rand.nextInt(21); 
        _a = _correctAnswer + _b;
      } else if (_selectedOp == OpType.mul) {
        _correctAnswer = 10 + _rand.nextInt(21); 
        List<int> factors = [];
        for (int f = 1; f <= _correctAnswer; f++) {
          if (_correctAnswer % f == 0) factors.add(f);
        }
        _a = factors[_rand.nextInt(factors.length)];
        _b = _correctAnswer ~/ _a;
      } else if (_selectedOp == OpType.div) {
        _correctAnswer = 10 + _rand.nextInt(21); 
        _b = 1 + _rand.nextInt(5); 
        _a = _correctAnswer * _b;
      }
    }

    final Set<int> opts = {_correctAnswer};
    while (opts.length < 4) {
      final delta = (_rand.nextInt(10) + 1) * (_rand.nextBool() ? 1 : -1);
      final candidate = _correctAnswer + delta;
      if (candidate >= 0 && candidate != _correctAnswer) opts.add(candidate);
    }
    _options = opts.toList()..shuffle(_rand);
  }

  Future<void> _speakQuestionAndGuide() async {
    if (!mounted) return;
    if (_selectedOp == null) return;
    if (_options.length != 4) return;

    final q = "$_a ${_selectedOp!.symbol} $_b = ?";
    final aOpt = _options[0];
    final bOpt = _options[1];
    final cOpt = _options[2];
    final dOpt = _options[3];

    final msg =
        """
$q.
A $aOpt.
B $bOpt.
C $cOpt.
D $dOpt.
පිළිතුර A නම් වමට ස්වයිප් කරන්න.
පිළිතුර B නම් දකුණට ස්වයිප් කරන්න.
පිළිතුර C නම් උඩට ස්වයිප් කරන්න.
පිළිතුර D නම් පහලට ස්වයිප් කරන්න.
නැවත ප්‍රශ්නය අහන්න දෙපාරක් click කරන්න.
""";

    await _stopSpeak();
    await _speak(msg);
  }

  void _onSwipeEnd(Offset end) {
    if (_selectedOp == null) return;
    if (_answered) return;
    if (_options.length != 4) return;
    if (_ttsBusy) return;

    final start = _swipeStart;
    if (start == null) return;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    if (dx.abs() < _minSwipe && dy.abs() < _minSwipe) return;

    final bool horizontal = dx.abs() >= dy.abs();

    int idx;
    String letter;

    if (horizontal) {
      if (dx < 0) {
        idx = 0; // A
        letter = "A";
      } else {
        idx = 1; // B
        letter = "B";
      }
    } else {
      if (dy < 0) {
        idx = 2; // C
        letter = "C";
      } else {
        idx = 3; // D
        letter = "D";
      }
    }

    final chosenValue = _options[idx];
    _chooseOption(chosenValue, chosenLetter: letter);
  }

  Future<void> _chooseOption(int val, {required String chosenLetter}) async {
    if (_answered) return;

    setState(() {
      _answered = true;
      _chosenOption = val;
      if (val == _correctAnswer) _score++;
      
      answersHistory.add({
        'questionText': "$_a ${_selectedOp!.symbol} $_b = ?",
        'userAnswer': val,
        'correctAnswer': _correctAnswer,
        'isCorrect': val == _correctAnswer,
      });
    });

    if (val == _correctAnswer) {
      await _speak("ඔබේ පිළිතුර $chosenLetter. නිවැරදි.");
    } else {
      await _speak(
        "ඔබේ පිළිතුර $chosenLetter. වැරදි. නිවැරදි පිළිතුර $_correctAnswer.",
      );
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (_questionNumber >= _totalQuestions) {
      _showResult();
    } else {
      _nextQuestion();
    }
  }

  Future<void> _showResult() async {
    int xpGained = 0;
    try {
      final token = Session.token ?? "";
      final dType = Session.disabilityType ?? "visual";
      final res = await QuizApi.saveHistory(
        token: token,
        disabilityType: dType,
        difficultyLevel: _level,
        totalQuestions: _totalQuestions,
        correctCount: _score,
        questions: answersHistory,
      );
      xpGained = res['xpGained'] ?? 0;
    } catch (_) {}

    await _speak("ප්‍රශ්න ඉවරයි. ඔබගේ ලකුණු $_totalQuestions න් $_scoreයි. ${xpGained != 0 ? 'ඔබට එක්ස්පී ලකුණු $xpGained ක් ලැබුණා.' : ''}");

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quiz Finished'),
        content: Text('Your score: $_score / $_totalQuestions\n${xpGained != 0 ? 'XP Gained: ${xpGained > 0 ? '+' : ''}$xpGained ✨' : ''}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _selectedOp = null);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _buildPdfQuestions(OpType op) {
    final List<Map<String, String>> items = [];
    for (int i = 0; i < 10; i++) {
      int a = 0, b = 0;

      if (op == OpType.add) {
        a = _rand.nextInt(50) + 1;
        b = _rand.nextInt(50) + 1;
      } else if (op == OpType.sub) {
        final x = _rand.nextInt(50) + 1;
        final y = _rand.nextInt(50) + 1;
        a = max(x, y);
        b = min(x, y);
      } else if (op == OpType.mul) {
        a = _rand.nextInt(12) + 1;
        b = _rand.nextInt(12) + 1;
      } else if (op == OpType.div) {
        b = _rand.nextInt(11) + 1;
        final result = _rand.nextInt(12) + 1;
        a = b * result;
      }

      items.add({"q": "$a ${op.symbol} $b = ?"});
    }
    return items;
  }

  Future<void> _downloadPdf() async {
    if (_selectedOp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select + / - / x / / first")),
      );
      return;
    }

    try {
      final op = _selectedOp!;
      final items = _buildPdfQuestions(op);

      await BraillePdfService.generateAndOpenPdf(
        type: "math",
        title: "Math Quiz 10 (${op.symbol})",
        items: items,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("PDF error: $e")));
    }
  }

  Widget _buildOperationCard(OpType op) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          _selectOperation(op);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [op.color.withOpacity(0.12), op.color.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: op.color,
                child: Text(
                  op.symbol,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                op.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeaderBar() {
    final Color bg = _selectedOp?.color ?? Theme.of(context).primaryColor;
    final double progress = (_totalQuestions == 0)
        ? 0
        : (_questionNumber / _totalQuestions).clamp(0.0, 1.0);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 32,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await _stopSpeak();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/home_visual');
                },
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ගණිතය ප්‍රශ්න',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_selectedOp != null)
                IconButton(
                  icon: const Icon(Icons.restart_alt, color: Colors.white),
                  tooltip: 'Restart',
                  onPressed: () async {
                    await _stopSpeak();
                    if (!mounted) return;

                    // ✅ FIX: no nested setState
                    setState(() {
                      _score = 0;
                      _questionNumber = 0;
                      _answered = false;
                      _chosenOption = null;
                    });

                    _nextQuestion();
                  },
                ),
            ],
          ),
        ),
        if (_selectedOp != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_selectedOp!.color.withOpacity(0.06), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Question $_questionNumber / $_totalQuestions',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
                const Spacer(),
                Text(
                  'Score: $_score',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$_a  ${_selectedOp!.symbol}  $_b  = ?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _answered
                    ? "Answered"
                    : (_ttsBusy
                          ? "Speaking..."
                          : "Swipe: A← B→ C↑ D↓  |  Double tap = Repeat voice"),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            ..._options.asMap().entries.map((entry) {
              final int idx = entry.key;
              final int opt = entry.value;
              final bool correct = opt == _correctAnswer;
              final bool chosen = _chosenOption == opt;

              Color bg;
              Color border;

              if (_answered) {
                if (chosen && correct) {
                  bg = Colors.green.shade100;
                  border = Colors.green;
                } else if (chosen && !correct) {
                  bg = Colors.red.shade100;
                  border = Colors.red;
                } else if (!chosen && correct) {
                  bg = Colors.green.shade50;
                  border = Colors.green;
                } else {
                  bg = Colors.grey.shade50;
                  border = Colors.transparent;
                }
              } else {
                bg = Colors.white;
                border = Colors.transparent;
              }

              final letter = String.fromCharCode(65 + idx);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: border,
                      width: border == Colors.transparent ? 0 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _selectedOp!.color.withOpacity(0.12),
                          radius: 16,
                          child: Text(
                            letter,
                            style: TextStyle(
                              color: _selectedOp!.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          opt.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        if (_answered && correct)
                          const Icon(Icons.check_circle, color: Colors.green)
                        else if (_answered && chosen && !correct)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationSelection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Text(
            'Choose an operation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              physics: const BouncingScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 1.05,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: OpType.values.map(_buildOperationCard).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizBody() {
    return Column(
      children: [
        _buildQuestionCard(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _stopSpeak();
                  setState(() => _selectedOp = null);
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
              const Spacer(),
              if (_selectedOp != null && !_answered)
                TextButton(
                  onPressed: _speakQuestionAndGuide,
                  child: const Text('Repeat Voice'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  void dispose() {
    // ✅ FIX: don't call async function in dispose
    try {
      _tts.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SwipeWrapper(
      onSwipe: (start, end) {
        _swipeStart = start;
        _onSwipeEnd(end);
      },
      onDoubleTap: _repeatVoiceIfPossible,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _selectedOp?.color.withOpacity(0.06) ??
                    Colors.blueGrey.withOpacity(0.03),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),

                  // ✅ FIX: pass ALL required args for YOUR TopNavBar
                  child: TopNavBar(
                    selectedTab: 3,
                    onTapTab: (int index) {
                      // Your navbar currently navigates internally in _navigate,
                      // but it still requires this param to compile.
                    },
                    highContrast: false,
                    fontSize: 18,
                    title: "ගණිතය ප්‍රශ්න",
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _downloadPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildTopHeaderBar(),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _selectedOp == null
                      ? _buildOperationSelection()
                      : _buildQuizBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeWrapper extends StatefulWidget {
  final Widget child;
  final void Function(Offset start, Offset end) onSwipe;
  final VoidCallback onDoubleTap;

  const _SwipeWrapper({
    required this.child,
    required this.onSwipe,
    required this.onDoubleTap,
  });

  @override
  State<_SwipeWrapper> createState() => _SwipeWrapperState();
}

class _SwipeWrapperState extends State<_SwipeWrapper> {
  Offset? _start;
  Offset? _last;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: widget.onDoubleTap,
      onPanStart: (d) {
        _start = d.globalPosition;
        _last = d.globalPosition;
      },
      onPanUpdate: (d) {
        _last = d.globalPosition;
      },
      onPanEnd: (_) {
        final s = _start;
        final e = _last;
        _start = null;
        _last = null;
        if (s != null && e != null) widget.onSwipe(s, e);
      },
      child: widget.child,
    );
  }
}
