import 'dart:convert';
import 'package:http/http.dart' as http;

const String YC_FUNCTION_URL = 
    'https://functions.yandexcloud.net/d4eblqs7ri9qtbvogojq';

void main() async {
  print('🧪 ТЕСТ ВЗАИМОДЕЙСТВИЯ DART ↔ YANDEX CLOUD');
  print('=' * 50);
  
  // Тест 1: Простая строка
  await runTest('Hello from Dart!');
  
  // Тест 2: Числа
  await runTest('12345');
  
  // Тест 3: Русский текст
  await runTest('Привет из Дарта!');
  
  // Тест 4: Пустая строка
  await runTest('');
  
  // Тест 5: Специальные символы
  await runTest('Test@2024#Cloud');
}

Future<void> runTest(String testData) async {
  print('\n📤 Тест: "$testData"');
  print('─' * 30);
  
  try {
    final result = await callYandexFunction(testData);
    
    if (result['success'] == true) {
      print('✅ УСПЕХ!');
      print('📝 Сообщение: ${result['message']}');
      print('📊 Данные:');
      
      final data = result['data'];
      print('   • Исходное: ${data['original']}');
      print('   • Модифицированное: ${data['modified']}');
      print('   • В верхнем регистре: ${data['uppercase']}');
      print('   • Длина: ${data['length']}');
      print('   • Время: ${data['timestamp']}');
    } else {
      print('❌ ОШИБКА: ${result['error']}');
    }
  } catch (e) {
    print('❌ ИСКЛЮЧЕНИЕ: $e');
  }
}

Future<Map<String, dynamic>> callYandexFunction(String testData) async {
  final url = Uri.parse(YC_FUNCTION_URL);
  
  print('Отправка запроса к Yandex Cloud...');
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'test_data': testData}),
  );
  
  print('Код ответа: ${response.statusCode}');
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
}