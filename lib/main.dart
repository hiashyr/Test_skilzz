import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'providers/metrics_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MetricsProvider()..startListening(),
      child: MaterialApp.router(
        title: 'Heart Rate Monitor',
        theme: ThemeData(
          primarySwatch: Colors.red,
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
