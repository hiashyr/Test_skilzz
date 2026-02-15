import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc_web.dart';
import '../generated/api.pbgrpc.dart';

/// StreamProvider который накапливает всех пользователей
final metricsStreamProvider = StreamProvider.autoDispose<List<UserMetric>>((ref) {
  final controller = StreamController<List<UserMetric>>();
  final usersMap = <String, UserMetric>{}; // Мапа со всеми пользователями

  ref.onDispose(
    () async {
      await controller.close();
    },
  );

  () async {
    while (!controller.isClosed) {
      GrpcWebClientChannel? channel;

      try{
        channel = GrpcWebClientChannel.xhr(
          Uri.parse('https://localhost:8143'),
        );
        final client = MetricsClient(channel);

        await for (final metric in client.getStats(Empty())) {
          if (controller.isClosed) break;

       usersMap[metric.userId] = metric;
          controller.add(usersMap.values.toList());
        }
      } catch (e, s) {
        if (!controller.isClosed) {
          controller.addError('Не удалось подключиться к серверу: $e', s);
          await Future.delayed(const Duration(seconds: 3));
        }
      } finally {
        await channel?.shutdown();
      }
    }
  }();

  return controller.stream;
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
    error: (error, stackTrace) {
      debugPrint('Error loading user $userId: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  );
});