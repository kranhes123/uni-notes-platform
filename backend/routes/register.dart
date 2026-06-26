import 'dart:math';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../lib/db.dart';
import '../lib/auth_utils.dart';

bool isValidEmail(String email) {
  // Sadece @erciyes.edu.tr kabul et
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@erciyes\.edu\.tr$');
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
        body: {'message': 'Lütfen geçerli bir Erciyes Üniversitesi mail adresi girin (@erciyes.edu.tr).'},
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

    // 6 haneli kod üret, 15 dakika geçerli
    final code = (Random().nextInt(900000) + 100000).toString();
    final expiresAt = DateTime.now()
        .add(const Duration(minutes: 15))
        .toIso8601String();

    await users.insertOne({
      '_id': ObjectId(),
      'fullName': fullName,
      'email': email,
      'passwordHash': hashPassword(password),
      'university': university,
      'department': department,
      'grade': grade,
      'selectedCourses': <Map<String, dynamic>>[],
      'isVerified': false,
      'verificationCode': code,
      'verificationExpiresAt': expiresAt,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Resend ile doğrulama maili gönder
    final resendApiKey = Platform.environment['RESEND_API_KEY'] ?? '';
    final mailResponse = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $resendApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': 'Uni Notes <onboarding@resend.dev>',
        'to': [email],
        'subject': 'E-posta Doğrulama Kodu',
        'html': '''
          <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; border-radius: 12px; border: 1px solid #e5e7eb;">
            <h2 style="color: #3730a3;">Uni Notes</h2>
            <p style="font-size: 16px; color: #374151;">Doğrulama kodunuz:</p>
            <div style="font-size: 36px; font-weight: bold; letter-spacing: 12px; color: #3730a3; padding: 16px 0;">
              $code
            </div>
            <p style="font-size: 14px; color: #6b7280;">Bu kod 15 dakika içinde geçersiz olur.</p>
          </div>
        ''',
      }),
    );

    if (mailResponse.statusCode != 200 && mailResponse.statusCode != 201) {
      print('RESEND ERROR: ${mailResponse.body}');
      return Response.json(
        statusCode: 500,
        body: {
          'message': 'Hesap oluşturuldu ancak doğrulama maili gönderilemedi. Lütfen destek ile iletişime geçin.',
        },
      );
    }

    return Response.json(
      statusCode: 201,
      body: {
        'message': 'Kayıt başarılı',
        'email': email,
        'needsVerification': true,
      },
    );
  } catch (e, st) {
    print('REGISTER ERROR: $e');
    print(st);
    return Response.json(
      statusCode: 500,
      body: {'message': 'Hata oluştu', 'error': e.toString()},
    );
  }
}