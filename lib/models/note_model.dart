class NoteModel {
  final String id;
  final String title;
  final String description;
  final String university;
  final String department;
  final String grade;
  final String semester;
  final String courseName;
  final String courseCode;
  final String noteType;
  final String fileName;
  final String fileUrl;
  final String publicId;
  final String createdAt;
  final String noteText;

  NoteModel({
    this.id = '',
    required this.title,
    required this.description,
    required this.university,
    required this.department,
    required this.grade,
    required this.semester,
    required this.courseName,
    required this.courseCode,
    required this.noteType,
    required this.fileName,
    required this.fileUrl,
    required this.publicId,
    this.createdAt = '',
    this.noteText = '',
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      university: json['university']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? '',
      noteType: json['noteType']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      publicId: json['publicId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      noteText: json['noteText']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'noteText': noteText,
    };
  }
}