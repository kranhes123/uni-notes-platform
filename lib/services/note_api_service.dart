import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note_model.dart';

class NoteApiService {
  final String baseUrl;

  NoteApiService({required this.baseUrl});
Future<Map<String, dynamic>> createNote(NoteModel note) async {
  final uri = Uri.parse('$baseUrl/notes');

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(note.toJson()),
  );

  final data = jsonDecode(response.body);

  // ❗ BENZERLİK VAR (409)
  if (response.statusCode == 409) {
    return {
      'success': false,
      'message': data['message'],
      'similarity': data['similarity'],
      'similarNoteTitle': data['similarNoteTitle'],
      'isTooSimilar': true,
    };
  }

  // ❗ HATA
  if (response.statusCode != 200 && response.statusCode != 201) {
    return {
      'success': false,
      'message': data['message'] ?? 'Not kaydedilemedi',
      'similarity': 0,
      'isTooSimilar': false,
    };
  }

  // ✔️ BAŞARILI
  return {
    'success': true,
    'message': data['message'] ?? 'Not kaydedildi',
    'similarity': data['similarity'] ?? 0,
    'isTooSimilar': false,
  };
}

  Future<List<NoteModel>> getNotes() async {
    final uri = Uri.parse('$baseUrl/notes');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Notlar alınamadı: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final notesJson = data['notes'] as List<dynamic>;

    return notesJson
        .map((item) => NoteModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUserCourses(String email) async {
    final uri = Uri.parse('$baseUrl/user-courses?email=$email');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Kullanıcı dersleri alınamadı: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final courses = (data['selectedCourses'] as List<dynamic>? ?? []);

    return courses
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> addUserCourse({
    required String email,
    required String courseName,
    required String courseCode,
    required String department,
  }) async {
    final uri = Uri.parse('$baseUrl/user-courses');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'courseName': courseName,
        'courseCode': courseCode,
        'department': department,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ders eklenemedi: ${response.body}');
    }
  }

  Future<void> removeUserCourse({
    required String email,
    required String courseName,
    required String courseCode,
  }) async {
    final uri = Uri.parse('$baseUrl/user-courses');

    final response = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'courseName': courseName,
        'courseCode': courseCode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ders kaldırılamadı: ${response.body}');
    }
  }
}