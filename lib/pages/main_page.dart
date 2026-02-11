import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_skilzz/generated/api.pb.dart';
import '../providers/metrics_riverpod.dart';
import '../widgets/user_card.dart';
import '../widgets/loading_widget.dart';
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
        // ✅ ЕСТЬ ДАННЫЕ - показываем ВСЕХ пользователей
        data: (usersList) {
          if (usersList.isEmpty) {
            return const Center(
              child: Text('Нет данных о пользователях'),
            );
          }

          // 🔥 Сортируем пользователей для стабильного отображения
          final sortedUsers = List<UserMetric>.from(usersList)
            ..sort((a, b) => a.userName.compareTo(b.userName));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedUsers.length,
            itemBuilder: (context, index) {
              final user = sortedUsers[index];
              return UserCard(
                user: user,
                onTap: () => context.go('/user/${user.userId}'),
              );
            },
          );
        },

        // 🔄 ЗАГРУЗКА
        loading: () => const LoadingWidget(
          message: 'Подключение к серверу...',
        ),

        // ❌ ОШИБКА - показываем спиннер вместо ошибки
        error: (err, stack) => const LoadingWidget(
          message: 'Подключение к серверу...',
        ),
      ),
    );
  }

}