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
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1), // Очень длинная анимация
    )..repeat();

    _lastHeartRate = widget.previousHeartRate;
    _initializePoints();

    // Добавляем слушатель для анимации
    _controller.addListener(_onAnimationUpdate);
  }

  void _onAnimationUpdate() {
    _frameCount++;

    // Добавляем новые точки для движения графика каждые несколько кадров
    if (_frameCount % 3 == 0) {
      _addBasePoint();
    }

    // Обновляем UI
    if (mounted) {
      setState(() {});
    }
  }

  void _initializePoints() {
    // Инициализируем начальными точками (ровная линия)
    for (int i = 0; i < 100; i++) {
      _points.add(40); // Базовый уровень
    }
    _isInitialized = true;
  }

  void _addBasePoint() {
    // Добавляем точку с базовым уровнем для движения графика
    _points.add(40);

    // Ограничиваем количество точек
    if (_points.length > 300) {
      _points.removeRange(0, _points.length - 300);
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

    // Добавляем скачок для кардиограммы
    _points.add(40); // Базовый уровень
    _points.add(25); // Начало скачка
    _points.add(80); // Пик скачка
    _points.add(40); // Возврат к базовому уровню
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

  _CardiogramPainter({
    required this.points,
    required this.lineColor,
    required this.height,
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

    final pointSpacing = 5.0;
    final verticalScale = height / 100;
    final centerY = height / 2;
    final baseLine = centerY + 10 * verticalScale; // Базовый уровень

    // Рассчитываем начальную позицию так, чтобы конец графика был в правой части
    // Мы хотим, чтобы новые точки (скачки) появлялись в конце (справа)
    final startIndex = points.length - (size.width / pointSpacing).ceil() - 10;
    final effectiveStartIndex = startIndex > 0 ? startIndex : 0;

    // Начинаем рисовать с первой видимой точки
    if (effectiveStartIndex < points.length) {
      path.moveTo(0, baseLine - points[effectiveStartIndex] * verticalScale);

      for (int i = effectiveStartIndex + 1; i < points.length; i++) {
        final x = (i - effectiveStartIndex) * pointSpacing;
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
           oldDelegate.height != height;
  }
}
