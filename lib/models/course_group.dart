import 'note_model.dart';

class CourseGroup {
  final String courseName;
  final String courseCode;
  final String department;
  final String university;
  final List<NoteModel> notes;

  CourseGroup({
    required this.courseName,
    required this.courseCode,
    required this.department,
    required this.university,
    required this.notes,
  });

  NoteModel get latestNote => notes.first;

  int get noteCount => notes.length;
}