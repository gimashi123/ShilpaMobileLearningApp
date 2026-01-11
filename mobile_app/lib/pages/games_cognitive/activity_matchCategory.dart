import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SortingGameApp extends StatelessWidget {
  const SortingGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sorting & Categorizing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const SortingCategorizingGame(),
    );
  }
}

// =========================
// DATA MODELS
// =========================
enum Rule { type, color, size }

enum ItemType { food, animal }

enum ItemSize { small, big }

class SortItem {
  final String id;
  final String emoji;       // easy visuals for kids (no assets needed)
  final String name;        // spoken name
  final ItemType type;
  final String color;       // "red", "green", "blue"
  final ItemSize size;

  const SortItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.type,
    required this.color,
    required this.size,
  });
}

class Bucket {
  final String id;
  final String title;
  final IconData icon;

  const Bucket({required this.id, required this.title, required this.icon});
}

// =========================
// GAME SCREEN
// =========================
class SortingCategorizingGame extends StatefulWidget {
  const SortingCategorizingGame({super.key});

  @override
  State<SortingCategorizingGame> createState() => _SortingCategorizingGameState();
}

class _SortingCategorizingGameState extends State<SortingCategorizingGame> {
  final FlutterTts _tts = FlutterTts();
  final Random _rng = Random();

  Rule _rule = Rule.type;
  int _score = 0;

  // Items
  late List<SortItem> _allItems;
  late List<SortItem> _remaining;

  // Track correctly placed items (so they disappear)
  final Set<String> _placedIds = {};

  @override
  void initState() {
    super.initState();
    _setupTts();
    _buildItems();
    _startNewRound(rule: Rule.type);
  }

  Future<void> _setupTts() async {
    // These settings may vary per device; safe defaults:
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    // If Sinhala is needed later: try "si-LK" (device dependent).
    // await _tts.setLanguage("en-US");
  }

  void _buildItems() {
    // Keep it small and clear
    _allItems = const [
      // FOOD
      SortItem(
        id: "apple",
        emoji: "🍎",
        name: "Apple",
        type: ItemType.food,
        color: "red",
        size: ItemSize.small,
      ),
      SortItem(
        id: "broccoli",
        emoji: "🥦",
        name: "Broccoli",
        type: ItemType.food,
        color: "green",
        size: ItemSize.big,
      ),
      SortItem(
        id: "blueberries",
        emoji: "🫐",
        name: "Blue berries",
        type: ItemType.food,
        color: "blue",
        size: ItemSize.small,
      ),

      // ANIMALS
      SortItem(
        id: "dog",
        emoji: "🐶",
        name: "Dog",
        type: ItemType.animal,
        color: "brown",
        size: ItemSize.big,
      ),
      SortItem(
        id: "cat",
        emoji: "🐱",
        name: "Cat",
        type: ItemType.animal,
        color: "orange",
        size: ItemSize.small,
      ),
      SortItem(
        id: "elephant",
        emoji: "🐘",
        name: "Elephant",
        type: ItemType.animal,
        color: "gray",
        size: ItemSize.big,
      ),
    ];
  }

  void _startNewRound({required Rule rule}) {
    setState(() {
      _rule = rule;
      _score = 0;
      _placedIds.clear();

      // Shuffle and pick a manageable number
      final items = List<SortItem>.from(_allItems)..shuffle(_rng);
      _remaining = items.take(6).toList();
    });

    _speakPrompt();
  }

  Future<void> _speakPrompt() async {
    final text = switch (_rule) {
      Rule.type => "Sort by type. Food versus animals.",
      Rule.color => "Sort by color. Red versus green.",
      Rule.size => "Sort by size. Small versus big.",
    };
    await _tts.stop();
    await _tts.speak(text);
  }

  List<Bucket> _getBucketsForRule() {
    switch (_rule) {
      case Rule.type:
        return const [
          Bucket(id: "food", title: "FOOD", icon: Icons.restaurant),
          Bucket(id: "animal", title: "ANIMALS", icon: Icons.pets),
        ];
      case Rule.color:
        // Keep it ONE rule with TWO groups. Use only red/green for simplicity.
        return const [
          Bucket(id: "red", title: "RED", icon: Icons.circle),
          Bucket(id: "green", title: "GREEN", icon: Icons.circle),
        ];
      case Rule.size:
        return const [
          Bucket(id: "small", title: "SMALL", icon: Icons.crop_square),
          Bucket(id: "big", title: "BIG", icon: Icons.check_box_outline_blank),
        ];
    }
  }

  bool _isCorrectBucket(SortItem item, String bucketId) {
    switch (_rule) {
      case Rule.type:
        return (bucketId == "food" && item.type == ItemType.food) ||
            (bucketId == "animal" && item.type == ItemType.animal);

      case Rule.color:
        // Only classify red/green; other colors become "wrong" (you can remove them if you want)
        return (bucketId == "red" && item.color == "red") ||
            (bucketId == "green" && item.color == "green");

      case Rule.size:
        return (bucketId == "small" && item.size == ItemSize.small) ||
            (bucketId == "big" && item.size == ItemSize.big);
    }
  }

  int get _targetCount {
    // Count items that are actually classifiable for the rule (important for color rule)
    if (_rule != Rule.color) return _remaining.length;
    return _remaining.where((i) => i.color == "red" || i.color == "green").length;
  }

  Future<void> _onCorrect(SortItem item) async {
    setState(() {
      _placedIds.add(item.id);
      _score += 1;
    });

    await _tts.stop();
    await _tts.speak("Good job!");

    if (_score >= _targetCount && _targetCount > 0) {
      await _tts.speak("Amazing! You finished!");
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text("⭐ Great job! ⭐"),
          content: const Text("You sorted everything correctly!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onWrong() async {
    await _tts.stop();
    await _tts.speak("Try again.");
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _getBucketsForRule();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (_rule) {
            Rule.type => "Sort: Type",
            Rule.color => "Sort: Color",
            Rule.size => "Sort: Size",
          },
        ),
        actions: [
          IconButton(
            tooltip: "Speak",
            onPressed: _speakPrompt,
            icon: const Icon(Icons.volume_up),
          ),
          IconButton(
            tooltip: "Reset",
            onPressed: () => _startNewRound(rule: _rule),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Rule selector (one rule at a time)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _RuleChip(
                    label: "TYPE",
                    selected: _rule == Rule.type,
                    onTap: () => _startNewRound(rule: Rule.type),
                  ),
                  _RuleChip(
                    label: "COLOR (Red/Green)",
                    selected: _rule == Rule.color,
                    onTap: () => _startNewRound(rule: Rule.color),
                  ),
                  _RuleChip(
                    label: "SIZE",
                    selected: _rule == Rule.size,
                    onTap: () => _startNewRound(rule: Rule.size),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Score
            Text(
              "Score: $_score / ${_targetCount == 0 ? _remaining.length : _targetCount}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 12),

            // Buckets (drop zones)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(child: _BucketDropZone(
                    bucket: buckets[0],
                    onAccept: (item) async {
                      final ok = _isCorrectBucket(item, buckets[0].id);
                      if (ok) {
                        await _onCorrect(item);
                      } else {
                        await _onWrong();
                      }
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _BucketDropZone(
                    bucket: buckets[1],
                    onAccept: (item) async {
                      final ok = _isCorrectBucket(item, buckets[1].id);
                      if (ok) {
                        await _onCorrect(item);
                      } else {
                        await _onWrong();
                      }
                    },
                  )),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Draggables (items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: _remaining.map((item) {
                    // For color rule: if item not red/green, keep but it will be “wrong”
                    final isPlaced = _placedIds.contains(item.id);
                    return Opacity(
                      opacity: isPlaced ? 0.25 : 1.0,
                      child: IgnorePointer(
                        ignoring: isPlaced,
                        child: _DraggableItemCard(item: item),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// UI WIDGETS
// =========================
class _RuleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RuleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(width: 2),
          color: selected ? Colors.black12 : null,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DraggableItemCard extends StatelessWidget {
  final SortItem item;

  const _DraggableItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Draggable<SortItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: _ItemVisual(item: item, big: true),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(width: 2),
        ),
        child: const Center(child: Text("...")),
      ),
      child: _ItemVisual(item: item, big: false),
    );
  }
}

class _ItemVisual extends StatelessWidget {
  final SortItem item;
  final bool big;

  const _ItemVisual({required this.item, required this.big});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.emoji,
              style: TextStyle(fontSize: big ? 64 : 52),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: big ? 20 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketDropZone extends StatefulWidget {
  final Bucket bucket;
  final Future<void> Function(SortItem item) onAccept;

  const _BucketDropZone({required this.bucket, required this.onAccept});

  @override
  State<_BucketDropZone> createState() => _BucketDropZoneState();
}

class _BucketDropZoneState extends State<_BucketDropZone> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<SortItem>(
      onWillAccept: (data) {
        setState(() => _hover = true);
        return true;
      },
      onLeave: (data) => setState(() => _hover = false),
      onAccept: (item) async {
        setState(() => _hover = false);
        await widget.onAccept(item);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 130,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(width: 3),
            color: _hover ? Colors.black12 : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.bucket.icon, size: 42),
              const SizedBox(height: 6),
              Text(
                widget.bucket.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              const Text(
                "DROP HERE",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }
}
