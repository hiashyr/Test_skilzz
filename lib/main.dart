import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc_web.dart';
import './generated/api.pbgrpc.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

// Модель для хранения данных пользователя
class UserData {
  final String userId;
  final String userName;
  final int heartRate;
  
  const UserData({
    required this.userId,
    required this.userName,
    required this.heartRate,
  });
}

// Главный провайдер, который получает все метрики
final allUsersProvider = StreamProvider.autoDispose<List<UserData>>(
  (ref) async* {
    final channel = GrpcWebClientChannel.xhr(
      Uri.parse('https://localhost:8143'),
    );
    final client = MetricsClient(channel);
    
    ref.onDispose(() => channel.shutdown());
    
    // Храним данные всех пользователей
    final usersData = <String, UserData>{};
    
    await for (final metric in client.getStats(Empty())) {
      // Обновляем данные для пользователя
      usersData[metric.userId] = UserData(
        userId: metric.userId,
        userName: metric.userName,
        heartRate: metric.heartRate,
      );
      
      // Отправляем список всех пользователей
      yield usersData.values.toList();
    }
  },
);

// Провайдер для конкретного пользователя (по ID)
final userDataProvider = Provider.family.autoDispose<UserData?, String>(
  (ref, userId) {
    final users = ref.watch(allUsersProvider);
    
    return users.when(
      data: (userList) => userList.firstWhere(
        (user) => user.userId == userId
      ),
      loading: () => null,
      error: (error, stack) => null,
    );
  },
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Монитор пульса')),
        body: const AllUsersList(),
      ),
    );
  }
}

class AllUsersList extends ConsumerWidget {
  const AllUsersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = ref.watch(allUsersProvider);
    
    return usersState.when(
      data: (users) => users.isEmpty
          ? const Center(child: Text('Нет данных о пользователях'))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user.userName),
                  subtitle: Text('ID: ${user.userId}'),
                  trailing: Text('${user.heartRate} уд/мин'),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Ошибка: $error')),
    );
  }
}