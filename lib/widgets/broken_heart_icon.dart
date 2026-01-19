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
    return CustomPaint(
      size: Size(size, size),
      painter: _BrokenHeartPainter(color: color),
    );
  }
}

class _BrokenHeartPainter extends CustomPainter {
  final Color color;

  _BrokenHeartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final heartSize = size.width * 0.4;

    // Рисуем левую половину сердечка (верхняя часть)
    final leftTopPath = Path();
    leftTopPath.moveTo(centerX - heartSize * 0.3, centerY - heartSize * 0.2);
    leftTopPath.quadraticBezierTo(
      centerX - heartSize * 0.6,
      centerY - heartSize * 0.6,
      centerX - heartSize * 0.4,
      centerY - heartSize * 0.8,
    );
    leftTopPath.quadraticBezierTo(
      centerX - heartSize * 0.2,
      centerY - heartSize * 0.9,
      centerX - heartSize * 0.1,
      centerY - heartSize * 0.7,
    );
    canvas.drawPath(leftTopPath, paint);

    // Рисуем правую половину сердечка (верхняя часть)
    final rightTopPath = Path();
    rightTopPath.moveTo(centerX + heartSize * 0.3, centerY - heartSize * 0.2);
    rightTopPath.quadraticBezierTo(
      centerX + heartSize * 0.6,
      centerY - heartSize * 0.6,
      centerX + heartSize * 0.4,
      centerY - heartSize * 0.8,
    );
    rightTopPath.quadraticBezierTo(
      centerX + heartSize * 0.2,
      centerY - heartSize * 0.9,
      centerX + heartSize * 0.1,
      centerY - heartSize * 0.7,
    );
    canvas.drawPath(rightTopPath, paint);

    // Рисуем нижнюю часть сердечка (разделенную)
    final leftBottomPath = Path();
    leftBottomPath.moveTo(centerX - heartSize * 0.1, centerY - heartSize * 0.7);
    leftBottomPath.quadraticBezierTo(
      centerX - heartSize * 0.2,
      centerY - heartSize * 0.3,
      centerX - heartSize * 0.3,
      centerY + heartSize * 0.2,
    );
    canvas.drawPath(leftBottomPath, paint);

    final rightBottomPath = Path();
    rightBottomPath.moveTo(centerX + heartSize * 0.1, centerY - heartSize * 0.7);
    rightBottomPath.quadraticBezierTo(
      centerX + heartSize * 0.2,
      centerY - heartSize * 0.3,
      centerX + heartSize * 0.3,
      centerY + heartSize * 0.2,
    );
    canvas.drawPath(rightBottomPath, paint);

    // Рисуем трещину посередине (зигзагообразная линия)
    final crackPath = Path();
    crackPath.moveTo(centerX, centerY - heartSize * 0.7);
    crackPath.lineTo(centerX - heartSize * 0.05, centerY - heartSize * 0.4);
    crackPath.lineTo(centerX + heartSize * 0.05, centerY - heartSize * 0.2);
    crackPath.lineTo(centerX, centerY);
    crackPath.lineTo(centerX - heartSize * 0.05, centerY + heartSize * 0.1);
    canvas.drawPath(crackPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
