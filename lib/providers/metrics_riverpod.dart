import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc_web.dart';
import '../generated/api.pbgrpc.dart';

/// StreamProvider который накапливает всех пользователей
final metricsStreamProvider = StreamProvider.autoDispose<List<UserMetric>>((ref) async* {
  final usersMap = <String, UserMetric>{}; // 🗃️ Храним ВСЕХ пользователей
  var shouldStop = false;

  ref.onDispose(() => shouldStop = true);

  const reconnectDelay = Duration(seconds: 1);

  while (!shouldStop) {
    GrpcWebClientChannel? channel;
    MetricsClient? client;
    
    try {
      channel = GrpcWebClientChannel.xhr(Uri.parse('https://localhost:8143'));
      client = MetricsClient(channel);

      // Слушаем поток
      await for (final metric in client.getStats(Empty())) {
        if (shouldStop) break;
        
        // 🔥 КЛЮЧЕВОЕ: Сохраняем или обновляем пользователя в Map
        usersMap[metric.userId] = metric;
        
        // Отправляем ВСЕХ пользователей
        yield usersMap.values.toList();
      }
      
    } catch (e) {
      // Ошибка - просто продолжаем цикл
    } finally {
      await channel?.shutdown();
    }

    if (shouldStop) break;
    await Future.delayed(reconnectDelay);
  }
});

/// Провайдер для получения конкретного пользователя по ID
final userByIdProvider = Provider.family.autoDispose<UserMetric?, String>((ref, userId) {
  final usersAsync = ref.watch(metricsStreamProvider);
  
  return usersAsync.when(
    data: (usersList) {
      // 🔍 Ищем пользователя в списке
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