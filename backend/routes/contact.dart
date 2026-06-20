import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// ── AYARLAR ──────────────────────────────────────────────────────────────
// Gmail gönderici hesabı (mailleri bu hesaptan gönderecek)
const String _senderEmail = 'duzyol975337@gmail.com';
// Google Hesap > Güvenlik > Uygulama Şifreleri'nden aldığın 16 haneli kod
// (boşlukları silerek tek parça yaz, örn: 'abcdwxyzabcdwxyz')
const String _senderAppPassword = 'lifatzfjyhyfcbxl';
// Mailin gideceği adres
const String _receiverEmail = 'duzyol975337@gmail.com';
// ─────────────────────────────────────────────────────────────────────────

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final name = (data['name'] as String?)?.trim() ?? '';
    final email = (data['email'] as String?)?.trim() ?? '';
    final message = (data['message'] as String?)?.trim() ?? '';

    if (name.isEmpty || message.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'name ve message zorunludur'},
      );
    }

    final smtpServer = gmail(_senderEmail, _senderAppPassword);

    final mailMessage = Message()
      ..from = Address(_senderEmail, 'Uni Notes İletişim Formu')
      ..recipients.add(_receiverEmail)
      ..subject = 'Uni Notes - Yeni İletişim Mesajı: $name'
      ..text = '''
Yeni bir iletişim formu mesajı geldi.

Ad Soyad: $name
E-posta: ${email.isEmpty ? '(belirtilmedi)' : email}

Mesaj:
$message
''';

    // Kullanıcı email bıraktıysa, ona direkt yanıt verilebilsin diye
    if (email.isNotEmpty) {
      mailMessage.headers = {
        'Reply-To': email,
      };
    }

    await send(mailMessage, smtpServer);

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': e.toString()},
    );
  }
}