import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/metrics_riverpod.dart';
import '../widgets/user_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/theme_toggle_button.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(metricsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Монитор сердечного ритма'),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: usersAsync.when(
        data: (streamState) {
          // Если идёт переподключение — показываем спиннер
          if (streamState.isReconnecting) {
            return const LoadingWidget(message: 'Ожидание сервера...');
          }

          final usersList = streamState.data ?? [];

          if (usersList.isEmpty) {
            return const Center(child: Text('Нет данных о пользователях'));
          }

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
        loading: () => const LoadingWidget(message: 'Ожидание данных...'),
        error: (err, stack) => ErrorMessageWidget(
          useBrokenHeart: true,
          message: err.toString(),
          subtitle: 'Попробуйте перезагрузить страницу.',
        ),
      ),
    );
  }
}
