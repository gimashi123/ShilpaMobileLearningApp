import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// =======================
/// Settings (sound default ON)
/// =======================
class AppSettings {
  static const String soundOnKey = 'settings_sound_on';
  static const String hapticsOnKey = 'settings_haptics_on';

  static Future<bool> getSoundOn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(soundOnKey) ?? true;
  }

  static Future<bool> getHapticsOn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(hapticsOnKey) ?? true;
  }
}

/// =======================
/// Sound effects (safe)
/// =======================
class Sfx {
  static final AudioPlayer _p = AudioPlayer();

  static Future<void> _playAsset(String path) async {
    try {
      await _p.stop();
      await _p.play(AssetSource(path));
    } catch (_) {}
  }

  static Future<void> correct(bool enabled) async {
    if (!enabled) return;
    await _playAsset('sounds/correct.mp3');
  }

  static Future<void> wrong(bool enabled) async {
    if (!enabled) return;
    await _playAsset('sounds/wrong.mp3');
  }
}

/// =======================
/// Haptics (safe)
/// =======================
Future<void> hapticCorrect(bool enabled) async {
  if (!enabled) return;
  try {
    await HapticFeedback.lightImpact();
  } catch (_) {}
}

Future<void> hapticWrong(bool enabled) async {
  if (!enabled) return;
  try {
    await HapticFeedback.vibrate();
  } catch (_) {}
}

class IqGame extends StatelessWidget {
  const IqGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Learning Game',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Comic Sans MS'),
      home: const Menu(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// =====================================
/// Menu
/// =====================================
class Menu extends StatelessWidget {
  const Menu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade300, Colors.blue.shade300],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;

                final contentMaxW = w < 600 ? w * 0.88 : 520.0;
                final btnH = (h * 0.11).clamp(64.0, 90.0);

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxW),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GameButton(
                            title: '🚀 පටන් ගමු',
                            color: Colors.orange,
                            height: btnH,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SequentialGameFlow(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GameButton(
                            title: '📊 ලකුණු බලමු',
                            color: Colors.pink,
                            height: btnH,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ScoreHistoryScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ScoreHistoryScreen extends StatelessWidget {
  const ScoreHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score History'),
        backgroundColor: Colors.pink,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink.shade100, Colors.purple.shade100],
          ),
        ),
        child: const Center(
          child: Text(
            'ලකුණු ඉතිහාස විශේෂාංගය ළඟදීම එනවා!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class SequentialGameFlow extends StatefulWidget {
  const SequentialGameFlow({Key? key}) : super(key: key);

  @override
  State<SequentialGameFlow> createState() => _SequentialGameFlowState();
}

class _SequentialGameFlowState extends State<SequentialGameFlow> {
  int currentGameIndex = 0;
  int shapeGameScore = 0;
  int colorGameScore = 0;
  int popGameScore = 0;
  int totalScore = 0;
  bool isGameSequenceComplete = false;

  final List<Widget> games = [];

  @override
  void initState() {
    super.initState();
    games.addAll([
      ShapeMatchGame(
        onGameComplete: (score) {
          setState(() {
            shapeGameScore = score;
            currentGameIndex = 1;
          });
        },
      ),
      ColorMatchGame(
        onGameComplete: (score) {
          setState(() {
            colorGameScore = score;
            currentGameIndex = 2;
          });
        },
      ),
      PopBubblesGame(
        onGameComplete: (score) {
          setState(() {
            popGameScore = score;
            totalScore = shapeGameScore + colorGameScore + score;
            isGameSequenceComplete = true;
          });
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (isGameSequenceComplete) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade300, Colors.blue.shade300],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '🎉  ඉදිරියට යමු 🎉',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            ScoreCard(
                              title: 'හැඩ ගැලපීමෙන් ලකුණු',
                              score: shapeGameScore,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 14),
                            ScoreCard(
                              title: 'පාට ගැලපීමෙන් ලකුණු',
                              score: colorGameScore,
                              color: Colors.pink,
                            ),
                            const SizedBox(height: 14),
                            ScoreCard(
                              title: 'බෝල පිපිරීමෙන් ලකුණු',
                              score: popGameScore,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 26),
                            Container(
                              width: 320,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    '🏆 මුළු ලකුණු',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$totalScore',
                                    style: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: GameButton(
                                title: '🏠 ආපසු මුලට',
                                color: Colors.purple,
                                onTap: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return games[currentGameIndex];
  }
}

class ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final Color color;

  const ScoreCard({
    Key? key,
    required this.title,
    required this.score,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameButton extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;
  final double? height;

  const GameButton({
    Key? key,
    required this.title,
    required this.color,
    required this.onTap,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final btnH = height ?? 80.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: btnH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =====================================
/// Shape Match Game
/// =====================================
class ShapeMatchGame extends StatefulWidget {
  final Function(int score) onGameComplete;

  const ShapeMatchGame({Key? key, required this.onGameComplete})
    : super(key: key);

  @override
  State<ShapeMatchGame> createState() => _ShapeMatchGameState();
}

class _ShapeMatchGameState extends State<ShapeMatchGame> {
  static const String firstPlayKey = 'shape_first_play_done';

  int score = 0;
  int timeLeft = 50;
  Timer? timer;

  bool gameActive = false;
  bool isGameOver = false;

  String? selectedShape;
  final List<String> shapes = ['circle', 'square', 'triangle', 'rectangle'];

  String targetShape = '';
  String? lastTargetShape;

  int roundKey = 0;
  late Color targetCardBg;

  final List<Color> pastelColors = [
    const Color(0xFFFFF3E0),
    const Color(0xFFE3F2FD),
    const Color(0xFFE8F5E9),
    const Color(0xFFFCE4EC),
    const Color(0xFFF3E5F5),
    const Color(0xFFFFFDE7),
  ];

  bool showHint = false;
  Timer? hintBlinkTimer;
  bool hintBlinkOn = false;
  int hintBlinkTicks = 0;

  int wrongStreak = 0;

  bool soundOn = true;
  bool hapticsOn = true;

  @override
  void initState() {
    super.initState();
    targetCardBg = pastelColors[0];
    _loadSettingsAndStart();
  }

  Future<void> _loadSettingsAndStart() async {
    soundOn = await AppSettings.getSoundOn();
    hapticsOn = await AppSettings.getHapticsOn();
    if (mounted) setState(() {});
    await _checkFirstAttemptAndStart();
  }

  Future<void> _checkFirstAttemptAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    final firstDone = prefs.getBool(firstPlayKey) ?? false;

    startGame();

    if (!firstDone) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted && gameActive && !isGameOver) startHintBlink();
      });
      await prefs.setBool(firstPlayKey, true);
    }
  }

  void toggleHint() => startHintBlink();

  void startHintBlink() {
    hintBlinkTimer?.cancel();

    setState(() {
      // ✅ FIX: clear previous selection so hint can highlight the correct tile
      selectedShape = null;

      showHint = true;
      hintBlinkOn = true;
      hintBlinkTicks = 0;
    });

    hintBlinkTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted) return;

      setState(() {
        hintBlinkOn = !hintBlinkOn;
        hintBlinkTicks++;
      });

      if (hintBlinkTicks >= 10) {
        t.cancel();
        if (!mounted) return;
        setState(() {
          showHint = false;
          hintBlinkOn = false;
        });
      }
    });
  }

  void startGame() {
    setState(() {
      score = 0;
      wrongStreak = 0;
      timeLeft = 50;
      gameActive = true;
      isGameOver = false;
    });

    generateNewTarget();

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          endGame();
        }
      });
    });
  }

  void generateNewTarget() {
    final rnd = Random();
    String next = shapes[rnd.nextInt(shapes.length)];

    if (lastTargetShape != null && shapes.length > 1) {
      while (next == lastTargetShape) {
        next = shapes[rnd.nextInt(shapes.length)];
      }
    }

    hintBlinkTimer?.cancel();
    showHint = false;
    hintBlinkOn = false;

    setState(() {
      lastTargetShape = next;
      targetShape = next;
      selectedShape = null;

      roundKey++;
      targetCardBg = pastelColors[rnd.nextInt(pastelColors.length)];
    });

    HapticFeedback.selectionClick();
  }

  Future<void> checkMatch(String shape) async {
    if (!gameActive || isGameOver) return;

    setState(() {
      selectedShape = shape;
      showHint = false;
      hintBlinkTimer?.cancel();
      hintBlinkOn = false;
    });

    final correct = shape == targetShape;

    if (correct) {
      wrongStreak = 0;
      await Sfx.correct(soundOn);
      await hapticCorrect(hapticsOn);

      setState(() => score += 10);

      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && gameActive && !isGameOver) generateNewTarget();
      });
    } else {
      wrongStreak++;
      await Sfx.wrong(soundOn);
      await hapticWrong(hapticsOn);

      if (wrongStreak >= 3) {
        wrongStreak = 0;
        startHintBlink();
      }
    }
  }

  void endGame() {
    timer?.cancel();
    hintBlinkTimer?.cancel();

    setState(() {
      gameActive = false;
      isGameOver = true;
      showHint = false;
      hintBlinkOn = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 හැඩ ගැළපීම සම්පූර්ණයි!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('මගේ ලකුණු:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            const Text(
              'පොඩ්ඩක් ඉන්න...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      widget.onGameComplete(score);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    hintBlinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('හැඩ ගලපමු'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(
              showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              size: 30,
            ),
            onPressed: toggleHint,
            tooltip: 'උදව්',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.yellow.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text('මගේ ලකුණු:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('ඉතිරි කාලය:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$timeLeft',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: timeLeft <= 10 ? Colors.red : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'මේ හැඩය ගලපමු:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 550),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: Container(
                key: ValueKey(roundKey),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: targetCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(100, 100),
                    painter: ShapePainter(targetShape, Colors.blue),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final tileW = (c.maxWidth - 20) / 2;
                  final tileH = (c.maxHeight - 20) / 2;
                  final ratio = tileW / tileH;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: ratio,
                    ),
                    itemCount: shapes.length,
                    itemBuilder: (context, index) {
                      final shape = shapes[index];

                      final isSelected = selectedShape == shape;
                      final isCorrect = isSelected && shape == targetShape;
                      final isWrong = isSelected && shape != targetShape;

                      final isHintTarget = showHint && (shape == targetShape);
                      final blinkGreen = isHintTarget && hintBlinkOn;

                      return GestureDetector(
                        onTap: () => checkMatch(shape),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.shade300
                                : isWrong
                                ? Colors.red.shade300
                                : (blinkGreen
                                      ? Colors.green.shade300
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                            border: Border.all(
                              color: blinkGreen
                                  ? Colors.white
                                  : Colors.transparent,
                              width: blinkGreen ? 3 : 0,
                            ),
                          ),
                          child: Center(
                            child: CustomPaint(
                              size: const Size(80, 80),
                              painter: ShapePainter(
                                shape,
                                (isCorrect || isWrong || blinkGreen)
                                    ? Colors.white
                                    : Colors.purple,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  final String shape;
  final Color color;

  ShapePainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (shape) {
      case 'circle':
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          size.width / 2,
          paint,
        );
        break;
      case 'square':
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
      case 'triangle':
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'rectangle':
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.2, 0, size.width * 0.6, size.height),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// =====================================
/// Color Match Game
/// =====================================
class ColorMatchGame extends StatefulWidget {
  final Function(int score) onGameComplete;

  const ColorMatchGame({Key? key, required this.onGameComplete})
    : super(key: key);

  @override
  State<ColorMatchGame> createState() => _ColorMatchGameState();
}

class _ColorMatchGameState extends State<ColorMatchGame> {
  static const String firstPlayKey = 'color_first_play_done';

  int score = 0;
  int timeLeft = 50;
  Timer? timer;

  bool gameActive = false;
  bool isGameOver = false;

  Color? selectedColor;

  final Map<String, Color> colorOptions = {
    'රතු': const Color(0xFFDC143C),
    'ලා නිල්': const Color(0xFF87CEEB),
    'කොල': const Color(0xFF00FF00),
    'කහ': const Color(0xFFFFFF00),
  };

  String targetColorName = '';
  Color targetColor = Colors.white;
  Color? lastTargetColor;

  int roundKey = 0;
  late Color targetCardBg;

  final List<Color> pastelColors = [
    const Color(0xFFFFF3E0),
    const Color(0xFFE3F2FD),
    const Color(0xFFE8F5E9),
    const Color(0xFFFCE4EC),
    const Color(0xFFF3E5F5),
    const Color(0xFFFFFDE7),
  ];

  bool showHint = false;
  Timer? hintBlinkTimer;
  bool hintBlinkOn = false;
  int hintBlinkTicks = 0;

  int wrongStreak = 0;

  bool soundOn = true;
  bool hapticsOn = true;

  @override
  void initState() {
    super.initState();
    targetCardBg = pastelColors[1];
    _loadSettingsAndStart();
  }

  Future<void> _loadSettingsAndStart() async {
    soundOn = await AppSettings.getSoundOn();
    hapticsOn = await AppSettings.getHapticsOn();
    if (mounted) setState(() {});
    await _checkFirstAttemptAndStart();
  }

  Future<void> _checkFirstAttemptAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    final firstDone = prefs.getBool(firstPlayKey) ?? false;

    startGame();

    if (!firstDone) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted && gameActive && !isGameOver) startHintBlink();
      });
      await prefs.setBool(firstPlayKey, true);
    }
  }

  void toggleHint() => startHintBlink();

  void startHintBlink() {
    hintBlinkTimer?.cancel();

    setState(() {
      // ✅ FIX: clear previous selection so hint can highlight the correct tile
      selectedColor = null;

      showHint = true;
      hintBlinkOn = true;
      hintBlinkTicks = 0;
    });

    hintBlinkTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted) return;

      setState(() {
        hintBlinkOn = !hintBlinkOn;
        hintBlinkTicks++;
      });

      if (hintBlinkTicks >= 10) {
        t.cancel();
        if (!mounted) return;
        setState(() {
          showHint = false;
          hintBlinkOn = false;
        });
      }
    });
  }

  void startGame() {
    setState(() {
      score = 0;
      wrongStreak = 0;
      timeLeft = 50;
      gameActive = true;
      isGameOver = false;
    });

    generateNewTarget();

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          endGame();
        }
      });
    });
  }

  void generateNewTarget() {
    final rnd = Random();
    final entries = colorOptions.entries.toList();

    MapEntry<String, Color> next = entries[rnd.nextInt(entries.length)];
    if (lastTargetColor != null && entries.length > 1) {
      while (next.value == lastTargetColor) {
        next = entries[rnd.nextInt(entries.length)];
      }
    }

    hintBlinkTimer?.cancel();
    showHint = false;
    hintBlinkOn = false;

    setState(() {
      lastTargetColor = next.value;
      targetColorName = next.key;
      targetColor = next.value;
      selectedColor = null;

      roundKey++;
      targetCardBg = pastelColors[rnd.nextInt(pastelColors.length)];
    });

    HapticFeedback.selectionClick();
  }

  Future<void> checkMatch(String colorName, Color color) async {
    if (!gameActive || isGameOver) return;

    setState(() {
      selectedColor = color;
      showHint = false;
      hintBlinkTimer?.cancel();
      hintBlinkOn = false;
    });

    final correct = color == targetColor;

    if (correct) {
      wrongStreak = 0;
      await Sfx.correct(soundOn);
      await hapticCorrect(hapticsOn);

      setState(() => score += 10);

      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted && gameActive && !isGameOver) generateNewTarget();
      });
    } else {
      wrongStreak++;
      await Sfx.wrong(soundOn);
      await hapticWrong(hapticsOn);

      if (wrongStreak >= 3) {
        wrongStreak = 0;
        startHintBlink();
      }
    }
  }

  void endGame() {
    timer?.cancel();
    hintBlinkTimer?.cancel();

    setState(() {
      gameActive = false;
      isGameOver = true;
      showHint = false;
      hintBlinkOn = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 පාට ගැලපීම සම්පුර්ණයි!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('මගේ ලකුණු:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            const Text(
              'පොඩ්ඩක් ඉන්න...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      widget.onGameComplete(score);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    hintBlinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('පාට ගලපමු'),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: Icon(
              showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              size: 30,
            ),
            onPressed: toggleHint,
            tooltip: 'උදව්',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade100, Colors.purple.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text('මගේ ලකුණු:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('ඉතිරි කාලය:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$timeLeft',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: timeLeft <= 10 ? Colors.red : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'මේ පාට ගලපමු:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              targetColorName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 550),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: Container(
                key: ValueKey(roundKey),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: targetCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: targetColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final tileW = (c.maxWidth - 20) / 2;
                  final tileH = (c.maxHeight - 20) / 2;
                  final ratio = tileW / tileH;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: ratio,
                    ),
                    itemCount: colorOptions.length,
                    itemBuilder: (context, index) {
                      final entry = colorOptions.entries.elementAt(index);

                      final isSelected = selectedColor == entry.value;
                      final isCorrect =
                          isSelected && entry.value == targetColor;
                      final isWrong = isSelected && entry.value != targetColor;

                      final isHintTarget =
                          showHint && (entry.value == targetColor);
                      final blinkGreen = isHintTarget && hintBlinkOn;

                      return GestureDetector(
                        onTap: () => checkMatch(entry.key, entry.value),
                        child: Container(
                          decoration: BoxDecoration(
                            color: blinkGreen ? Colors.white : entry.value,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: blinkGreen
                                  ? Colors.green
                                  : (isCorrect
                                        ? Colors.green
                                        : (isWrong
                                              ? Colors.red
                                              : Colors.white)),
                              width: blinkGreen ? 6 : (isSelected ? 5 : 3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              entry.key,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: blinkGreen
                                    ? Colors.green.shade900
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================================
/// Pop Bubbles Game
/// =====================================
class PopBubblesGame extends StatefulWidget {
  final Function(int score) onGameComplete;

  const PopBubblesGame({Key? key, required this.onGameComplete})
    : super(key: key);

  @override
  State<PopBubblesGame> createState() => _PopBubblesGameState();
}

class Bubble {
  double x;
  double y;
  Color color;
  String id;

  Bubble({
    required this.x,
    required this.y,
    required this.color,
    required this.id,
  });
}

class _PopBubblesGameState extends State<PopBubblesGame>
    with SingleTickerProviderStateMixin {
  static const String firstPlayKey = 'pop_first_play_done';

  int score = 0;
  int timeLeft = 50;

  Timer? gameTimer;
  Timer? spawnTimer;

  bool gameActive = false;
  bool isGameOver = false;

  List<Bubble> bubbles = [];

  late AnimationController anim;

  bool soundOn = true;
  bool hapticsOn = true;

  Bubble? hintBubble;
  bool hintBlinkOn = false;
  Timer? hintBlinkTimer;
  int hintBlinkTicks = 0;

  final List<Color> bubbleColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 32),
    )..addListener(updateBubbles);

    _loadSettingsAndStart();
  }

  Future<void> _loadSettingsAndStart() async {
    soundOn = await AppSettings.getSoundOn();
    hapticsOn = await AppSettings.getHapticsOn();
    if (mounted) setState(() {});
    await _checkFirstAttemptAndStart();
  }

  Future<void> _checkFirstAttemptAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    final firstDone = prefs.getBool(firstPlayKey) ?? false;

    startGame();

    if (!firstDone) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted || bubbles.isEmpty || isGameOver) return;
        _startBlinkOnBubble(bubbles.first);
      });
      await prefs.setBool(firstPlayKey, true);
    }
  }

  void startGame() {
    setState(() {
      score = 0;
      timeLeft = 50;
      gameActive = true;
      isGameOver = false;
      bubbles.clear();
      hintBubble = null;
      hintBlinkOn = false;
      hintBlinkTicks = 0;
    });

    anim.repeat();

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          endGame();
        }
      });
    });

    spawnTimer?.cancel();
    spawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (t) {
      if (!mounted || isGameOver) return;
      spawnBubble();
    });
  }

  void spawnBubble() {
    final r = Random();
    setState(() {
      bubbles.add(
        Bubble(
          x: r.nextDouble() * 0.8 + 0.1,
          y: 1.2,
          color: bubbleColors[r.nextInt(bubbleColors.length)],
          id: DateTime.now().microsecondsSinceEpoch.toString(),
        ),
      );
    });
  }

  void updateBubbles() {
    if (!mounted) return;
    setState(() {
      bubbles = bubbles.where((b) {
        b.y -= 0.003;
        return b.y > -0.1;
      }).toList();
    });
  }

  void onHintPressed() {
    if (!mounted || bubbles.isEmpty || isGameOver) return;
    final size = MediaQuery.of(context).size;
    final centerBubble = _pickCenterBubble(size);
    _startBlinkOnBubble(centerBubble);
  }

  Bubble _pickCenterBubble(Size size) {
    Bubble best = bubbles.first;
    double bestDist = double.infinity;

    for (final b in bubbles) {
      final px = b.x * size.width;
      final py = b.y * size.height;
      final dx = px - size.width / 2;
      final dy = py - size.height / 2;
      final d = dx * dx + dy * dy;
      if (d < bestDist) {
        bestDist = d;
        best = b;
      }
    }
    return best;
  }

  void _startBlinkOnBubble(Bubble b) {
    hintBlinkTimer?.cancel();

    setState(() {
      hintBubble = b;
      hintBlinkOn = true;
      hintBlinkTicks = 0;
    });

    hintBlinkTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted) return;
      setState(() {
        hintBlinkOn = !hintBlinkOn;
        hintBlinkTicks++;
      });

      if (hintBlinkTicks >= 10) {
        t.cancel();
        if (!mounted) return;
        setState(() {
          hintBlinkOn = false;
          hintBubble = null;
        });
      }
    });
  }

  Future<void> popBubble(Bubble b) async {
    if (!gameActive || isGameOver) return;

    setState(() {
      bubbles.removeWhere((x) => x.id == b.id);
      score += 5;
      if (hintBubble?.id == b.id) {
        hintBubble = null;
        hintBlinkOn = false;
      }
    });

    await Sfx.correct(soundOn);
    await hapticCorrect(hapticsOn);
  }

  void endGame() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    hintBlinkTimer?.cancel();
    anim.stop();

    setState(() {
      gameActive = false;
      isGameOver = true;
      hintBubble = null;
      hintBlinkOn = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 බෝල පිපිරවීම සම්පුර්ණයි!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('මගේ ලකුණු:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            const Text(
              'මුළු ලකුණු ගණනය කරමින්...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      widget.onGameComplete(score);
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    hintBlinkTimer?.cancel();
    anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('බෝල පුපුරවමු'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, size: 30),
            onPressed: onHintPressed,
            tooltip: 'උදව්',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text('මගේ ලකුණු:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('ඉතිරි කාලය:', style: TextStyle(fontSize: 16)),
                      Text(
                        '$timeLeft',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: timeLeft <= 10 ? Colors.red : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: bubbles.map((b) {
                  final isHint = hintBubble?.id == b.id && hintBlinkOn;

                  return Positioned(
                    left: b.x * size.width - 30,
                    top: b.y * size.height - 30,
                    child: GestureDetector(
                      onTap: () => popBubble(b),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHint ? Colors.green : b.color,
                          border: Border.all(
                            color: isHint ? Colors.white : Colors.transparent,
                            width: isHint ? 4 : 0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
