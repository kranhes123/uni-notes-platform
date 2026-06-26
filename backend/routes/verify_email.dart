import 'package:dart_frog/dart_frog.dart';
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

    final users = await DbService.usersCollection();
    final user = await users.findOne({'email': email});

    if (user == null) {
      return Response.json(
        statusCode: 404,
        body: {'message': 'Kullanıcı bulunamadı.'},
      );
    }

    final storedCode = user['verificationCode']?.toString() ?? '';
    final expiresAt = user['verificationExpiresAt'] as String? ?? '';

    if (storedCode != code) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'Kod hatalı. Lütfen tekrar deneyin.'},
      );
    }

    if (DateTime.now().isAfter(DateTime.parse(expiresAt))) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'Kodun süresi dolmuş. Yeni kod talep edin.', 'expired': true},
      );
    }

    // Doğrulama başarılı — hesabı aktif et, kodu sil
    await users.updateOne(
      {'email': email},
      {
        r'$set': {'isVerified': true},
        r'$unset': {'verificationCode': '', 'verificationExpiresAt': ''},
      },
    );

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