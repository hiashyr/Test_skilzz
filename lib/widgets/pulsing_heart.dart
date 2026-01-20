import 'dart:ui';

import 'package:flutter/material.dart';
import '../utils/heart_rate_colors.dart';

extension PulsingHeartTheme on ThemeData {
  Duration get heartPulseDuration => const Duration(milliseconds: 600);
  double get heartPulseScale => 1.2;
  Curve get heartPulseCurve => Curves.easeInOut;
}

class PulsingHeart extends StatefulWidget {
  final int heartRate;
  final int? previousHeartRate;
  final double size;
  final Duration? duration;
  final double? scale;
  final Curve? curve;
  final double glowIntensity;
  final double glowRadius;

  const PulsingHeart({
    super.key,
    required this.heartRate,
    this.previousHeartRate,
    this.size = 180, // Увеличенный размер по умолчанию
    this.duration,
    this.scale,
    this.curve,
    this.glowIntensity = 0.8,
    this.glowRadius = 20.0,
  });

  @override
  State<PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<PulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
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

    // Инициализируем анимации с дефолтными значениями
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Запускаем анимацию при первом отображении
    _lastHeartRate = widget.previousHeartRate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.heartRate != _lastHeartRate) {
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
    if (widget.heartRate != _lastHeartRate) {
      _lastHeartRate = widget.heartRate;
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
    final heartColor = HeartRateColors.getColor(widget.heartRate);

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
      builder: (context, child) {
        // Рассчитываем параметры свечения в зависимости от пульса
        final glowIntensity = widget.glowIntensity * _glowAnimation.value;
        final glowScale = 1.0 + (0.15 * _glowAnimation.value); // Масштаб свечения 1.0-1.15
        final blurRadius = 8.0 * _glowAnimation.value; // Радиус размытия 0-8

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Слой свечения (увеличенная иконка с размытием)
              Transform.scale(
                scale: glowScale,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurRadius,
                    sigmaY: blurRadius,
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: widget.size,
                    color: heartColor.withOpacity(0.7 * glowIntensity),
                  ),
                ),
              ),
              // Дополнительный слой свечения для усиления эффекта
              Transform.scale(
                scale: glowScale * 0.95,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurRadius * 0.5,
                    sigmaY: blurRadius * 0.5,
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: widget.size,
                    color: heartColor.withOpacity(0.4 * glowIntensity),
                  ),
                ),
              ),
              // Основная иконка
              Icon(
                Icons.favorite,
                size: widget.size,
                color: heartColor,
              ),
            ],
          ),
        );
      },
    );
  }
}
