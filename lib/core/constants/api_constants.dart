import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get host {
    if (kIsWeb) {
      return 'localhost';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      default:
        return 'localhost';
    }
  }

  static String get baseUrl => 'http://$host:9000/api';
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String questionnaireUrl(int userId, int requesterId) =>
      '$baseUrl/users/$userId/questionnaire?requesterId=$requesterId';
  static String questionnaireStatusUrl(int userId, int requesterId) =>
      '$baseUrl/users/$userId/questionnaire-status?requesterId=$requesterId';
  static String ratingUrl(int requesterId) => '$baseUrl/users/list?requesterId=$requesterId';
  static String candidateDetailsUrl(int userId, int requesterId) =>
      '$baseUrl/users/$userId/details?requesterId=$requesterId';
}
