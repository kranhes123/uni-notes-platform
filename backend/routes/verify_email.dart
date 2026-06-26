import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'message': 'Method not allowed'});
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final email = (body['email'] ?? '').toString().trim().toLowerCase();
    final code = (body['code'] ?? '').toString().trim();

    if (email.isEmpty || code.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'E-posta ve kod gerekli.'},
      );
    }

    final pending = await DbService.pendingRegistrationsCollection();
    final users = await DbService.usersCollection();

    final pendingUser = await pending.findOne({'email': email});

    if (pendingUser == null) {
      // Belki kullanıcı zaten doğrulanıp users'a taşınmıştır
      final alreadyVerified = await users.findOne({'email': email});
      if (alreadyVerified != null) {
        return Response.json(
          statusCode: 400,
          body: {'message': 'Bu hesap zaten doğrulanmış. Giriş yapabilirsiniz.'},
        );
      }
      return Response.json(
        statusCode: 404,
        body: {
          'message':
              'Bekleyen bir kayıt bulunamadı. Lütfen yeniden kayıt olun.',
        },
      );
    }

    final storedCode = pendingUser['verificationCode']?.toString() ?? '';
    final expiresAt = pendingUser['verificationExpiresAt'] as String? ?? '';

    if (storedCode != code) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'Kod hatalı. Lütfen tekrar deneyin.'},
      );
    }

    if (expiresAt.isEmpty || DateTime.now().isAfter(DateTime.parse(expiresAt))) {
      return Response.json(
        statusCode: 400,
        body: {
          'message': 'Kodun süresi dolmuş. Yeni kod talep edin.',
          'expired': true,
        },
      );
    }

    // Email'in arada başka biri tarafından alınmadığından emin ol
    // (aynı anda iki kişi aynı emaili kayıt etmeye çalışmış olabilir)
    final existingUser = await users.findOne({'email': email});
    if (existingUser != null) {
      await pending.deleteOne({'email': email});
      return Response.json(
        statusCode: 409,
        body: {'message': 'Bu e-posta zaten kayıtlı.'},
      );
    }

    // Doğrulama başarılı — kullanıcıyı asıl tabloya taşı
    await users.insertOne({
      '_id': ObjectId(),
      'fullName': pendingUser['fullName'],
      'email': pendingUser['email'],
      'passwordHash': pendingUser['passwordHash'],
      'university': pendingUser['university'],
      'department': pendingUser['department'],
      'grade': pendingUser['grade'],
      'selectedCourses': <Map<String, dynamic>>[],
      'isVerified': true,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Bekleyen kaydı temizle
    await pending.deleteOne({'email': email});

    return Response.json(
      statusCode: 200,
      body: {'message': 'E-posta başarıyla doğrulandı. Artık giriş yapabilirsiniz.'},
    );
  } catch (e, st) {
    print('VERIFY ERROR: $e');
    print(st);
    return Response.json(
      statusCode: 500,
      body: {'message': 'Hata oluştu', 'error': e.toString()},
    );
  }
}