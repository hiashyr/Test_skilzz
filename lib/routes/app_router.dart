import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/main_page.dart';
import '../pages/user_detail_screen.dart';

/// Конфигурация маршрутов приложения
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/user/:userId',
      name: 'user-detail',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return UserDetailScreen(userId: userId);
      },
    ),
  ],
  // Обработка ошибок навигации
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
