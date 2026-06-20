import 'package:dart_frog/dart_frog.dart';

import '../lib/db.dart';
import '../lib/auth_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {
        'message': 'Method not allowed',
      },
    );
  }

  bool isEnglish = false;

  try {
    final body = await context.request.json() as Map<String, dynamic>;

    final language = (body['language'] ?? 'TR').toString();
    isEnglish = language == 'EN';

    final email =
        (body['email'] ?? '').toString().trim().toLowerCase();

    final password =
        (body['password'] ?? '').toString().trim();

    if (email.isEmpty || password.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'message': isEnglish
              ? 'Email and password are required.'
              : 'E-posta ve şifre gerekli.',
        },
      );
    }

    final users = await DbService.usersCollection();

    final user = await users.findOne({
      'email': email,
    });

    if (user == null) {
      return Response.json(
        statusCode: 401,
        body: {
          'message': isEnglish
              ? 'User not found.'
              : 'Kullanıcı bulunamadı.',
        },
      );
    }

    final storedPasswordHash =
        user['passwordHash']?.toString() ?? '';

    if (storedPasswordHash != hashPassword(password)) {
      return Response.json(
        statusCode: 401,
        body: {
          'message': isEnglish
              ? 'Incorrect password.'
              : 'Şifre yanlış.',
        },
      );
    }

    return Response.json(
      statusCode: 200,
      body: {
        'message': isEnglish
            ? 'Login successful'
            : 'Giriş başarılı',
        'user': {
          'fullName': user['fullName'],
          'email': user['email'],
          'university': user['university'],
          'department': user['department'],
          'grade': user['grade'],
          'selectedCourses':
              ((user['selectedCourses'] as List?) ?? [])
                  .map(
                    (item) =>
                        Map<String, dynamic>.from(item as Map),
                  )
                  .toList(),
        },
      },
    );
  } catch (e, st) {
    print('LOGIN ERROR: $e');
    print(st);

    return Response.json(
      statusCode: 500,
      body: {
        'message': isEnglish
            ? 'An error occurred'
            : 'Hata oluştu',
        'error': e.toString(),
      },
    );
  }
}