import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc_web.dart';
import '../generated/api.pbgrpc.dart';

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
  
  // Для gRPC-web
  GrpcWebClientChannel? _channel;
  MetricsClient? _client;
  Stream<UserMetric>? _stream;
  
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
    const int retrySeconds = 5;
    while (!_shouldStop) {
      try {
        _updateConnectionStatus(ConnectionStatus.connecting, null);
        await _listenGrpcWebStream();
      } catch (e) {
        if (!_shouldStop) {
          debugPrint('Connection error: $e');
          _updateConnectionStatus(ConnectionStatus.error, 'Подключение потеряно');

          // Обратный отсчёт перед повторной попыткой
          await _startReconnectCountdown(retrySeconds);
        }
      }
    }
  }
  
  
  // Прослушивание gRPC-web потока
  Future<void> _listenGrpcWebStream() async {
    // Закрываем предыдущее подключение, если есть
    _cleanupGrpc();

    _channel = GrpcWebClientChannel.xhr(Uri.parse('https://localhost:8143'));
    _client = MetricsClient(_channel!);
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

  // Запуск обратного отсчёта с возможностью прерывания
  Future<void> _startReconnectCountdown(int seconds) async {
    for (int i = seconds; i > 0; i--) {
      if (_shouldStop) break;
      _updateReconnectCountdown(i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!_shouldStop) _updateReconnectCountdown(0);
  }
  
  // Очистка gRPC-web ресурсов
  void _cleanupGrpc() {
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
