import 'package:flutter/material.dart';

class BrokenHeartIcon extends StatelessWidget {
  final double size;
  final Color color;

  const BrokenHeartIcon({
    super.key,
    this.size = 24,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.heart_broken_rounded,
      size: size,
      color: color,
    );
  }
}
