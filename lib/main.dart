import 'dart:convert';
import 'package:http/http.dart' as http;

const String AI_FUNCTION_URL = 
    'https://functions.yandexcloud.net/d4eblqs7ri9qtbvogojq';

void main() async {
  print('🚀 AI Health Analyzer\n');
  
  // Тестовые данные пациента
  final healthData = {
    'patient_name': 'Сергей Иванов',
    'age': 35,
    'heart_rate': 85,
    'blood_pressure_systolic': 135,
    'blood_pressure_diastolic': 88,
    'temperature': 36.8,
    'blood_oxygen': 96,
  };
  
  // Отправляем запрос
  final response = await http.post(
    Uri.parse(AI_FUNCTION_URL),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'health_data': healthData}),
  );
  
  // Обрабатываем ответ
  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);
    
    if (result['success'] == true) {
      print('✅ Анализ успешен!');
      print('\n' + '=' * 40);
      print('🤖 AI АНАЛИЗ:');
      print('=' * 40);
      print(result['analysis']);
      print('=' * 40);
    } else {
      print('❌ Ошибка: ${result['error']}');
    }
  } else {
    print('❌ HTTP ошибка: ${response.statusCode}');
    print('Тело ответа: ${response.body}');
  }
}