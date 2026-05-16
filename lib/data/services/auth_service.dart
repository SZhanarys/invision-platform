import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class AuthService {
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Возвращаем JSON с id и role
    }
    return null;
  }

  Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.registerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': 'CANDIDATE' // Поменяли USER на CANDIDATE
      }),
    );

    return response.statusCode == 201;
  }
}