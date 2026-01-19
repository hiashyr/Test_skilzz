import 'package:flutter/material.dart';
import '../utils/heart_rate_colors.dart';

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
    final color = HeartRateColors.getColor(heartRate);
    
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

}
