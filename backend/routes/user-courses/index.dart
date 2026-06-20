import 'package:dart_frog/dart_frog.dart';
import '../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  try {
    final users = await DbService.usersCollection();

    if (context.request.method == HttpMethod.get) {
      final email =
          context.request.uri.queryParameters['email']?.trim().toLowerCase() ?? '';

      if (email.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'message': 'Email gerekli.'},
        );
      }

      final user = await users.findOne({'email': email});

      if (user == null) {
        return Response.json(
          statusCode: 404,
          body: {'message': 'Kullanıcı bulunamadı.'},
        );
      }

      return Response.json(
        statusCode: 200,
        body: {
          'selectedCourses': ((user['selectedCourses'] as List?) ?? [])
    .map((item) => Map<String, dynamic>.from(item as Map))
    .toList(),
        },
      );
    }

    if (context.request.method == HttpMethod.post) {
      final body = await context.request.json() as Map<String, dynamic>;

      final email = (body['email'] ?? '').toString().trim().toLowerCase();
      final courseName = (body['courseName'] ?? '').toString().trim();
      final courseCode = (body['courseCode'] ?? '').toString().trim();
      final department = (body['department'] ?? '').toString().trim();

      if (email.isEmpty ||
          courseName.isEmpty ||
          courseCode.isEmpty ||
          department.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'message': 'Tüm alanlar gerekli.'},
        );
      }

      final user = await users.findOne({'email': email});

      if (user == null) {
        return Response.json(
          statusCode: 404,
          body: {'message': 'Kullanıcı bulunamadı.'},
        );
      }
final selectedCourses = ((user['selectedCourses'] as List?) ?? [])
    .map((item) => Map<String, dynamic>.from(item as Map))
    .toList();

      final alreadyExists = selectedCourses.any(
        (course) =>
            course['courseCode'] == courseCode &&
            course['courseName'] == courseName,
      );

      if (!alreadyExists) {
        selectedCourses.add({
          'courseName': courseName,
          'courseCode': courseCode,
          'department': department,
        });

        await users.updateOne(
          {'email': email},
          {
            r'$set': {'selectedCourses': selectedCourses},
          },
        );
      }

      return Response.json(
        statusCode: 200,
        body: {
          'message': 'Ders eklendi',
          'selectedCourses': selectedCourses,
        },
      );
    }

    if (context.request.method == HttpMethod.delete) {
      final body = await context.request.json() as Map<String, dynamic>;

      final email = (body['email'] ?? '').toString().trim().toLowerCase();
      final courseName = (body['courseName'] ?? '').toString().trim();
      final courseCode = (body['courseCode'] ?? '').toString().trim();

      if (email.isEmpty || courseName.isEmpty || courseCode.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'message': 'Email, ders adı ve ders kodu gerekli.'},
        );
      }

      final user = await users.findOne({'email': email});

      if (user == null) {
        return Response.json(
          statusCode: 404,
          body: {'message': 'Kullanıcı bulunamadı.'},
        );
      }

      final selectedCourses = ((user['selectedCourses'] as List?) ?? [])
    .map((item) => Map<String, dynamic>.from(item as Map))
    .toList();

      selectedCourses.removeWhere(
        (course) =>
            course['courseCode'] == courseCode &&
            course['courseName'] == courseName,
      );

      await users.updateOne(
        {'email': email},
        {
          r'$set': {'selectedCourses': selectedCourses},
        },
      );

      return Response.json(
        statusCode: 200,
        body: {
          'message': 'Ders kaldırıldı',
          'selectedCourses': selectedCourses,
        },
      );
    }

    return Response.json(
      statusCode: 405,
      body: {'message': 'Method not allowed'},
    );
  } catch (e, st) {
    print('USER COURSES ERROR: $e');
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