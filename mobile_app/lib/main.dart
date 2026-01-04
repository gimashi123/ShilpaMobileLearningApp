import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Your pages
import 'package:mobile_app/lesson_dashboard/hearing_lesson.dart';
import 'package:mobile_app/pages/auth/create_account_blind_screen.dart';
import 'package:mobile_app/pages/auth/create_account_screen.dart';
import 'package:mobile_app/pages/auth/login_screen.dart';
import 'package:mobile_app/pages/dashboard/cognative_dashboard_screen.dart';
import 'package:mobile_app/pages/dashboard/dashboard_screen.dart';
import 'package:mobile_app/pages/dashboard/hearing_dashboard_screen.dart';
import 'package:mobile_app/pages/dashboard/physical_dashboard_screen.dart';
import 'package:mobile_app/pages/dashboard/visual_dashboard_screen.dart';
import 'package:mobile_app/pages/games/visual_game_dashboard.dart';
import 'package:mobile_app/pages/games/visual_math_gamecard.dart';
import 'package:mobile_app/pages/games/visual_math_quick_game.dart';
import 'package:mobile_app/pages/games/hearing_game_dashboard.dart';
import 'package:mobile_app/pages/games/level1_math_gamedeaf.dart';
import 'package:mobile_app/pages/landing_screen.dart';
import 'package:mobile_app/pages/profile_screen.dart';
import 'package:mobile_app/pages/quiz.dart';
import 'package:mobile_app/pages/quiz/hearing_quiz_screen.dart';
import 'package:mobile_app/pages/quiz/quiz_hub.dart';
import 'package:mobile_app/pages/subject/hearing_math.dart';
import 'package:mobile_app/pages/subject/lessons.dart';
import 'package:mobile_app/pages/subject/maths_screen.dart';
import 'package:mobile_app/pages/visual_lesson_dashboard.dart';
import 'package:mobile_app/pages/visual_quiz_dashboard.dart';
import 'package:mobile_app/pages/games/more_or_less_game.dart';
// Speech service
import 'package:mobile_app/services/speech_service.dart';

// ✅ Global cameras list
late final List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("LOG: main() started");

  // ✅ Load cameras BEFORE runApp (IMPORTANT)
  try {
    cameras = await availableCameras();
    print("LOG: cameras loaded: ${cameras.length}");
  } catch (e) {
    // If camera fails, keep empty list to avoid crash
    print("ERROR: availableCameras failed: $e");
    cameras = <CameraDescription>[];
  }

  // Start Flutter UI
  runApp(const MyApp());

  // Initialize Speech-to-Text in background (do NOT block UI)
  SpeechService.instance.init().then((_) {
    print("LOG: SpeechService init completed");
  }).catchError((e) {
    print("ERROR: SpeechService init failed: $e");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shilpa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      initialRoute: '/',
      routes: {
        // common navigation
        '/': (_) => const HomePage(),
        '/dashboard': (_) => const DashboardScreen(),
        '/register': (_) => const RegisterPage(disabilityType: ''),
        '/blindregister': (_) => const BlindRegisterPage(),
        '/newlogin': (_) => const LoginPage(),

        // disability-type navigation
        '/home_visual': (_) => const VisualDashboardScreen(),
        '/home_hearing': (_) => const HearingDashboardScreen(),
        '/home_physical': (_) => const PhysicalDashboardScreen(),
        '/home_cognitive': (_) => const CognativeDashboardScreen(),

        '/math_lessons': (_) => const StudentLessonsPage(),

        // visual navigation
        '/quizdashboard': (_) => const VisualQuizDashboard(),
        '/lessons': (_) => const VisualLessonDashboard(),
        '/quiz': (_) => const QuizPage(),

        // hearing navigation
        '/quizhear': (_) => const QuizPageSimple(),
        '/general_quiz': (_) => const QuizHubPage(),
        '/hearing_lessons': (_) => const HearingLesson(),
        '/profile': (_) => const ProfileScreen(),
        '/lessons': (_) => const VisualLessonDashboard(),
        '/visual_game_dashboard': (_) => const VisualGameDashboard(),
        '/visual_math_gamecard': (_) => const AvailableGamesPage(),

        '/math_quick_game': (context) => const NumberMatchLevelsSound(),
        '/visual_more_or_less_game': (context) => const MoreNumberSwipeGame(),
        '/hearing_games_dashboard': (_) => const HearingGameDashboard(),

        // ✅ FIXED: pass real cameras list (NOT [])
        '/hearing_games': (_) => Level1MathGameDeaf(cameras: cameras),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/quizhearing') {
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
        return null;
      },
    );
  }
}

// ---------------- HOME PAGE (your existing code) ----------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8E9FF), Color.fromARGB(255, 186, 173, 247)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            // Check if it's a phone (width < 600) or tablet
            final isPhone = screenWidth < 600;
            // Check if it's a small phone (height < 700)
            final isSmallPhone = screenHeight < 700;

            if (isPhone) {
              // Phone layout - vertical
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight),
                  child: Column(
                    children: [
                      // Top image section
                      Container(
                        height: isSmallPhone
                            ? screenHeight * 0.35
                            : screenHeight * 0.4,
                        width: double.infinity,
                        decoration: const BoxDecoration(),
                        child: Image.asset(
                          'assets/mobile_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Content section
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallPhone ? 20.0 : 24.0,
                          vertical: isSmallPhone ? 16.0 : 24.0,
                        ),
                        child: _PhoneContentPanel(
                          isSmallPhone: isSmallPhone,
                          screenWidth: screenWidth,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // Tablet layout - horizontal
              return Row(
                children: [
                  // Left image section
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: double.infinity,
                      decoration: const BoxDecoration(),
                      child: Image.asset(
                        'assets/homepage.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Right content section
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.all(
                          screenWidth > 900 ? 32.0 : 24.0,
                        ),
                        child: _TabletContentPanel(screenWidth: screenWidth),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class _PhoneContentPanel extends StatelessWidget {
  final bool isSmallPhone;
  final double screenWidth;

  const _PhoneContentPanel({
    required this.isSmallPhone,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Calculate responsive values for phones
    final double avatarSize = isSmallPhone ? 70.0 : 88.0;
    final double titleFontSize = isSmallPhone ? 28.0 : 32.0;
    final double subtitleFontSize = isSmallPhone ? 14.0 : 16.0;
    final double buttonFontSize = isSmallPhone ? 16.0 : 20.0;
    final double buttonHeight = isSmallPhone ? 48.0 : 56.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: avatarSize / 2,
          backgroundColor: cs.surfaceContainerHighest,
          backgroundImage: const AssetImage('assets/mobile_logo.png'),
        ),
        SizedBox(height: isSmallPhone ? 12.0 : 16.0),

        Text(
          'Shilpa',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: titleFontSize,
          ),
        ),

        SizedBox(height: isSmallPhone ? 4.0 : 6.0),

        Text(
          'ශිෂ්‍යයන් සඳහා සවිබල ගැන්වු ලෝකය',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: subtitleFontSize),
        ),

        SizedBox(height: isSmallPhone ? 20.0 : 24.0),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            label: Text(
              'ආරම්භ කරමු',
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(buttonHeight),
              shape: const StadiumBorder(),
              foregroundColor: Colors.white,
              backgroundColor: const Color.fromARGB(255, 195, 90, 213),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallPhone ? 16.0 : 24.0,
                vertical: 16.0,
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChooseDisabilityPage()),
              );
            },
            icon: Icon(Icons.play_arrow, size: buttonFontSize * 1.2),
          ),
        ),

        SizedBox(height: isSmallPhone ? 16.0 : 20.0),

        // Optional: Add more content for phones if needed
        if (!isSmallPhone) ...[
          const Divider(height: 30),
          Text(
            '',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _TabletContentPanel extends StatelessWidget {
  final double screenWidth;

  const _TabletContentPanel({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Calculate responsive values for tablets
    final bool isLargeTablet = screenWidth > 900;
    final double avatarSize = isLargeTablet ? 120.0 : 100.0;
    final double titleFontSize = isLargeTablet ? 40.0 : 36.0;
    final double buttonFontSize = isLargeTablet ? 22.0 : 20.0;
    final double buttonHeight = isLargeTablet ? 65.0 : 60.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isLargeTablet ? 500.0 : 400.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: cs.surfaceContainerHighest,
              backgroundImage: const AssetImage('assets/mobile_logo.png'),
            ),

            SizedBox(height: isLargeTablet ? 24.0 : 20.0),

            Text(
              'Shilpa',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: titleFontSize,
              ),
            ),

            SizedBox(height: isLargeTablet ? 12.0 : 8.0),

            Text(
              'ශිෂ්‍යයන් සඳහා සවිබල ගැන්වු ලෝකය',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: isLargeTablet ? 18.0 : 16.0,
              ),
            ),

            SizedBox(height: isLargeTablet ? 32.0 : 28.0),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                label: Text(
                  'ආරම්භ කරමු',
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(buttonHeight),
                  shape: const StadiumBorder(),
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 195, 90, 213),
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 20.0,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChooseDisabilityPage(),
                    ),
                  );
                },
                icon: Icon(Icons.play_arrow, size: buttonFontSize * 1.2),
              ),
            ),

            SizedBox(height: isLargeTablet ? 32.0 : 28.0),

            // Additional info for tablets
            const Divider(),
            SizedBox(height: 20.0),

            Text(
              'Supported Features:',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 16.0),

            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              alignment: WrapAlignment.center,
              children: [
                Chip(
                  avatar: const Icon(Icons.visibility, size: 16),
                  label: const Text('Visual Support'),
                ),
                Chip(
                  avatar: const Icon(Icons.hearing, size: 16),
                  label: const Text('Hearing Support'),
                ),
                Chip(
                  avatar: const Icon(Icons.accessible, size: 16),
                  label: const Text('Accessibility'),
                ),
                Chip(
                  avatar: const Icon(Icons.school, size: 16),
                  label: const Text('Learning Tools'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Add the missing ChooseDisabilityPage class for navigation to work
