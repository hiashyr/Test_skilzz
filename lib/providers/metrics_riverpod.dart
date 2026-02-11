import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc_web.dart';
import '../generated/api.pbgrpc.dart';
import 'metrics_provider.dart' show ConnectionStatus;

class MetricsState {
  final Map<String, UserMetric> userMetrics;
  final ConnectionStatus connectionStatus;
  final String? errorMessage;
  final int reconnectCountdown;

  const MetricsState({
    required this.userMetrics,
    required this.connectionStatus,
    this.errorMessage,
    this.reconnectCountdown = 0,
  });

  MetricsState copyWith({
    Map<String, UserMetric>? userMetrics,
    ConnectionStatus? connectionStatus,
    String? errorMessage,
    int? reconnectCountdown,
  }) {
    return MetricsState(
      userMetrics: userMetrics ?? this.userMetrics,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      reconnectCountdown: reconnectCountdown ?? this.reconnectCountdown,
    );
  }

  List<UserMetric> get usersList => userMetrics.values.toList();

  bool get hasData => userMetrics.isNotEmpty;

  UserMetric? getUser(String userId) => userMetrics[userId];
}

class MetricsNotifier extends Notifier<MetricsState> {
  GrpcWebClientChannel? _channel;
  MetricsClient? _client;
  Stream<UserMetric>? _stream;
  bool _shouldStop = false;

  @override
  MetricsState build() {
    // initial state
    final initial = const MetricsState(
      userMetrics: {},
      connectionStatus: ConnectionStatus.connecting,
      errorMessage: null,
      reconnectCountdown: 0,
    );

    // Start listening after provider is created
    Future.microtask(() => startListening());

    // Ensure we cleanup on dispose
    ref.onDispose(() {
      _shouldStop = true;
      _cleanupGrpc();
    });

    return initial;
  }

  void startListening() {
    if (_shouldStop == false && (_stream != null)) return;
    _shouldStop = false;
    _startListeningLoop();
  }

  void stopListening() {
    _shouldStop = true;
    _cleanupGrpc();
  }

  Future<void> _startListeningLoop() async {
    const int retrySeconds = 5;
    while (!_shouldStop) {
      try {
        _setConnectionStatus(ConnectionStatus.connecting, null);
        await _listenGrpcWebStream();
      } catch (e) {
        if (!_shouldStop) {
          _setConnectionStatus(ConnectionStatus.error, 'Подключение потеряно');
          await _startReconnectCountdown(retrySeconds);
        }
      }
    }
  }

  Future<void> _listenGrpcWebStream() async {
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

  void _updateMetric(UserMetric metric) {
    final newMap = Map<String, UserMetric>.from(state.userMetrics);
    newMap[metric.userId] = metric;
    final next = state.copyWith(
      userMetrics: newMap,
      connectionStatus: ConnectionStatus.connected,
      errorMessage: null,
    );
    state = next;
  }

  void _setConnectionStatus(ConnectionStatus status, String? error) {
    state = state.copyWith(
      connectionStatus: status,
      errorMessage: error,
      reconnectCountdown: 0,
    );
  }

  void _updateReconnectCountdown(int seconds) {
    state = state.copyWith(reconnectCountdown: seconds);
  }

  Future<void> _startReconnectCountdown(int seconds) async {
    for (int i = seconds; i > 0; i--) {
      if (_shouldStop) break;
      _updateReconnectCountdown(i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!_shouldStop) _updateReconnectCountdown(0);
  }

  void _cleanupGrpc() {
    _channel = null;
    _client = null;
    _stream = null;
  }
}

final metricsNotifierProvider = NotifierProvider<MetricsNotifier, MetricsState>(MetricsNotifier.new);