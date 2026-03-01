import 'package:flutter/material.dart';
import 'package:mobile_app/pages/models/cognitive.dart';
import 'package:mobile_app/services/cognitive.dart';

class ProgressHistoryScreen extends StatefulWidget {
  final String studentId;
  const ProgressHistoryScreen({super.key, required this.studentId});

  @override
  State<ProgressHistoryScreen> createState() => _ProgressHistoryScreenState();
}

class _ProgressHistoryScreenState extends State<ProgressHistoryScreen> {
  Future<List<LdAttempt>>? _future;

  @override
  void initState() {
    super.initState();

    // ✅ Student ID තිබේ නම් පමණක් API call කරන්න
    if (widget.studentId.trim().isNotEmpty) {
      _future = LdHistoryApi.fetchHistoryByStudentId(widget.studentId.trim());
    } else {
      _future = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ❌ Student ID නැතිනම්
    if (widget.studentId.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("ප්‍රගති ඉතිහාසය")),
        body: const Center(
          child: Text(
            "ප්‍රගති ඉතිහාසය පෙන්විය නොහැක.\nශිෂ්‍ය හැඳුනුම් අංකය නොමැත.\nකරුණාකර නැවත ලොග් වන්න.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("ප්‍රගති ඉතිහාසය")),
      body: FutureBuilder<List<LdAttempt>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                "ප්‍රගති ඉතිහාසය ලබාගැනීම අසාර්ථකයි.\n${snap.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }

          final attempts = snap.data ?? [];

          // 🟡 තවම ක්‍රීඩා කර නොමැතිනම්
          if (attempts.isEmpty) {
            return const Center(
              child: Text(
                "මුලින්ම IQ ක්‍රීඩාව ක්‍රීඩා කරන්න",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = attempts[i];

              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "උත්සාහය ${attempts.length - i} • ${a.createdAt.toLocal()}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("ඇස්තමේන්තු මට්ටම: ${a.predLabel}"),
                      const SizedBox(height: 6),
                      Text("හැඩ ක්‍රීඩා ලකුණු: ${a.shapeGameScore}"),
                      Text("වර්ණ ක්‍රීඩා ලකුණු: ${a.colorGameScore}"),
                      Text("බුබුළු ක්‍රීඩා ලකුණු: ${a.bubbleGameScore}"),
                      const Divider(height: 16),
                      Text(
                        "මුළු ලකුණු: ${a.totalGameScore}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
