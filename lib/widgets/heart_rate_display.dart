import 'package:flutter/material.dart';

class HeartRateDisplay extends StatelessWidget {
  final int heartRate;
  final String? userName;

  const HeartRateDisplay({
    super.key,
    required this.heartRate,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getHeartRateColor(heartRate, theme);
    
    return Column(
      children: [
        if (userName != null) ...[
          Text(
            userName!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          '$heartRate',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'bpm',
          style: TextStyle(
            fontSize: 24,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Color _getHeartRateColor(int heartRate, ThemeData theme) {
    if (heartRate < 60) return Colors.blue;
    if (heartRate <= 100) return Colors.green;
    if (heartRate <= 120) return Colors.orange;
    return Colors.red;
  }
}
