import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../lib/services/similarity_service.dart';
import '../../lib/services/pdf_text_service.dart';
import '../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  try {
    if (context.request.method == HttpMethod.get) {
      final notes = await DbService.notesCollection();
      final data = await notes.find().toList();

      final formattedNotes = data.map((note) {
        return {
          'id': note['_id'].toString(),
          'title': note['title'],
          'description': note['description'],
          'university': note['university'],
          'department': note['department'],
          'grade': note['grade'],
          'semester': note['semester'],
          'courseName': note['courseName'],
          'courseCode': note['courseCode'],
          'noteType': note['noteType'],
          'fileName': note['fileName'],
          'fileUrl': note['fileUrl'],
          'publicId': note['publicId'],
          'createdAt': note['createdAt'],
          'noteText': note['noteText'] ?? '',
        };
      }).toList();

      return Response.json(
        statusCode: 200,
        body: {'notes': formattedNotes},
      );
    }

    if (context.request.method == HttpMethod.post) {
      final body = await context.request.json() as Map<String, dynamic>;

      final title = (body['title'] ?? '').toString().trim();
      final description = (body['description'] ?? '').toString().trim();
      final university = (body['university'] ?? '').toString().trim();
      final department = (body['department'] ?? '').toString().trim();
      final grade = (body['grade'] ?? '').toString().trim();
      final semester = (body['semester'] ?? '').toString().trim();
      final courseName = (body['courseName'] ?? '').toString().trim();
      final courseCode = (body['courseCode'] ?? '').toString().trim();
      final noteType = (body['noteType'] ?? '').toString().trim();
      final fileName = (body['fileName'] ?? '').toString().trim();
      final fileUrl = (body['fileUrl'] ?? '').toString().trim();
      final publicId = (body['publicId'] ?? '').toString().trim();
      final clientNoteText = (body['noteText'] ?? '').toString().trim();

      // Kullanıcı "benzerlik yüksek çıksa da yükle" derse buraya true gelir.
      final forceUpload = body['forceUpload'] == true;

      if (title.isEmpty ||
          description.isEmpty ||
          university.isEmpty ||
          department.isEmpty ||
          grade.isEmpty ||
          semester.isEmpty ||
          courseName.isEmpty ||
          courseCode.isEmpty ||
          noteType.isEmpty ||
          fileName.isEmpty ||
          fileUrl.isEmpty ||
          publicId.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'message': 'Tüm alanları doldur.'},
        );
      }

      // --- PDF içeriğini gerçekten oku ---
      // Sadece .pdf dosyalarda anlamlı; diğer (video vb.) tiplerde boş kalır.
      String extractedText = '';
      if (fileName.toLowerCase().endsWith('.pdf')) {
        extractedText = await PdfTextService.extractTextFromUrl(fileUrl);
      }

      // Öncelik sırası:
      // 1) İstemciden gelen noteText (varsa)
      // 2) Sunucuda PDF'ten çıkarılan gerçek içerik
      // 3) Son çare: metadata (başlık/açıklama/dosya adı/ders bilgisi)
      final newNoteText = clientNoteText.isNotEmpty
          ? clientNoteText
          : extractedText.isNotEmpty
              ? extractedText
              : '$title $description $fileName $courseName $courseCode';

      // Bu metnin gerçek PDF içeriği mi yoksa metadata fallback mi olduğunu
      // ileride debug etmek için işaretleyelim.
      final isContentBased = extractedText.isNotEmpty || clientNoteText.isNotEmpty;

      final notes = await DbService.notesCollection();

      double highestSimilarity = 0;
      Map<String, dynamic>? mostSimilarNote;

      if (!forceUpload) {
        // Aynı bölüm + ders kodundaki mevcut notları çek
        final existingNotes = await notes.find({
          'department': department,
          'courseCode': courseCode,
        }).toList();

        // Corpus: tüm mevcut notların metinleri (IDF için)
        final corpusTexts = existingNotes.map((note) {
          final raw = (note['noteText'] ?? '').toString().trim();
          return raw.isNotEmpty
              ? raw
              : '${note['title'] ?? ''} ${note['description'] ?? ''} '
                  '${note['fileName'] ?? ''} ${note['courseName'] ?? ''} '
                  '${note['courseCode'] ?? ''}';
        }).toList();

        for (int i = 0; i < existingNotes.length; i++) {
          final note = existingNotes[i];
          final oldNoteText = corpusTexts[i];

          final similarity = SimilarityService.calculateSimilarityWithCorpus(
            newNoteText,
            oldNoteText,
            corpusTexts,
          );

          if (similarity > highestSimilarity) {
            highestSimilarity = similarity;
            mostSimilarNote = note;
          }
        }

        // Not: Gerçek PDF içeriği varsa eşik biraz daha güvenle uygulanabilir
        // (çünkü artık metadata tekrarından kaynaklı yanlış pozitif riski düştü).
        // Metadata fallback'teyken daha toleranslı davranıyoruz.
        final threshold = isContentBased ? 0.85 : 0.92;

        if (highestSimilarity >= threshold) {
          return Response.json(
            statusCode: 409,
            body: {
              'message': 'Bu not çok benziyor.',
              'similarity': (highestSimilarity * 100).round(),
              'isTooSimilar': true,
              'similarNoteTitle': mostSimilarNote?['title'],
              // Frontend bu alanı görünce "Yine de yükle" butonu gösterip
              // forceUpload: true ile tekrar istek atabilir.
              'canForceUpload': true,
            },
          );
        }
      }

      final result = await notes.insertOne({
        '_id': ObjectId(),
        'title': title,
        'description': description,
        'university': university,
        'department': department,
        'grade': grade,
        'semester': semester,
        'courseName': courseName,
        'courseCode': courseCode,
        'noteType': noteType,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'publicId': publicId,
        'noteText': newNoteText,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!result.isSuccess) {
        return Response.json(
          statusCode: 500,
          body: {'message': 'Not kaydedilemedi.'},
        );
      }

      return Response.json(
        statusCode: 201,
        body: {
          'message': 'Not başarıyla kaydedildi',
          'similarity': (highestSimilarity * 100).round(),
          'isTooSimilar': false,
          'similarNoteTitle': mostSimilarNote?['title'],
        },
      );
    }

    return Response.json(
      statusCode: 405,
      body: {'message': 'Method not allowed'},
    );
  } catch (e, st) {
    print('NOTES ERROR: $e');
    print(st);

    return Response.json(
      statusCode: 500,
      body: {
        'message': 'Hata oluştu',
        'error': e.toString(),
      },
    );
  }
}