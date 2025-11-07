import 'package:flutter/material.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF6B38FB), Color(0xFF22073E)], // soft purple → deep purple
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF16082B),                // inner dark panel
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF8E5BFF), width: 6), // thick outer purple border
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message ?? 'ඔබේ විශේෂ අවශ්‍යතාවය තෝරන්න',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2×2 responsive grid of buttons
                  Wrap(
                    spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
                    children: [
                      ModuleTile(
                        asset: 'assets/visual.png',
                        onTap: () { /* Navigator.pushNamed(context, '/visual'); */ },
                      ),
                      ModuleTile(
                        asset: 'assets/hearing.png',
                        onTap: () { /* Navigator.pushNamed(context, '/hearing'); */ },
                      ),
                      ModuleTile(
                        asset: 'assets/physical.png',
                        onTap: () { /* Navigator.pushNamed(context, '/physical'); */ },
                      ),
                      ModuleTile(
                        asset: 'assets/cognitive.png',
                        onTap: () { /* Navigator.pushNamed(context, '/cognitive'); */ },
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
}

/// One square button with rounded corners, purple border, shadow
class ModuleTile extends StatelessWidget {
  const ModuleTile({super.key, required this.asset, required this.onTap});
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 150, height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E7F0),                // light gray inside
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB388FF), width: 3), // purple outline
          boxShadow: [
            BoxShadow(color: const Color(0xFFB388FF).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: Image.asset(asset, width: 64, height: 64, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
