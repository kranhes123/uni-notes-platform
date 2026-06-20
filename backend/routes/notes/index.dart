import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../../lib/services/similarity_service.dart';
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
      final noteText = (body['noteText'] ?? '').toString().trim();

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

      final notes = await DbService.notesCollection();

      final newNoteText = noteText.isNotEmpty
          ? noteText
          : '$title $description $fileName $courseName $courseCode';

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

      double highestSimilarity = 0;
      Map<String, dynamic>? mostSimilarNote;

      for (int i = 0; i < existingNotes.length; i++) {
        final note = existingNotes[i];
        final oldNoteText = corpusTexts[i];

        // Corpus'u kullanan gelişmiş versiyon
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

      if (highestSimilarity >= 0.80) {
        return Response.json(
          statusCode: 409,
          body: {
            'message': 'Bu not çok benziyor, kaydedilmedi.',
            'similarity': (highestSimilarity * 100).round(),
            'isTooSimilar': true,
            'similarNoteTitle': mostSimilarNote?['title'],
          },
        );
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