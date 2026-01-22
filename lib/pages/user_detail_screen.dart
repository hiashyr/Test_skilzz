import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/metrics_provider.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/heart_rate_display.dart';
import '../widgets/pulsing_heart.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/heart_rate_chart.dart';
import '../utils/heart_rate_colors.dart';

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

    return Scaffold(
      body: Consumer<MetricsProvider>(
        builder: (context, metricsProvider, child) {
          final user = metricsProvider.getUser(widget.userId);
          final connectionStatus = metricsProvider.connectionStatus;

          // Если есть ошибка подключения, показываем только сообщение об ошибке
          if (connectionStatus == ConnectionStatus.error && metricsProvider.errorMessage != null) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                  title: Text(user?.userName.isNotEmpty == true ? user!.userName : 'Пользователь ${widget.userId}'),
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
                SliverFillRemaining(
                  child: ErrorMessageWidget(
                    icon: Icons.heart_broken_rounded,
                    message: metricsProvider.errorMessage!,
                    subtitle: 'Приложение автоматически переподключится, когда сервер станет доступен.',
                    reconnectCountdown: metricsProvider.reconnectCountdown > 0
                        ? metricsProvider.reconnectCountdown
                        : null,
                    onAction: () => metricsProvider.startListening(),
                    actionLabel: 'Переподключиться',
                  ),
                ),
              ],
            );
          }

          // Если пользователь не найден
          if (user == null) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                  title: Text('Пользователь ${widget.userId}'),
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
                SliverFillRemaining(
                  child: ErrorMessageWidget(
                    icon: Icons.person_off,
                    message: 'Пользователь не найден',
                    onAction: () => context.go('/'),
                    actionLabel: 'Вернуться на главную',
                  ),
                ),
              ],
            );
          }

          // Сохраняем предыдущее значение пульса для следующего обновления
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _previousHeartRate = user.heartRate;
              });
            }
          });

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/'),
                ),
                title: Text(user.userName.isNotEmpty ? user.userName : 'Пользователь ${widget.userId}'),
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
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Отображение пульса
                          HeartRateDisplay(
                            heartRate: user.heartRate,
                          ),
                          const SizedBox(height: 60),
                          // Кардиограмма пульса
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Кардиограмма',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                HeartRateChart(
                                  heartRate: user.heartRate,
                                  previousHeartRate: _previousHeartRate,
                                  lineColor: HeartRateColors.getColor(user.heartRate),
                                  height: 150,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
