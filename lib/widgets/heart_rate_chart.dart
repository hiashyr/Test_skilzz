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
  bool _isInitialized = false;
  double _offset = 0;
  double _totalDistance = 0;
  final double _pointSpacing = 3.0; // Расстояние между точками

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    )..repeat();

    _lastHeartRate = widget.previousHeartRate;
    _initializePoints();

    _controller.addListener(_onAnimationUpdate);
  }

  void _initializePoints() {
    // Инициализируем начальными точками (ровная линия)
    // Нам нужно достаточно точек, чтобы конец линии был в конце видимого блока
    // Предполагаем, что ширина контейнера ~300px, а расстояние между точками 3px
    // Значит нужно ~100 точек для заполнения видимой области + запас
    final pointsNeeded = 150;
    for (int i = 0; i < pointsNeeded; i++) {
      _points.add(40); // Базовый уровень
    }

    // Устанавливаем начальное смещение так, чтобы конец линии был в конце блока
    // Это гарантирует, что новые скачки будут появляться из конца блока сразу
    _offset = (pointsNeeded - 100) * _pointSpacing;
    _isInitialized = true;
  }

  void _onAnimationUpdate() {
    // Двигаем график слева направо
    _offset += 1.0;
    _totalDistance += 1.0;

    // Добавляем новые точки по мере движения
    if (_totalDistance % _pointSpacing < 1.0) {
      _addBasePoint();
    }

    // Сбрасываем offset, чтобы избежать переполнения
    if (_offset > 1000) {
      _offset = 0;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _addBasePoint() {
    // Добавляем точку с базовым уровнем
    _points.add(40);

    // Ограничиваем количество точек
    if (_points.length > 500) {
      _points.removeAt(0);
    }
  }

  @override
  void didUpdateWidget(HeartRateChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Используем ту же логику, что и в PulsingHeart
    if (widget.heartRate != _lastHeartRate) {
      _addHeartBeatSpike();
      _lastHeartRate = widget.heartRate;
    }
  }

  void _addHeartBeatSpike() {
    if (!_isInitialized) return;

    // Добавляем скачок для кардиограммы за пределами видимой области
    // Сначала добавляем несколько точек базового уровня
    for (int i = 0; i < 5; i++) {
      _points.add(40);
    }

    // Затем добавляем сам скачок
    _points.add(25); // Начало скачка
    _points.add(80); // Пик скачка
    _points.add(40); // Возврат к базовому уровню

    // Добавляем еще несколько точек базового уровня
    for (int i = 0; i < 5; i++) {
      _points.add(40);
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
    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: _CardiogramPainter(
          points: _points,
          lineColor: widget.lineColor,
          height: widget.height,
          offset: _offset,
          pointSpacing: _pointSpacing,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CardiogramPainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final double height;
  final double offset;
  final double pointSpacing;

  _CardiogramPainter({
    required this.points,
    required this.lineColor,
    required this.height,
    required this.offset,
    required this.pointSpacing,
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

    // Начинаем рисовать линию кардиограммы
    if (points.isEmpty) return;

    final verticalScale = height / 100;
    final centerY = height / 2;
    final baseLine = centerY + 10 * verticalScale; // Базовый уровень

    // Рассчитываем, сколько точек помещается на экране
    final pointsPerScreen = size.width / pointSpacing;

    // Рассчитываем начальную точку для отображения
    // Нам нужно отобразить точки в диапазоне [startIndex, endIndex]
    final startIndex = offset / pointSpacing;
    final endIndex = startIndex + pointsPerScreen;

    // Находим индексы первой и последней видимой точки
    final firstVisibleIndex = startIndex.floor();
    final lastVisibleIndex = endIndex.ceil().clamp(0, points.length - 1);

    // Рисуем только видимую часть графика
    if (firstVisibleIndex < points.length) {
      // Начинаем с первой видимой точки
      final startX = (firstVisibleIndex - startIndex) * pointSpacing;
      final startY = baseLine - points[firstVisibleIndex] * verticalScale;
      path.moveTo(startX, startY);

      // Рисуем все видимые точки
      for (int i = firstVisibleIndex + 1; i <= lastVisibleIndex && i < points.length; i++) {
        final x = (i - startIndex) * pointSpacing;
        final y = baseLine - points[i] * verticalScale;
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawGrid(Canvas canvas, Size size, Paint gridPaint) {
    // Горизонтальные линии
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
           oldDelegate.offset != offset ||
           oldDelegate.pointSpacing != pointSpacing;
  }
}
