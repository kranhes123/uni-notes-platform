import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

// ── AYARLAR ──────────────────────────────────────────────────────────────
// UYARI: Bu key'i public bir GitHub reposuna push etmiyorsan sorun yok.
// Public repo kullanıyorsan Resend dashboard'dan key'i hemen rotate et
// ve Railway > Variables üzerinden ortam değişkeni olarak taşı.
const String _resendApiKey = 're_HXe85va2_JjQdrUVK1HSsDSbWSc15ApXW';

// Mailin gideceği adres (kendi mailin)
const String _receiverEmail = 'duzyol975337@gmail.com';

// Resend test modunda domain doğrulaman yoksa SADECE bu adresten gönderebilirsin.
const String _senderAddress = 'Uni Notes <onboarding@resend.com>';
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

    final textBody = '''
Yeni bir iletişim formu mesajı geldi.

Ad Soyad: $name
E-posta: ${email.isEmpty ? '(belirtilmedi)' : email}

Mesaj:
$message
''';

    final response = await http
        .post(
          Uri.parse('https://api.resend.com/emails'),
          headers: {
            'Authorization': 'Bearer $_resendApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'from': _senderAddress,
            'to': [_receiverEmail],
            'subject': 'Uni Notes - Yeni İletişim Mesajı: $name',
            'text': textBody,
            // Kullanıcı email bıraktıysa direkt yanıt verebilmek için
            if (email.isNotEmpty) 'reply_to': email,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Response.json(body: {'success': true});
    }

    print('RESEND_ERROR: status=${response.statusCode} body=${response.body}');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Mail gönderilemedi'},
    );
  } catch (e) {
    print('CONTACT_EXCEPTION: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': e.toString()},
    );
  }
}