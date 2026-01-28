import 'package:flutter/material.dart';
import 'dart:math' as math;

class HeartRateChart extends StatefulWidget {
  final int heartRate;
  final int? previousHeartRate;
  final Color lineColor;
  final double height;

  const HeartRateChart({
    super.key,
    required this.heartRate,
    this.previousHeartRate,
    required this.lineColor,
    this.height = 200,
  });

  @override
  State<HeartRateChart> createState() => _HeartRateChartState();
}

class _HeartRateChartState extends State<HeartRateChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _points = [];
  int? _lastHeartRate;
  final double _pointSpacing = 3.0;
  int _pointsPerScreen = 0;
  double _containerWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();

    // Инициализируем «последний» пульс значением из widget
    _lastHeartRate = widget.previousHeartRate;

    // Подписываемся на события контроллера
    _controller.addListener(_onAnimationUpdate);
  }

  void _onAnimationUpdate() {
    // Добавляем «базовую» точку: 50 соответствует средней линии по вертикали
    _points.add(50);

    // Чтобы список не рос бесконечно, ограничиваем его длину
    if (_points.length > _pointsPerScreen + 50) {
      _points.removeAt(0);
    }

    // Обновляем UI (перерисовка через CustomPainter)
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(HeartRateChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.heartRate != _lastHeartRate) {
      _addHeartBeatSpike();
      _lastHeartRate = widget.heartRate;
    }
  }

  void _addHeartBeatSpike() {
    // Если не заполнены точки — нечего изменять
    if (_points.isEmpty) return;

    // Удаляем несколько последних точек, чтобы заменить их «ударом сердца».
    // Это формирует заметный пик на графике в момент изменения значения.
    final pointsToRemove = 8;
    if (_points.length > pointsToRemove) {
      for (int i = 0; i < pointsToRemove; i++) {
        _points.removeLast();
      }
    }

    // Простейший паттерн скачка: серия значений ниже/выше средней линии.
    _points.add(25); // спад перед ударом
    _points.add(35);
    _points.add(85); // острый пик вверх
    _points.add(65); // спад после пика
    _points.add(50); // возвращение к базовой линии

    // Несколько базовых точек, чтобы плавно вернуться к постоянному уровню.
    for (int i = 0; i < 3; i++) {
      _points.add(50);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimationUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Сохраняем ширину контейнера для расчетов
        _containerWidth = constraints.maxWidth;
        _pointsPerScreen = (_containerWidth / _pointSpacing).ceil();
        
        return SizedBox(
          height: widget.height,
          child: CustomPaint(
            painter: _CardiogramPainter(
              points: _points,
              lineColor: widget.lineColor,
              height: widget.height,
              pointSpacing: _pointSpacing,
              pointsPerScreen: _pointsPerScreen,
            ),
            size: Size(_containerWidth, widget.height),
          ),
        );
      },
    );
  }
}

class _CardiogramPainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final double height;
  final double pointSpacing;
  final int pointsPerScreen;

  _CardiogramPainter({
    required this.points,
    required this.lineColor,
    required this.height,
    required this.pointSpacing,
    required this.pointsPerScreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final gridPaint = Paint()
      ..color = lineColor.withOpacity(0.2)
      ..strokeWidth = 0.5;

    // Рисуем фоновую сетку
    _drawGrid(canvas, size, gridPaint);

    if (points.isEmpty) return;

    final verticalScale = height / 100;
    final baseLine = height / 2;

    // Всегда рисуем последние N точек: N = min(pointsPerScreen, availablePoints)
    final availablePoints = points.length;
    final count = math.min(pointsPerScreen, availablePoints);
    if (count <= 0) return;

    final startIndex = availablePoints - count;

    // Первая точка на X = 0
    final firstX = 0.0;
    final firstY = baseLine - (points[startIndex] - 50) * verticalScale;
    path.moveTo(firstX, firstY);

    for (int i = 1; i < count; i++) {
      final x = i * pointSpacing;
      final pointIndex = startIndex + i;
      final y = baseLine - (points[pointIndex] - 50) * verticalScale;
      if (x > size.width) break;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

  }

  void _drawGrid(Canvas canvas, Size size, Paint gridPaint) {
    // Горизонтальные линии (5 линий на равном расстоянии)
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Вертикальные линии (менее заметные)
    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      final dashPaint = Paint()
        ..color = lineColor.withOpacity(0.1)
        ..strokeWidth = 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardiogramPainter oldDelegate) {
    return oldDelegate.points != points ||
           oldDelegate.lineColor != lineColor ||
           oldDelegate.height != height ||
           oldDelegate.pointSpacing != pointSpacing ||
           oldDelegate.pointsPerScreen != pointsPerScreen;
  }
}
