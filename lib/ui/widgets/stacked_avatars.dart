import 'package:flutter/material.dart';

class StackedAvatars extends StatelessWidget {
  final List<String?> imageUrls;
  final double size;
  final double overlap;
  final Color borderColor;
  final double  borderWidth;

  const StackedAvatars({
    super.key,
    required this.imageUrls,
    this.size = 40,
    this.overlap = 15,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final items = imageUrls.take(4).toList(); // Max 4 avatars
    
    return SizedBox(
      height: size,
      width: size + (items.length - 1) * (size - overlap),
      child: Stack(
        children: List.generate(items.length, (index) {
          return Positioned(
            left: index * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: borderWidth),
                color: Colors.grey[300],
                image: items[index] != null 
                    ? DecorationImage(image: NetworkImage(items[index]!), fit: BoxFit.cover)
                    : null
              ),
              child: items[index] == null 
                  ? Icon(Icons.person, size: size * 0.6, color: Colors.grey[600]) 
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
