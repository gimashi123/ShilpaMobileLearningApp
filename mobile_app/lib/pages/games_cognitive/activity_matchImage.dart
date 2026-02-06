import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class MatchImageGameApp extends StatelessWidget {
  const MatchImageGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MatchImageGamePage();
  }
}

class _ImageItem {
  final String id;
  final String asset;

  const _ImageItem({required this.id, required this.asset});
}

class MatchImageGamePage extends StatefulWidget {
  const MatchImageGamePage({super.key});

  @override
  State<MatchImageGamePage> createState() => _MatchImageGamePageState();
}

class _MatchImageGamePageState extends State<MatchImageGamePage>
    with SingleTickerProviderStateMixin {
  final _rng = Random();

  final List<_ImageItem> _pool = const [
    _ImageItem(id: 'monkey', asset: 'assets/images/cognitive/monkey.png'),
    _ImageItem(id: 'panda', asset: 'assets/images/cognitive/panda.png'),
    _ImageItem(id: 'dog', asset: 'assets/images/cognitive/dog.png'),
    _ImageItem(id: 'cat', asset: 'assets/images/cognitive/cat.png'),
    _ImageItem(id: 'car', asset: 'assets/images/cognitive/car.png'),
    _ImageItem(id: 'bell', asset: 'assets/images/cognitive/bell.png'),
  ];

  late List<_ImageItem> _tiles;

  String? _selectedId;
  int? _selectedIndex;
  final Set<String> _matchedIds = {};

  String _feedback = 'එකම රූප දෙක තෝරන්න';
  Color _feedbackColor = Colors.black87;
  bool _checking = false;

  late final ConfettiController _confettiController;
  late final AnimationController _starController;
  late final Animation<double> _starScale;
  bool _showStar = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 900));
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _starScale = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _starController, curve: Curves.elasticOut),
    );
    _newRound();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _starController.dispose();
    super.dispose();
  }

  void _newRound() {
    final picks = List<_ImageItem>.from(_pool)..shuffle(_rng);
    final selected = picks.take(6).toList();
    _tiles = [...selected, ...selected]..shuffle(_rng);

    setState(() {
      _selectedId = null;
      _selectedIndex = null;
      _matchedIds.clear();
      _feedback = 'එකම රූප දෙක තෝරන්න';
      _feedbackColor = Colors.black87;
      _checking = false;
    });
  }

  Future<void> _checkMatch(String tappedId, int tappedIndex) async {
    if (_checking) return;

    if (_selectedId == null) {
      setState(() {
        _selectedId = tappedId;
        _selectedIndex = tappedIndex;
        _feedback = 'එකම රූපය තෝරන්න';
        _feedbackColor = Colors.black87;
      });
      return;
    }

    if (_selectedIndex == tappedIndex) return;

    setState(() => _checking = true);

    final correct = _selectedId == tappedId;

    if (correct) {
      setState(() {
        _matchedIds.add(tappedId);
        _feedback = 'හරි! ගැලපුවා.';
        _feedbackColor = Colors.green;
        _selectedId = null;
        _selectedIndex = null;
      });

      if (_matchedIds.length == 6) {
        await _playRewardAnimation();
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        setState(() {
          _feedback = 'සියල්ල ගැලපුණා!';
          _feedbackColor = Colors.green.shade700;
        });
      }
    } else {
      setState(() {
        _feedback = 'වැරදියි. නැවත උත්සාහ කරන්න.';
        _feedbackColor = Colors.red;
      });

      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() {
        _selectedId = null;
        _selectedIndex = null;
        _feedback = 'එකම රූප දෙක තෝරන්න';
        _feedbackColor = Colors.black87;
      });
    }

    if (mounted) setState(() => _checking = false);
  }

  Future<void> _goDashboard() async {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      '/home_cognitive',
      (route) => false,
    );
  }

  Future<void> _playRewardAnimation() async {
    setState(() => _showStar = true);

    _confettiController.play();
    await _starController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    setState(() => _showStar = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    final shortestSide = size.shortestSide;
    final isPortrait = height >= width;

    final scale = (shortestSide / 360).clamp(0.85, 1.2);
    final isWide = width >= 720;
    final padding = (isWide ? 20.0 : 12.0) * scale;
    final titleSize = (isWide ? 20.0 : 18.0) * scale;
    final feedbackSize = (isWide ? 16.0 : 14.0) * scale;
    final gridSpacing = (isWide ? 12.0 : 8.0) * scale;
    final cardRadius = (isWide ? 16.0 : 12.0) * scale;

    return Scaffold(
      appBar: AppBar(
        title: const Text('රූප ගැලපීම'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goDashboard,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  Text(
                    'එකම රූප දෙක තෝරා ගැලපෙන්න',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8 * scale),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * scale,
                      vertical: 8 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: _feedbackColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    child: Text(
                      _feedback,
                      style: TextStyle(
                        fontSize: feedbackSize,
                        color: _feedbackColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 12 * scale),
                  Expanded(
                    child: _buildGrid(
                      items: _tiles,
                      onTap: _onTapTile,
                      selectedId: _selectedId,
                      selectedIndex: _selectedIndex,
                      gridSpacing: gridSpacing,
                      cardRadius: cardRadius,
                      isPortrait: isPortrait,
                      screenWidth: width,
                    ),
                  ),
                  SizedBox(height: 12 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _newRound,
                          icon: const Icon(Icons.refresh),
                          label: const Text('අලුත්'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: 12 * scale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_showStar)
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          numberOfParticles: 16,
                          emissionFrequency: 0.12,
                          maxBlastForce: 18,
                          minBlastForce: 10,
                          gravity: 0.3,
                        ),
                      ),
                      Center(
                        child: ScaleTransition(
                          scale: _starScale,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 16,
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Text(
                              "⭐",
                              style: TextStyle(fontSize: 64),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid({
    required List<_ImageItem> items,
    required void Function(_ImageItem item, int index) onTap,
    required String? selectedId,
    required int? selectedIndex,
    required double gridSpacing,
    required double cardRadius,
    required bool isPortrait,
    required double screenWidth,
  }) {
    final crossAxisCount = screenWidth < 360
        ? 2
        : screenWidth < 600
            ? 3
            : 4;

    return GridView.builder(
      itemCount: items.length,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isMatched = _matchedIds.contains(item.id);
        final isSelected = selectedId == item.id && selectedIndex == index;

        final borderColor = isMatched
            ? Colors.green
            : isSelected
                ? Colors.blue
                : Colors.grey.shade400;

        return InkWell(
          onTap: isMatched ? null : () => onTap(item, index),
          borderRadius: BorderRadius.circular(cardRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isMatched ? Colors.green.withOpacity(0.12) : Colors.white,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Opacity(
              opacity: isMatched ? 0.6 : 1.0,
              child: Image.asset(
                item.asset,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTapTile(_ImageItem item, int index) {
    if (_matchedIds.contains(item.id)) return;
    if (_checking) return;
    _checkMatch(item.id, index);
  }
}
