import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User $userId'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 120,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'User ID: $userId',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a placeholder page',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
