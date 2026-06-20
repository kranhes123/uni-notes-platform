import 'dart:convert';
import 'package:http/http.dart' as http;

class UniversityService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<List<Map<String, dynamic>>> getCourses({
    required String department,
    required String grade,
    required String semester,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/courses'
        '?department=$department'
        '&grade=$grade'
        '&semester=$semester',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Dersler alınamadı');
    }

    final data = jsonDecode(response.body);

    return List<Map<String, dynamic>>.from(
      data['courses'],
    );
  }
}