import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../generated/api.pbgrpc.dart';
import '../sse_stub.dart'
  if (dart.library.html) '../sse_client_web.dart';
import '../grpc_stub.dart' if (dart.library.io) 'package:grpc/grpc.dart' as grpc;

enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
}

class MetricsProvider extends ChangeNotifier {
  // Храним последние метрики для каждого пользователя
  final Map<String, UserMetric> _userMetrics = {};
  
  // Состояние подключения
  ConnectionStatus _connectionStatus = ConnectionStatus.connecting;
  String? _errorMessage;
  int _reconnectCountdown = 0; // Счетчик обратного отсчета
  
  // Для gRPC
  dynamic _channel;
  MetricsClient? _client;
  Stream<UserMetric>? _stream;
  StreamSubscription<UserMetric>? _streamSubscription;
  
  // Флаги управления
  bool _isListening = false;
  bool _shouldStop = false;
  
  // Геттеры
  Map<String, UserMetric> get userMetrics => Map.unmodifiable(_userMetrics);
  List<UserMetric> get usersList => _userMetrics.values.toList();
  bool get hasData => _userMetrics.isNotEmpty;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  int get reconnectCountdown => _reconnectCountdown;
  
  // Получить метрику конкретного пользователя
  UserMetric? getUser(String userId) => _userMetrics[userId];
  
  // Инициализация подключения к потоку данных с автоматическим переподключением
  void startListening() {
    if (_isListening) return;
    _isListening = true;
    _shouldStop = false;
    _startListeningLoop();
  }
  
  // Основной цикл прослушивания с автоматическим переподключением
  void _startListeningLoop() async {
    while (!_shouldStop) {
      try {
        _updateConnectionStatus(ConnectionStatus.connecting, null);

        if (kIsWeb) {
          await _listenSSEStream();
        } else {
          await _listenGrpcStream();
        }
      } catch (e) {
        if (!_shouldStop) {
          debugPrint('Connection error: $e');
          _updateConnectionStatus(
            ConnectionStatus.error,
            'Server connection lost',
          );

          // Запускаем обратный отсчет перед следующей попыткой
          for (int i = 5; i > 0; i--) {
            if (_shouldStop) break;
            _updateReconnectCountdown(i);
            await Future.delayed(const Duration(seconds: 1));
          }

          // Если не было команды на остановку, продолжаем
          if (!_shouldStop) {
            _updateReconnectCountdown(0);
          }
        }
      }
    }
  }
  
  // Прослушивание SSE потока для веба
  Future<void> _listenSSEStream() async {
    final stream = sseUserMetricStream('https://localhost:8143/metrics/sse');
    StreamSubscription<UserMetric>? subscription;
    final completer = Completer<void>();
    
    subscription = stream.listen(
      (metric) {
        if (_shouldStop) {
          subscription?.cancel();
          if (!completer.isCompleted) completer.complete();
          return;
        }
        _updateMetric(metric);
      },
      onError: (error) {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          // Если поток закрылся без ошибки, но мы не должны останавливаться,
          // считаем это ошибкой для переподключения
          if (!_shouldStop) {
            completer.completeError(Exception('SSE stream closed unexpectedly'));
          } else {
            completer.complete();
          }
        }
      },
      cancelOnError: false,
    );
    
    try {
      await completer.future;
    } finally {
      subscription.cancel();
    }
  }
  
  // Прослушивание gRPC потока для мобильных платформ
  Future<void> _listenGrpcStream() async {
    // Закрываем предыдущее подключение, если есть
    _cleanupGrpc();
    
    _channel = grpc.ClientChannel(
      'localhost',
      port: 8143,
      options: grpc.ChannelOptions(
        credentials: grpc.ChannelCredentials.insecure(),
      ),
    );
    _client = MetricsClient(_channel);
    
    final call = _client!.getStats(Empty());
    _stream = call;
    
      await for (var metric in _stream!) {
        if (_shouldStop) break;
        _updateMetric(metric);
      }
  }
  
  // Обновление метрики пользователя
  void _updateMetric(UserMetric metric) {
    _userMetrics[metric.userId] = metric;
    // После получения данных обновляем статус соединения
    if (_connectionStatus != ConnectionStatus.connected) {
      _updateConnectionStatus(ConnectionStatus.connected, null);
    } else {
      notifyListeners();
    }
  }
  
  // Обновление статуса подключения
  void _updateConnectionStatus(ConnectionStatus status, String? error) {
    // Не сбрасываем статус ошибки, если мы переходим в connected,
    // но еще не получили данные
    if (status == ConnectionStatus.connected && !hasData) {
      return;
    }

    _connectionStatus = status;
    _errorMessage = error;
    _reconnectCountdown = 0; // Сбрасываем счетчик при изменении статуса
    notifyListeners();
  }

  // Обновление счетчика обратного отсчета
  void _updateReconnectCountdown(int seconds) {
    _reconnectCountdown = seconds;
    notifyListeners();
  }
  
  // Очистка gRPC ресурсов
  void _cleanupGrpc() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    try {
      _channel?.shutdown();
    } catch (_) {}
    _channel = null;
    _client = null;
    _stream = null;
  }
  
  // Остановка прослушивания
  void stopListening() {
    _shouldStop = true;
    _isListening = false;
    _cleanupGrpc();
  }
  
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
