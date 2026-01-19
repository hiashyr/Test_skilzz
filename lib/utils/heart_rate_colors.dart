import 'package:flutter/material.dart';

class HeartRateColors {
  static Color getColor(int heartRate) {
    if (heartRate < 60) return const Color(0xFFFFCDD2);    // Colors.red[100]
    if (heartRate <= 80) return const Color(0xFFE57373);   // Colors.red[300]
    if (heartRate <= 100) return const Color(0xFFF44336);  // Colors.red[500]
    if (heartRate <= 120) return const Color(0xFFD32F2F);  // Colors.red[700]
    return const Color(0xFFB71C1C);                        // Colors.red[900]
  }
}
