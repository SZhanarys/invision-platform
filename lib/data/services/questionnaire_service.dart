import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';

class QuestionnaireService {
  Future<Map<String, dynamic>> fetchStatus(int userId) async {
    final uri = Uri.parse(ApiConstants.questionnaireStatusUrl(userId, userId));

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      debugPrint('Questionnaire status -> ${response.statusCode} ${uri.toString()}');

      if (response.statusCode != 200) {
        return {'submitted': false};
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (error, stackTrace) {
      debugPrint('Questionnaire status failed -> $error');
      debugPrintStack(stackTrace: stackTrace);
      return {'submitted': false};
    }
  }

  Future<Map<String, dynamic>> submit({
    required int userId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String skillsInput,
    required String valueStatement,
    required String experienceSummary,
    required String projectsInput,
  }) async {
    final uri = Uri.parse(ApiConstants.questionnaireUrl(userId, userId));

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'firstName': firstName,
              'lastName': lastName,
              'phoneNumber': phoneNumber,
              'skillsInput': skillsInput,
              'valueStatement': valueStatement,
              'experienceSummary': experienceSummary,
              'projectsInput': projectsInput,
            }),
          )
          .timeout(const Duration(seconds: 45));

      debugPrint('Questionnaire submit -> ${response.statusCode} ${uri.toString()}');
      debugPrint('Questionnaire response -> ${response.body}');

      if (response.body.isEmpty) {
        return {
          'ok': false,
          'message': 'Сервер вернул пустой ответ (${response.statusCode})',
        };
      }

      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'ok': response.statusCode == 200,
          'message': (data['message'] ?? 'Ошибка запроса').toString(),
          'data': data,
          'statusCode': response.statusCode,
        };
      } catch (_) {
        return {
          'ok': false,
          'message': 'Сервер вернул некорректный JSON (${response.statusCode})',
          'statusCode': response.statusCode,
        };
      }
    } on TimeoutException {
      return {
        'ok': false,
        'message':
            'Сервер отвечает слишком долго. Если включен AI-анализ, попробуйте подождать дольше и повторить.',
      };
    } catch (error, stackTrace) {
      debugPrint('Questionnaire submit failed -> $error');
      debugPrintStack(stackTrace: stackTrace);
      return {
        'ok': false,
        'message':
            'Не удалось отправить анкету. Откройте Network в браузере или проверьте лог backend.',
      };
    }
  }
}
