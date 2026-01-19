import 'package:flutter/material.dart';

extension PulsingHeartTheme on ThemeData {
  Duration get heartPulseDuration => const Duration(milliseconds: 600);
  double get heartPulseScale => 1.2;
  Curve get heartPulseCurve => Curves.easeInOut;
}

class PulsingHeart extends StatefulWidget {
  final int currentHeartRate;
  final int? previousHeartRate;
  final double size;
  final Color? color;
  final Duration? duration;
  final double? scale;
  final Curve? curve;

  const PulsingHeart({
    super.key,
    required this.currentHeartRate,
    this.previousHeartRate,
    this.size = 300,
    this.color,
    this.duration,
    this.scale,
    this.curve,
  });

  @override
  State<PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<PulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int? _lastHeartRate;
  Duration? _duration;
  double? _scale;
  Curve? _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 600),
      vsync: this,
    );

    // Инициализируем анимацию с дефолтными значениями
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Запускаем анимацию при первом отображении
    _lastHeartRate = widget.previousHeartRate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.currentHeartRate != _lastHeartRate) {
        _playAnimation();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    _duration = widget.duration ?? theme.heartPulseDuration;
    _scale = widget.scale ?? theme.heartPulseScale;
    _curve = widget.curve ?? theme.heartPulseCurve;

    // Обновляем анимацию с текущими параметрами
    _controller.duration = _duration;
    _scaleAnimation = Tween<double>(begin: 1.0, end: _scale!).animate(
      CurvedAnimation(
        parent: _controller,
        curve: _curve!,
      ),
    );
  }

  @override
  void didUpdateWidget(PulsingHeart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Обновляем параметры анимации, если они изменились
    if (widget.duration != oldWidget.duration ||
        widget.scale != oldWidget.scale ||
        widget.curve != oldWidget.curve) {
      final theme = Theme.of(context);
      _duration = widget.duration ?? theme.heartPulseDuration;
      _scale = widget.scale ?? theme.heartPulseScale;
      _curve = widget.curve ?? theme.heartPulseCurve;

      _controller.duration = _duration;
      _scaleAnimation = Tween<double>(begin: 1.0, end: _scale!).animate(
        CurvedAnimation(
          parent: _controller,
          curve: _curve!,
        ),
      );
    }

    // Проверяем, изменился ли пульс
    if (widget.currentHeartRate != _lastHeartRate) {
      _lastHeartRate = widget.currentHeartRate;
      _playAnimation();
    }
  }

  void _playAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.favorite,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}
