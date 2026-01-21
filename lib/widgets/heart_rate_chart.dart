import 'package:flutter/material.dart';

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
  final double _pointSpacing = 3.0; // Расстояние между точками
  int _pointsPerScreen = 0;
  double _containerWidth = 0;
  bool _shouldFillInitialPoints = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    )..repeat();

    _lastHeartRate = widget.previousHeartRate;

    _controller.addListener(_onAnimationUpdate);
  }

  void _onAnimationUpdate() {
    if (_pointsPerScreen == 0) return;

    // Если нужно заполнить начальные точки
    if (_shouldFillInitialPoints) {
      _fillInitialPoints();
    }

    // Добавляем новую точку с базовым уровнем (50 - это середина по вертикали)
    _points.add(50); // Изменено с 40 на 50 - середина диапазона 0-100
    
    // Удаляем самую старую точку, чтобы поддерживать постоянную длину
    if (_points.length > _pointsPerScreen + 50) {
      _points.removeAt(0);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _fillInitialPoints() {
    // Заполняем массив точками так, чтобы сразу была полная линия
    // Берем pointsPerScreen + небольшой запас
    final targetCount = _pointsPerScreen + 20;
    
    if (_points.length < targetCount) {
      // Добавляем недостающие точки (50 - середина)
      for (int i = _points.length; i < targetCount; i++) {
        _points.add(50); // Изменено с 40 на 50
      }
    }
    
    // Теперь у нас достаточно точек, чтобы линия начиналась с конца
    _shouldFillInitialPoints = false;
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
    if (_points.isEmpty) return;

    // Удаляем последние несколько точек и заменяем их скачком
    final pointsToRemove = 8;
    if (_points.length > pointsToRemove) {
      for (int i = 0; i < pointsToRemove; i++) {
        _points.removeLast();
      }
    }

    // Добавляем скачок относительно средней линии (50)
    _points.add(25); // Начало скачка (сильнее вниз)
    _points.add(35);
    _points.add(85); // Пик скачка (сильнее вверх)
    _points.add(65);
    _points.add(50); // Возврат к середине
    
    // Добавляем несколько базовых точек после скачка
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
    final baseLine = height / 2; // Теперь точно по середине!

    // Определяем, сколько точек у нас есть для отображения
    final availablePoints = points.length;
    
    // Если у нас меньше точек, чем помещается на экран,
    // начинаем рисовать с левого края (но это будет только в самом начале)
    if (availablePoints <= pointsPerScreen) {
      // Рисуем то, что есть
      final firstX = 0.0;
      // Преобразуем значение точки: 0 -> низ, 100 -> верх, 50 -> середина
      final firstY = baseLine - (points[0] - 50) * verticalScale;
      path.moveTo(firstX, firstY);

      for (int i = 1; i < availablePoints; i++) {
        final x = i * pointSpacing;
        final y = baseLine - (points[i] - 50) * verticalScale;
        
        if (x > size.width) break;
        path.lineTo(x, y);
      }
    } else {
      // У нас достаточно точек, начинаем с конца
      // Начинаем рисовать с точки, которая находится на расстоянии pointsPerScreen от конца
      final startIndex = availablePoints - pointsPerScreen;
      
      // Первая точка будет на X = 0
      final firstX = 0.0;
      final firstY = baseLine - (points[startIndex] - 50) * verticalScale;
      path.moveTo(firstX, firstY);

      // Рисуем остальные точки
      for (int i = 1; i < pointsPerScreen; i++) {
        final x = i * pointSpacing;
        final pointIndex = startIndex + i;
        
        if (pointIndex >= availablePoints) break;
        
        final y = baseLine - (points[pointIndex] - 50) * verticalScale;
        
        if (x > size.width) break;
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Дополнительно рисуем среднюю пунктирную линию для наглядности
    final centerLinePaint = Paint()
      ..color = lineColor.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(0, baseLine),
      Offset(size.width, baseLine),
      centerLinePaint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final delta = end - start;
    final direction = delta / delta.distance;

    double distance = 0;
    while (distance < delta.distance) {
      final dashStart = start + direction * distance;
      distance += dashWidth;
      if (distance > delta.distance) {
        distance = delta.distance;
      }
      final dashEnd = start + direction * distance;
      canvas.drawLine(dashStart, dashEnd, paint);
      distance += dashSpace;
    }
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
