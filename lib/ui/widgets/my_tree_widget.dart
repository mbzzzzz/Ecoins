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

class _MyTreeWidgetState extends State<MyTreeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true); // Breathing effect
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getAssetForStage() {
    if (widget.points < 100) return 'assets/images/tree_stage_1.png';
    if (widget.points < 300) return 'assets/images/tree_stage_2.png';
    if (widget.points < 800) return 'assets/images/tree_stage_3.png';
    if (widget.points < 2000) return 'assets/images/tree_stage_4.png';
    return 'assets/images/tree_stage_5.png';
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
