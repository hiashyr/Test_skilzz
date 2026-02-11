import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/metrics_riverpod.dart';
import '../generated/api.pbgrpc.dart';
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
      body: Builder(
        builder: (context) {
          return usersAsync.when(
            data: (streamState) {
              // При переподключении показываем спиннер
              if (streamState.isReconnecting) {
                return const LoadingWidget(message: 'Ожидание сервера...');
              }

              final usersList = streamState.data ?? [];
              UserMetric? user;
              for (final u in usersList) {
                if (u.userId == widget.userId) {
                  user = u;
                  break;
                }
              }

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

              final userNonNull = user;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _previousHeartRate = userNonNull.heartRate;
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
                    title: Text(userNonNull.userName.isNotEmpty ? userNonNull.userName : 'Пользователь ${widget.userId}'),
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
            loading: () => const LoadingWidget(message: 'Ожидание данных...'),
            error: (err, stack) => CustomScrollView(
              slivers: [
                SliverAppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                  title: Text('Пользователь ${widget.userId}'),
                  actions: const [ThemeToggleButton()],
                ),
                SliverFillRemaining(
                  child: ErrorMessageWidget(
                    icon: Icons.heart_broken_rounded,
                    message: err.toString(),
                    subtitle: 'Попробуйте перезагрузить страницу.',
                    onAction: () => ref.refresh(metricsStreamProvider),
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
