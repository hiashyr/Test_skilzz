import 'package:flutter/material.dart';
import '../utils/heart_rate_colors.dart';

extension PulsingHeartTheme on ThemeData {
  Duration get heartPulseDuration => const Duration(milliseconds: 600);
  double get heartPulseScale => 1.2;
}

class PulsingHeart extends StatefulWidget {
  final int heartRate;
  final int? previousHeartRate;
  final double size;
  final Duration? duration;
  final double? scale;

  const PulsingHeart({
    super.key,
    required this.heartRate,
    this.previousHeartRate,
    this.size = 180,
    this.duration,
    this.scale,
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

  static const Curve _hardcodedCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: _hardcodedCurve,
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

    // Обновляем анимацию с текущими параметрами
    _controller.duration = _duration;
    _scaleAnimation = Tween<double>(begin: 1.0, end: _scale!).animate(
      CurvedAnimation(
        parent: _controller,
        curve: _hardcodedCurve,
      ),
    );
  }

  @override
  void didUpdateWidget(PulsingHeart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Обновляем параметры анимации, если они изменились
    if (widget.duration != oldWidget.duration ||
        widget.scale != oldWidget.scale) {
      final theme = Theme.of(context);
      _duration = widget.duration ?? theme.heartPulseDuration;
      _scale = widget.scale ?? theme.heartPulseScale;

      _controller.duration = _duration;
      _scaleAnimation = Tween<double>(begin: 1.0, end: _scale!).animate(
        CurvedAnimation(
          parent: _controller,
          curve: _hardcodedCurve,
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

    final iconChild = RepaintBoundary(
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        child: Icon(
          Icons.favorite,
          size: widget.size,
          color: heartColor,
          shadows: [
            Shadow(
              color: heartColor,
              blurRadius: 30,
            ),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      child: iconChild,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
    );
  }
}