import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/metrics_provider.dart';
import '../providers/metrics_riverpod.dart';
import '../widgets/user_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/theme_toggle_button.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsProvider = ref.watch(metricsNotifierProvider);

    final connectionStatus = metricsProvider.connectionStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Монитор сердечного ритма'),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Builder(
        builder: (_) {
          if (connectionStatus == ConnectionStatus.error &&
              metricsProvider.errorMessage != null) {
            return ErrorMessageWidget(
              useBrokenHeart: true,
              message: metricsProvider.errorMessage!,
              subtitle: 'Приложение автоматически переподключится, когда сервер станет доступен.',
              reconnectCountdown: metricsProvider.reconnectCountdown > 0
                  ? metricsProvider.reconnectCountdown
                  : null,
            );
          }

          if (connectionStatus == ConnectionStatus.connecting || !metricsProvider.hasData) {
            return const LoadingWidget(
              message: 'Ожидание данных...',
            );
          }

          final usersList = metricsProvider.usersList;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: usersList.length,
                  itemBuilder: (context, index) {
                    final user = usersList[index];
                    return UserCard(
                      user: user,
                      onTap: () => context.go('/user/${user.userId}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
