import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/metrics_riverpod.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/heart_rate_display.dart';
import '../widgets/pulsing_heart.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/heart_rate_chart.dart';
import '../utils/heart_rate_colors.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailScreen({ 
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  int? _previousHeartRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(metricsStreamProvider);

    return Scaffold(
      body: usersAsync.when(
        // ✅ ЕСТЬ ДАННЫЕ - показываем пользователя
        data: (usersList) {
          // Ищем нужного пользователя
          final user = usersList.firstWhere(
            (u) => u.userId == widget.userId
          );

          // ✅ Пользователь найден - сохраняем предыдущее значение пульса
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _previousHeartRate = user.heartRate;
              });
            }
          });

          // Показываем данные пользователя
          return CustomScrollView(
            slivers: [
              _buildAppBar(
                context, 
                user.userName.isNotEmpty ? user.userName : 'Пользователь ${widget.userId}'
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
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
              ),
            ],
          );
        },

        // 🔄 ЗАГРУЗКА - используем LoadingWidget
        loading: () => const LoadingWidget(
          message: 'Подключение к серверу...',
        ),

        // ❌ ОШИБКА - показываем сообщение и кнопку повтора
        error: (err, stack) => CustomScrollView(
          slivers: [
            _buildAppBar(context, 'Пользователь ${widget.userId}'),
            SliverFillRemaining(
              child: ErrorMessageWidget(
                icon: Icons.heart_broken_rounded,
                message: _formatErrorMessage(err),
                subtitle: 'Проверьте подключение к серверу',
                onAction: () => ref.invalidate(metricsStreamProvider),
                actionLabel: 'Повторить',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔧 Выносим AppBar в отдельный метод для переиспользования
  Widget _buildAppBar(BuildContext context, String title) {
    return SliverAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/'),
      ),
      title: Text(title),
      actions: const [
        ThemeToggleButton(),
      ],
      pinned: true,
      floating: false,
      snap: false,
      forceMaterialTransparency: false,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: Theme.of(context).appBarTheme.elevation,
    );
  }

  // 🔧 Форматируем сообщение об ошибке
  String _formatErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('Connection refused')) {
      return 'Сервер недоступен';
    }
    if (message.contains('timed out')) {
      return 'Сервер не отвечает';
    }
    if (message.contains('Failed host lookup')) {
      return 'Нет подключения к интернету';
    }
    if (message.length > 100) {
      return '${message.substring(0, 100)}...';
    }
    return message;
  }
}