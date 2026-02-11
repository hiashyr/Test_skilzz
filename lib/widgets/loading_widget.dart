import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool fullScreen; // Флаг для растягивания на весь экран

  const LoadingWidget({
    super.key,
    this.message,
    this.fullScreen = true, // По умолчанию на весь экран
  });

  const LoadingWidget.compact({
    super.key,
    this.message,
  }) : fullScreen = false; // Компактная версия

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Center(
        child: content,
      );
    }

    return content;
  }
}