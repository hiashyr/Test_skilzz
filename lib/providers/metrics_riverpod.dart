import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc_web.dart';
import '../generated/api.pbgrpc.dart';

/// StreamProvider который накапливает всех пользователей
final metricsStreamProvider = StreamProvider.autoDispose<List<UserMetric>>((ref) async* {
  final usersMap = <String, UserMetric>{}; // Мапа со всеми пользователями
  var shouldStop = false;

  ref.onDispose(() => shouldStop = true);

  while (!shouldStop) {
    GrpcWebClientChannel? channel;
    MetricsClient? client;
    
    try {
      channel = GrpcWebClientChannel.xhr(Uri.parse('https://localhost:8143'));
      client = MetricsClient(channel);

      // Слушаем поток
      await for (final metric in client.getStats(Empty())) {
        if (shouldStop) break;
        
        // 🔥 Сохраняем или обновляем пользователя в Map
        usersMap[metric.userId] = metric;
        
        // Отправляем всех пользователей
        yield usersMap.values.toList();
      }
      
    } catch (e) {
      // При ошибке подключения выбрасываем исключение, чтобы UI показал состояние ошибки
      throw Exception('Не удалось подключиться к серверу: $e');
    } finally {
      await channel?.shutdown();
    }

    if (shouldStop) break;
  }
});

/// Провайдер для получения конкретного пользователя по ID
final userByIdProvider = Provider.family.autoDispose<UserMetric?, String>((ref, userId) {
  final usersAsync = ref.watch(metricsStreamProvider);
  
  return usersAsync.when(
    data: (usersList) {
      // Ищем пользователя в списке
      try {
        return usersList.firstWhere((u) => u.userId == userId);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, _) => null,
  );
});