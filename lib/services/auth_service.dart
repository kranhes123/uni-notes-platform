import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://uni-notes-platform-production.up.railway.app';

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String university,
    required String department,
    required String grade,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'university': university,
        'department': department,
        'grade': grade,
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Yeni: e-posta doğrulama kodu kontrolü
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify_email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {'success': response.statusCode == 200, ...data};
  }
}