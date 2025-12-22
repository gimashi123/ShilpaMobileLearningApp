import 'package:flutter/material.dart';
import '../services/braille_pdf_service.dart';

class BraillePdfPage extends StatelessWidget {
  const BraillePdfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Braille PDF")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await BraillePdfService.generateAndOpenPdf(
                    type: "math",
                    title: "Math Quiz 10",
                    items: List.generate(10, (i) => {"q": "${i + 1}+1=?"}),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to generate PDF")),
                  );
                }
              },
              child: const Text("Generate Math Braille PDF (10)"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                try {
                  await BraillePdfService.generateAndOpenPdf(
                    type: "sinhala",
                    title: "සිංහල Quiz 5",
                    items: [
                      {"q": "අ"},
                      {"q": "ක"},
                      {"q": "ද"},
                      {"q": "අ ක"},
                      {"q": "ක ද"},
                    ],
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to generate PDF")),
                  );
                }
              },
              child: const Text("Generate Sinhala Braille PDF (5)"),
            ),
          ],
        ),
      ),
    );
  }
}
