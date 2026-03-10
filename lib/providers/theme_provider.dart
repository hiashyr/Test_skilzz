import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Создаем Notifier класс
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Начальное состояние
    return ThemeMode.dark;
  }

  // Геттер
  bool get isDarkMode => state == ThemeMode.dark;

  // Методы изменения состояния
  void toggleTheme() {
    state = state == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
  }

  void setTheme(ThemeMode mode) {
    if (state != mode) {
      state = mode;
    }
  }
}

// Создаем провайдер
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

// геттер для isDarkMode
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider) == ThemeMode.dark;
});