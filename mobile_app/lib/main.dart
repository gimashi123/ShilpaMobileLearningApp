import 'package:flutter/material.dart';
import 'package:mobile_app/pages/landing_page.dart';

void main() => runApp(const MyApp());

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
      ),),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 700; // Row on wide screens, Column on phones
            final content = _DetailsPanel();

            if (isWide) {
              return Row(
                children: [
                  // LEFT: Image
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
                  // RIGHT: Details
                  Expanded(
                    flex: 2,
                    child: content,
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  // TOP: Image
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      'assets/mobile_logo.png',
                      fit: BoxFit.cover,
                      
                    ),
                  ),
                  // BOTTOM: Details
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
              // Logo
              CircleAvatar(
                radius: 44,
                backgroundColor: cs.surfaceContainerHighest,
                backgroundImage: const AssetImage('assets/mobile_logo.png'),
              ),
              const SizedBox(height: 16),
              // App name + tagline (Sinhala optional)
              Text('Shilpa', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('ශිෂ්‍යයන් සඳහා සවිබල ගැන්වු ලෝකය',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  label: const Text(('ආරම්භ කරමු'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: const StadiumBorder(),
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255), // icon/text color
                    backgroundColor: const Color.fromARGB(255, 195, 90, 213), // button background color
                    iconColor: Colors.purple,
                  ),
                  onPressed: () {
                     Navigator.of(context).push(
                     MaterialPageRoute(builder: (_) => const SecondPage()),
                    );
                  },
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


