import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'generated/api.pbgrpc.dart';
import 'sse_stub.dart'
  if (dart.library.html) 'sse_client_web.dart';

import 'grpc_stub.dart' if (dart.library.io) 'package:grpc/grpc.dart' as grpc;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gRPC Web Metrics',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MetricsPage(),
    );
  }
}

class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key});

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  late final grpc.ClientChannel _channel;
  late final MetricsClient _client;
  final List<UserMetric> _metrics = [];
  Stream<UserMetric>? _stream;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Use SSE stream for web clients
      // Connect directly to backend server (dev server runs on 8143)
      final stream = sseUserMetricStream('https://localhost:8143/metrics/sse');
      stream.listen((metric) {
        setState(() {
          _metrics.insert(0, metric);
          if (_metrics.length > 100) _metrics.removeLast();
        });
      }, onError: (e) {
        debugPrint('SSE error: $e');
      });
    } else {
      // Fallback: use direct gRPC client on non-web
      _channel = grpc.ClientChannel(
        'localhost',
        port: 8143,
        options: grpc.ChannelOptions(
          credentials: grpc.ChannelCredentials.insecure(),
        ),
      );
      _client = MetricsClient(_channel as dynamic);
      _startStream();
    }
  }

  void _startStream() {
    final call = _client.getStats(Empty());
    _stream = call;
    _stream!.listen((metric) {
      setState(() {
        _metrics.insert(0, metric);
        if (_metrics.length > 100) _metrics.removeLast();
      });
    }, onError: (e) {
      debugPrint('Stream error: $e');
    });
  }

  @override
  void dispose() {
    try {
      _channel.shutdown();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('gRPC Metrics (web)')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('Live user heart rate metrics from server'),
            const SizedBox(height: 12),
            Expanded(
              child: _metrics.isEmpty
                  ? const Center(child: Text('Waiting for data...'))
                  : ListView.builder(
                      itemCount: _metrics.length,
                      itemBuilder: (c, i) {
                        final m = _metrics[i];
                        return ListTile(
                          title: Text(m.userName),
                          trailing: Text('${m.heartRate} bpm'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
