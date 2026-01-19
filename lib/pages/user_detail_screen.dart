import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/metrics_provider.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/heart_rate_display.dart';
import '../widgets/theme_toggle_button.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('User $userId'),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Consumer<MetricsProvider>(
        builder: (context, metricsProvider, child) {
          final user = metricsProvider.getUser(userId);
          final connectionStatus = metricsProvider.connectionStatus;

          // Если пользователь не найден
          if (user == null) {
            return ErrorMessageWidget(
              icon: Icons.person_off,
              message: 'User not found',
              onAction: () => context.go('/'),
              actionLabel: 'Back to Dashboard',
            );
          }

          // Если есть ошибка подключения, показываем сообщение, но оставляем данные
          final showError = connectionStatus == ConnectionStatus.error &&
              metricsProvider.errorMessage != null;

          // Основной контент страницы пользователя
          return SingleChildScrollView(
            child: Column(
              children: [
                // Индикатор статуса подключения
                if (showError || connectionStatus == ConnectionStatus.connected)
                  ConnectionStatusBar(
                    status: connectionStatus,
                    errorMessage: showError 
                        ? 'Showing last known data. Reconnecting...'
                        : null,
                  ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Заглушка для пульсирующего сердца (будет реализовано позже)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        child: Icon(
                          Icons.favorite,
                          size: 120,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Отображение пульса
                      HeartRateDisplay(
                        heartRate: user.heartRate,
                        userName: user.userName,
                      ),
                      const SizedBox(height: 60),
                      // Заглушка для графика (будет реализовано позже)
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Chart will be here',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Back to Dashboard'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
