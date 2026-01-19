import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/metrics_provider.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/user_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/theme_toggle_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Monitor'),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Consumer<MetricsProvider>(
        builder: (context, metricsProvider, child) {
          final connectionStatus = metricsProvider.connectionStatus;
          
          // Если есть ошибка подключения, показываем сообщение
          if (connectionStatus == ConnectionStatus.error && 
              metricsProvider.errorMessage != null) {
            return ErrorMessageWidget(
              useBrokenHeart: true,
              message: metricsProvider.errorMessage!,
              subtitle: 'The app will automatically reconnect when the server is available.',
            );
          }
          
          // Если подключаемся или нет данных
          if (connectionStatus == ConnectionStatus.connecting || 
              !metricsProvider.hasData) {
            return const LoadingWidget(
              message: 'Waiting for data...',
            );
          }

          final usersList = metricsProvider.usersList;

          return Column(
            children: [
              // Индикатор статуса подключения
              ConnectionStatusBar(
                status: connectionStatus,
                errorMessage: metricsProvider.errorMessage,
              ),
              // Список пользователей
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: usersList.length,
                  itemBuilder: (context, index) {
                    final user = usersList[index];
                    return UserCard(
                      user: user,
                      onTap: () => context.go('/user/${user.userId}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
