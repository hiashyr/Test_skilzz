import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/metrics_provider.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/heart_rate_display.dart';
import '../widgets/pulsing_heart.dart';
import '../widgets/theme_toggle_button.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  int? _previousHeartRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<MetricsProvider>(
      builder: (context, metricsProvider, child) {
        final user = metricsProvider.getUser(widget.userId);
        final connectionStatus = metricsProvider.connectionStatus;

        // Если пользователь не найден
        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('User ${widget.userId}'),
              actions: const [
                ThemeToggleButton(),
              ],
            ),
            body: ErrorMessageWidget(
              icon: Icons.person_off,
              message: 'User not found',
              onAction: () => context.go('/'),
              actionLabel: 'Back to Dashboard',
            ),
          );
        }

        // Если есть ошибка подключения, показываем сообщение, но оставляем данные
        final showError = connectionStatus == ConnectionStatus.error &&
            metricsProvider.errorMessage != null;

        // Сохраняем предыдущее значение пульса для следующего обновления
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _previousHeartRate = user.heartRate;
            });
          }
        });

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(user.userName.isNotEmpty ? user.userName : 'User ${widget.userId}'),
                actions: const [
                  ThemeToggleButton(),
                ],
                pinned: true,
                floating: false,
                snap: false,
                forceMaterialTransparency: false,
                surfaceTintColor: Colors.transparent,
                backgroundColor: theme.appBarTheme.backgroundColor,
                elevation: theme.appBarTheme.elevation,
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (showError)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ErrorMessageWidget(
                          icon: Icons.warning_amber_rounded,
                          message: metricsProvider.errorMessage!,
                          onAction: () => metricsProvider.startListening(),
                          actionLabel: 'Reconnect',
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Анимированное пульсирующее сердце
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: Center(
                              child: PulsingHeart(
                                heartRate: user.heartRate,
                                previousHeartRate: _previousHeartRate,
                                // size по умолчанию теперь 180, можно не указывать явно
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                  // Отображение пульса
                  HeartRateDisplay(
                    heartRate: user.heartRate,
                  ),
                          const SizedBox(height: 60),
                          // Заглушка для графика (будет реализовано позже)
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(),
                            ),
                            child: Center(
                              child: Text(
                                'Chart will be here',
                                style: TextStyle(
                                  fontSize: 16,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
