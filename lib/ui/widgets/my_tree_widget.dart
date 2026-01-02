import 'package:ecoins/core/level_system.dart';
import 'package:flutter/material.dart';

class MyTreeWidget extends StatefulWidget {
  final int points;
  final double size;

  const MyTreeWidget({
    super.key,
    required this.points,
    this.size = 200,
  });

  @override
  State<MyTreeWidget> createState() => _MyTreeWidgetState();
}

class _MyTreeWidgetState extends State<MyTreeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true); // Breathing effect

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getAssetForStage() {
    return LevelSystem.getLevel(widget.points).assetPath;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Image.asset(
            _getAssetForStage(),
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}
