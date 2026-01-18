import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../generated/api.pbgrpc.dart';
import '../sse_stub.dart'
  if (dart.library.html) '../sse_client_web.dart';
import '../grpc_stub.dart' if (dart.library.io) 'package:grpc/grpc.dart' as grpc;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Используем dynamic для совместимости с заглушкой на вебе
  dynamic _channel;
  MetricsClient? _client;
  // Храним последние метрики для каждого пользователя
  final Map<String, UserMetric> _userMetrics = {};
  Stream<UserMetric>? _stream;
  StreamSubscription<UserMetric>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Use SSE stream for web clients
      final stream = sseUserMetricStream('https://localhost:8143/metrics/sse');
      _streamSubscription = stream.listen(
        (metric) {
          if (mounted) {
            setState(() {
              // Обновляем последнюю метрику для пользователя
              _userMetrics[metric.userId] = metric;
            });
          }
        },
        onError: (e) {
          debugPrint('SSE error: $e');
        },
      );
    } else {
      // Fallback: use direct gRPC client on non-web
      _channel = grpc.ClientChannel(
        'localhost',
        port: 8143,
        options: grpc.ChannelOptions(
          credentials: grpc.ChannelCredentials.insecure(),
        ),
      );
      _client = MetricsClient(_channel);
      _startStream();
    }
  }

  void _startStream() {
    if (_client == null) return;
    final call = _client!.getStats(Empty());
    _stream = call;
    _streamSubscription = _stream!.listen(
      (metric) {
        if (mounted) {
          setState(() {
            _userMetrics[metric.userId] = metric;
          });
        }
      },
      onError: (e) {
        debugPrint('Stream error: $e');
      },
    );
  }

  @override
  void dispose() {
    // Отменяем подписку на поток
    _streamSubscription?.cancel();
    // Закрываем gRPC канал
    try {
      _channel?.shutdown();
    } catch (_) {}
    super.dispose();
  }

  void _navigateToUserDetail(String userId) {
    context.go('/user/$userId');
  }

  @override
  Widget build(BuildContext context) {
    final usersList = _userMetrics.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Monitor'),
        centerTitle: true,
      ),
      body: usersList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Waiting for data...'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: usersList.length,
              itemBuilder: (context, index) {
                final user = usersList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red.shade700,
                      ),
                    ),
                    title: Text(
                      user.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('User ID: ${user.userId}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${user.heartRate}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getHeartRateColor(user.heartRate),
                          ),
                        ),
                        Text(
                          'bpm',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToUserDetail(user.userId),
                  ),
                );
              },
            ),
    );
  }

  Color _getHeartRateColor(int heartRate) {
    if (heartRate < 60) return Colors.blue;
    if (heartRate <= 100) return Colors.green;
    if (heartRate <= 120) return Colors.orange;
    return Colors.red;
  }
}
