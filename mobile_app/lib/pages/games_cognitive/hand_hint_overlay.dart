import 'package:flutter/material.dart';

class HandHintOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final VoidCallback onFinished;

  const HandHintOverlay({
    super.key,
    required this.targetKey,
    required this.onFinished,
  });

  @override
  State<HandHintOverlay> createState() => _HandHintOverlayState();
}

class _HandHintOverlayState extends State<HandHintOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;
  Offset _targetOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _calculatePosition());

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onFinished());
  }

  void _calculatePosition() {
    final renderBox = widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && overlayBox != null && mounted) {
      final targetOffset =
          renderBox.localToGlobal(Offset.zero, ancestor: overlayBox) +
          Offset(renderBox.size.width / 2, renderBox.size.height / 2);

      _positionAnimation = Tween<Offset>(
        begin: targetOffset + const Offset(100, 150),
        end: targetOffset,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

      setState(() {
        _targetOffset = targetOffset;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targetOffset == Offset.zero) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx - 25,
          top: _positionAnimation.value.dy - 25,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: const Icon(
              Icons.front_hand, 
              size: 60, 
              color: Colors.orangeAccent,
              shadows: [Shadow(blurRadius: 10, color: Colors.black26)],
            ),
          ),
        );
      },
    );
  }
}
