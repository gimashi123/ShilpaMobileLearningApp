import 'package:flutter/material.dart';
import 'package:mobile_app/pages/auth/create_account_screen.dart';
import 'package:mobile_app/pages/auth/login_screen.dart';
import 'package:mobile_app/pages/dashboard/cognative_dashboard_screen.dart';
import 'package:mobile_app/pages/dashboard/dashboard_screen.dart';
import 'package:mobile_app/pages/dashboard/hearing_dashboard_screen.dart';
import 'package:mobile_app/pages/dashboard/visual_dashboard_screen.dart';
import 'package:mobile_app/pages/landing_screen.dart';
import 'package:mobile_app/pages/auth/create_account_blind_screen.dart';
import 'package:mobile_app/pages/quiz.dart';
import 'package:mobile_app/pages/subject/maths_screen.dart';
import 'package:mobile_app/pages/physical/physical_main_screen.dart';

// Speech service
import 'package:mobile_app/services/speech_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("LOG: main() started");

  // Start Flutter UI first
  runApp(const MyApp());

  // Initialize Speech-to-Text in background (do NOT block UI)
  // If this is heavy, it won't freeze the splash screen now.
  SpeechService.instance
      .init()
      .then((_) {
        print("LOG: SpeechService init completed");
      })
      .catchError((e, st) {
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
        '/': (_) => const HomePage(),
        '/dashboard': (_) => const DashboardScreen(),
        '/register': (_) => const RegisterPage(disabilityType: ''),
        '/blindregister': (_) => const BlindRegisterPage(),
        '/newlogin': (_) => const LoginPage(),

        // disability-type navigation
        '/home_visual': (_) => const VisualDashboardScreen(),
        '/home_hearing': (_) => const HearingDashboardScreen(),
        '/home_physical': (_) => const PhysicalMainScreen(),
        '/home_cognitive': (_) => const CognativeDashboardScreen(),

        '/math_lessons': (_) => const StudentLessonsPage(),
        '/quiz': (_) => const QuizPage(),
      },
    );
  }
}

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
          builder: (context, c) {
            final isWide = c.maxWidth >= 700;
            final content = _DetailsPanel();

            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(),
                      child: Image.asset(
                        'assets/homepage.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(flex: 2, child: content),
                ],
              );
            } else {
              return Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      'assets/mobile_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(child: content),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: cs.surfaceContainerHighest,
                backgroundImage: const AssetImage('assets/mobile_logo.png'),
              ),
              const SizedBox(height: 16),
              Text(
                'Shilpa',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ශිෂ්‍යයන් සඳහා සවිබල ගැන්වු ලෝකය',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  label: const Text(
                    'ආරම්භ කරමු',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: const StadiumBorder(),
                    foregroundColor: Colors.white,
                    backgroundColor: Color.fromARGB(255, 195, 90, 213),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChooseDisabilityPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
