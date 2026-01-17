import 'dart:io';
import 'package:grpc/grpc.dart';
import 'generated/api.pbgrpc.dart';

Future<void> main() async {
  print('🚀 gRPC CLI Клиент для получения метрик пульса');
  print('=' * 60);

  final channel = ClientChannel(
    'localhost',
    port: 8143,
    options: ChannelOptions(
      credentials: ChannelCredentials.secure(
        onBadCertificate: (X509Certificate cert, String host) => true,
      ),
    ),
  );

  final client = MetricsClient(channel);

  try {
    print('📡 Подключение к серверу на localhost:8143...\n');

    // Создаем запрос
    final request = Empty();

    // Получаем stream метрик
    final stream = client.getStats(request);

    print('✅ Подключено! Получение данных...\n');
    print('-' * 60);

    // Обрабатываем поток данных
    await for (final metric in stream) {
      final timestamp = DateTime.now().toLocal().toString().split('.')[0];
      print(
        '👤 ${metric.userName.padRight(15)} | '
        '❤️  ${metric.heartRate.toString().padLeft(3)} bpm | '
        '🕐 $timestamp',
      );
    }
  } on GrpcError catch (e) {
    print('❌ Ошибка gRPC: ${e.message}');
    print('Код: ${e.code}');
  } catch (e) {
    print('❌ Ошибка: $e');
  } finally {
    await channel.shutdown();
    print('\n' + '-' * 60);
    print('🔌 Соединение закрыто');
  }
}
