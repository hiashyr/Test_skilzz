import 'package:flutter/material.dart';
import 'broken_heart_icon.dart';

class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final int? reconnectCountdown;
  final IconData? icon;
  final bool useBrokenHeart;
  final VoidCallback? onAction;
  final String? actionLabel;

  const ErrorMessageWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.reconnectCountdown,
    this.icon,
    this.useBrokenHeart = false,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            useBrokenHeart
                ? BrokenHeartIcon(
                    size: 64,
                    color: theme.colorScheme.error,
                  )
                : Icon(
                    icon ?? Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (reconnectCountdown != null && reconnectCountdown! > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Переподключение через $reconnectCountdown...',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
