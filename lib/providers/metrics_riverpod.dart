import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc_web.dart';
import '../generated/api.pbgrpc.dart';

/// Расширенное состояние, которое включает информацию о переподключении
class MetricsStreamState {
  final List<UserMetric>? data;
  final bool isReconnecting;
  final String? lastError;
  
  const MetricsStreamState({
    this.data,
    this.isReconnecting = false,
    this.lastError,
  });
}

/// StreamProvider с явным состоянием загрузки при переподключении
final metricsStreamProvider = StreamProvider.autoDispose<MetricsStreamState>((ref) async* {
  final usersData = <String, UserMetric>{};
  var shouldStop = false;

  ref.onDispose(() => shouldStop = true);

  var attemptCount = 0;
  const reconnectDelay = Duration(milliseconds: 300); // ← Маленькая задержка

  while (!shouldStop) {
    attemptCount++;
    
    // 1. Показываем состояние "переподключение"
    yield MetricsStreamState(
      data: usersData.values.toList(),
      isReconnecting: true,
      lastError: attemptCount > 1 ? 'Попытка переподключения $attemptCount' : null,
    );

    // 2. Даем UI время отрисовать спиннер
    await Future.delayed(const Duration(milliseconds: 100));

    GrpcWebClientChannel? channel;
    MetricsClient? client;
    
    try {
      channel = GrpcWebClientChannel.xhr(Uri.parse('https://localhost:8143'));
      client = MetricsClient(channel);

      // 3. Успешное подключение
      yield MetricsStreamState(
        data: usersData.values.toList(),
        isReconnecting: false,
        lastError: null,
      );

      // 4. Слушаем поток
      await for (final metric in client.getStats(Empty())) {
        if (shouldStop) break;
        usersData[metric.userId] = metric;
        yield MetricsStreamState(
          data: usersData.values.toList(),
          isReconnecting: false,
          lastError: null,
        );
      }
    } catch (e) {
      // 5. Ошибка подключения
      yield MetricsStreamState(
        data: usersData.values.toList(),
        isReconnecting: true,
        lastError: e.toString(),
      );
    } finally {
      channel = null;
      client = null;
    }

    if (shouldStop) break;
    
    // 6. Пауза перед следующей попыткой (если сразу переподключаться)
    await Future.delayed(reconnectDelay);
  }
});

/// Упрощенный провайдер для конкретного пользователя
final userByIdProvider = Provider.family.autoDispose<UserMetric?, String>((ref, userId) {
  final state = ref.watch(metricsStreamProvider);
  
  return state.when(
    data: (streamState) {
      if (streamState.data == null) return null;
      for (final u in streamState.data!) {
        if (u.userId == userId) return u;
      }
      return null;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

/// Провайдер для состояния переподключения
final isReconnectingProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(metricsStreamProvider);
  
  return state.when(
    data: (streamState) => streamState.isReconnecting,
    loading: () => true,  // Первоначальная загрузка
    error: (_, _) => false,
  );
});