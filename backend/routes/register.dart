import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../lib/db.dart';
import '../lib/auth_utils.dart';

bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return emailRegex.hasMatch(email);
}

bool isStrongPassword(String password) {
  final hasMinLength = password.length >= 8;
  final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
  final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
  final hasDigit = RegExp(r'[0-9]').hasMatch(password);
  final hasSpecialChar =
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\\/\[\]=+;]').hasMatch(password);

  return hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigit &&
      hasSpecialChar;
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'message': 'Method not allowed'},
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;

    final fullName = (body['fullName'] ?? '').toString().trim();
    final email = (body['email'] ?? '').toString().trim().toLowerCase();
    final password = (body['password'] ?? '').toString();
    final university = (body['university'] ?? '').toString().trim();
    final department = (body['department'] ?? '').toString().trim();
    final grade = (body['grade'] ?? '').toString().trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        university.isEmpty ||
        department.isEmpty ||
        grade.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'Tüm alanları doldur.'},
      );
    }

    if (fullName.length < 3) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'Ad soyad en az 3 karakter olmalı.'},
      );
    }

    if (!isValidEmail(email)) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'Geçerli bir e-posta adresi gir.'},
      );
    }

    if (!isStrongPassword(password)) {
      return Response.json(
        statusCode: 400,
        body: {
          'message':
              'Şifre en az 8 karakter olmalı; büyük harf, küçük harf, rakam ve özel karakter içermeli.'
        },
      );
    }

    if (university.length < 3) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'Üniversite adı çok kısa.'},
      );
    }

    if (department.length < 2) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'Bölüm adı çok kısa.'},
      );
    }

    final users = await DbService.usersCollection();

    final existingUser = await users.findOne({'email': email});
    if (existingUser != null) {
      return Response.json(
        statusCode: 409,
        body: {'message': 'Bu e-posta zaten kayıtlı.'},
      );
    }

    await users.insertOne({
  '_id': ObjectId(),
  'fullName': fullName,
  'email': email,
  'passwordHash': hashPassword(password),
  'university': university,
  'department': department,
  'grade': grade,
  'selectedCourses': <Map<String, dynamic>>[],
  'createdAt': DateTime.now().toIso8601String(),
});

    return Response.json(
      statusCode: 201,
      body: {'message': 'Kayıt başarılı'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Hata oluştu', 'error': e.toString()},
    );
  }
}