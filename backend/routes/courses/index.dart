import 'package:dart_frog/dart_frog.dart';
import '../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  try {
    final department =
        context.request.uri.queryParameters['department'] ?? '';

    final grade =
        context.request.uri.queryParameters['grade'] ?? '';

    final semester =
        context.request.uri.queryParameters['semester'] ?? '';

    final collection = await DbService.coursesCollection();

    final courses = await collection.find({
      'department': department,
      'grade': grade,
      'semester': semester,
    }).toList();

    return Response.json(
      body: {
        'courses': courses.map((e) {
          return {
            'courseName': e['courseName'],
            'courseCode': e['courseCode'],
          };
        }).toList(),
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'message': e.toString(),
      },
    );
  }
}