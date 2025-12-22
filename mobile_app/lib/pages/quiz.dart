import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/top_nav_bar.dart';
import 'package:mobile_app/services/braille_pdf_service.dart';

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

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
  }

  void _selectOperation(OpType op) {
    setState(() {
      _selectedOp = op;
      _score = 0;
      _questionNumber = 0;
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    setState(() {
      _questionNumber++;
      _answered = false;
      _chosenOption = null;
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    switch (_selectedOp) {
      case OpType.add:
        _a = _rand.nextInt(50) + 1;
        _b = _rand.nextInt(50) + 1;
        _correctAnswer = _a + _b;
        break;

      case OpType.sub:
        int x = _rand.nextInt(50) + 1;
        int y = _rand.nextInt(50) + 1;
        _a = max(x, y);
        _b = min(x, y);
        _correctAnswer = _a - _b;
        break;

      case OpType.mul:
        _a = _rand.nextInt(12) + 1;
        _b = _rand.nextInt(12) + 1;
        _correctAnswer = _a * _b;
        break;

      case OpType.div:
        _b = _rand.nextInt(11) + 1;
        int result = _rand.nextInt(12) + 1;
        _a = _b * result; // divisible
        _correctAnswer = result;
        break;

      default:
        _a = 0;
        _b = 0;
        _correctAnswer = 0;
    }

    final Set<int> opts = {_correctAnswer};
    while (opts.length < 4) {
      int delta = (_rand.nextInt(10) + 1) * (_rand.nextBool() ? 1 : -1);
      int candidate = _correctAnswer + delta;
      if (candidate != _correctAnswer && candidate >= 0) {
        opts.add(candidate);
      }
    }
    _options = opts.toList()..shuffle(_rand);
  }

  void _chooseOption(int val) {
    if (_answered) return;

    setState(() {
      _answered = true;
      _chosenOption = val;
      if (val == _correctAnswer) _score++;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_questionNumber >= _totalQuestions) {
        _showResult();
      } else {
        _nextQuestion();
      }
    });
  }

  void _showResult() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quiz Finished'),
        content: Text('Your score: $_score / $_totalQuestions'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _selectedOp = null;
              });
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
        int x = _rand.nextInt(50) + 1;
        int y = _rand.nextInt(50) + 1;
        a = max(x, y);
        b = min(x, y);
      } else if (op == OpType.mul) {
        a = _rand.nextInt(12) + 1;
        b = _rand.nextInt(12) + 1;
      } else if (op == OpType.div) {
        b = _rand.nextInt(11) + 1;
        int result = _rand.nextInt(12) + 1;
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
      debugPrint("PDF error: $e");
    }
  }

  Widget _buildOperationCard(OpType op) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _selectOperation(op),
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

  Widget _buildQuestionCard() {
    final theme = Theme.of(context);

    return Card(
      key: ValueKey('q$_questionNumber'),
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
            const SizedBox(height: 12),
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

              String letter = String.fromCharCode(65 + idx);

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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _chooseOption(opt),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _selectedOp!.color.withOpacity(
                                0.12,
                              ),
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
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            else if (_answered && chosen && !correct)
                              const Icon(Icons.cancel, color: Colors.red),
                          ],
                        ),
                      ),
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
                onPressed: () {
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
                  onPressed: () {
                    setState(() {
                      _score = 0;
                      _questionNumber = 0;
                      _nextQuestion();
                    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              const Padding(
                padding: EdgeInsets.all(12),
                child: TopNavBar(selectedTab: 3),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor:
                      _selectedOp?.color ?? Theme.of(context).primaryColor,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: () {
                  setState(() {
                    _selectedOp = null;
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
              const Spacer(),
              if (!_answered)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _answered = true;
                      _chosenOption = null;
                    });
                  },
                  child: const Text('Show Answer'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
