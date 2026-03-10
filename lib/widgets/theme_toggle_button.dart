import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart'; // твой новый файл с провайдерами

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Следим за изменением темы через провайдер
    final isDarkMode = ref.watch(isDarkModeProvider);
    
    return IconButton(
      icon: Icon(
        isDarkMode 
            ? Icons.light_mode 
            : Icons.dark_mode,
      ),
      onPressed: () {
        // Получаем notifier и вызываем метод
        ref.read(themeProvider.notifier).toggleTheme();
      },
      tooltip: isDarkMode 
          ? 'Переключить на светлую тему' 
          : 'Переключить на темную тему',
    );
  }
}