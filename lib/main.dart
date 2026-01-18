import 'package:flutter/material.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Heart Rate Monitor',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
