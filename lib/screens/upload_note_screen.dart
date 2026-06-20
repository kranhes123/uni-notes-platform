import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_model.dart';
import '../services/cloudinary_service.dart';
import '../services/note_api_service.dart';
import '../widgets/custom_footer.dart';
import '../widgets/custom_header.dart';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/university_service.dart';

class _Palette {
  static const ink = Color(0xFF1A1F36);
  static const muted = Color(0xFF6B7280);
  static const paper = Color(0xFFF7F6F2);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE7E5DE);
  static const indigo = Color(0xFF4F46E5);
  static const violet = Color(0xFF7C3AED);
  static const gold = Color(0xFFD97706);
  static const goldSoft = Color(0xFFFBF0DF);
  static const danger = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
}

/// Backend (MongoDB) "grade" ve "semester" alanlarını birebir string
/// eşleşmesiyle sorguluyor (bkz. /notes/courses endpoint: collection.find({grade, semester})).
/// Bu yüzden state'te tutulan değer HER ZAMAN kanonik (Türkçe) değer olmalı;
/// kullanıcıya gösterilen metin (label) ise dile göre değişebilir.
/// Bu sınıf "value" (backend'e giden, sabit) ile "label" (ekranda görünen,
/// dile göre çevrilen) ayrımını yapar.
class _Option {
  final String value; // kanonik değer — backend'e bu gider, asla değişmez
  final String label; // ekranda görünen metin — dile göre değişir

  const _Option({required this.value, required this.label});
}

class UploadNoteScreen extends StatefulWidget {
  const UploadNoteScreen({super.key});

  @override
  State<UploadNoteScreen> createState() => _UploadNoteScreenState();
}

class _UploadNoteScreenState extends State<UploadNoteScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String university = '';
  String department = '';
  String userGrade = '';
  String language = 'TR';

  bool get isEnglish => language == 'EN';

  String t(String tr, String en) => isEnglish ? en : tr;

  // NOT: Bunlar artık backend'e giden KANONİK (Türkçe) değerler.
  // Ekranda hangi metnin görüneceği `gradeOptions` / `semesterOptions` /
  // `noteTypeOptions` üzerinden ayrıca belirleniyor.
  String? selectedGrade;
  String? selectedSemester;
  String? selectedCourseName;
  String selectedCourseCode = '';
  List<Map<String, dynamic>> courses = [];
  String? selectedNoteType;
  String? selectedFileName;
  Uint8List? selectedFileBytes;

  bool isUploading = false;

  final CloudinaryService cloudinaryService = CloudinaryService(
    cloudName: 'dicwjncco',
    uploadPreset: 'uni_notes_unsigned',
  );

  final NoteApiService noteApiService = NoteApiService(
    baseUrl: 'https://uni-notes-platform-production.up.railway.app',
  );

  // ---------------------------------------------------------------------
  // KANONİK DEĞER + LABEL LİSTELERİ
  // `value` alanı dil değişse de SABİT kalır (Türkçe), bu sayede:
  //  - backend sorguları (grade/semester eşleşmesi) bozulmaz
  //  - dil değiştiğinde seçili dropdown değeri "listede yok" durumuna
  //    düşüp sıfırlanmaz
  // `label` alanı ise t() ile dile göre çevrilir, sadece görünümü etkiler.
  // ---------------------------------------------------------------------

  List<_Option> get gradeOptions => [
        _Option(value: '1. Sınıf', label: t('1. Sınıf', '1st Year')),
        _Option(value: '2. Sınıf', label: t('2. Sınıf', '2nd Year')),
        _Option(value: '3. Sınıf', label: t('3. Sınıf', '3rd Year')),
        _Option(value: '4. Sınıf', label: t('4. Sınıf', '4th Year')),
        _Option(value: '5. Sınıf', label: t('5. Sınıf', '5th Year')),
        _Option(value: '6. Sınıf', label: t('6. Sınıf', '6th Year')),
      ];

  List<_Option> get semesterOptions => [
        _Option(value: 'Güz', label: t('Güz', 'Fall')),
        _Option(value: 'Bahar', label: t('Bahar', 'Spring')),
      ];

  List<_Option> get noteTypeOptions => [
        _Option(value: 'Slayt', label: t('Slayt', 'Slides')),
        _Option(value: 'Çıkmış Sorular', label: t('Çıkmış Sorular', 'Past Exams')),
        _Option(value: 'Video', label: t('Video', 'Video')),
        _Option(value: 'Diğer Notlar', label: t('Diğer Notlar', 'Other Notes')),
      ];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      university = prefs.getString('university') ?? '';
      department = prefs.getString('department') ?? '';
      userGrade = prefs.getString('grade') ?? '';
      language = prefs.getString('language') ?? 'TR';

      // userGrade da kanonik (Türkçe) değer olarak saklanıyor olmalı.
      // gradeOptions artık value bazlı olduğu için dil ne olursa olsun
      // kanonik değerle eşleşip eşleşmediğini kontrol ediyoruz.
      if (gradeOptions.any((option) => option.value == userGrade)) {
        selectedGrade = userGrade;
      }
    });
  }

  Future<void> loadCourses() async {
    if (department.isEmpty ||
        selectedGrade == null ||
        selectedSemester == null) {
      return;
    }

    // selectedGrade / selectedSemester her zaman kanonik (Türkçe) değer
    // olduğu için backend sorgusu dil fark etmeksizin doğru çalışır.
    final result = await UniversityService.getCourses(
      department: department,
      grade: selectedGrade!,
      semester: selectedSemester!,
    );

    setState(() {
      courses = result;
    });
  }

  void onGradeChanged(String? value) {
    setState(() {
      selectedGrade = value;
      selectedSemester = null;
      selectedCourseName = null;
      selectedCourseCode = '';
      courses.clear();
    });
  }

  Future<void> onSemesterChanged(String? value) async {
    setState(() {
      selectedSemester = value;
      selectedCourseName = null;
      selectedCourseCode = '';
      courses.clear();
    });

    await loadCourses();
  }

  void onCourseChanged(String? selectedName) {
    final selectedCourse = courses.firstWhere(
      (course) => course['courseName'] == selectedName,
      orElse: () => {},
    );

    setState(() {
      selectedCourseName = selectedName;
      selectedCourseCode = selectedCourse['courseCode'] ?? '';
    });
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: [
      'pdf', 'doc', 'docx', 'txt', 'pptx',
      'xlsx', 'jpg', 'jpeg', 'png', 'zip', 'mp4',
    ],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.single;

      if (picked.bytes != null) {
        setState(() {
          selectedFileName = picked.name;
          selectedFileBytes = picked.bytes;
        });
      }
    }
  }

  Future<void> uploadNote() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty ||
        selectedGrade == null ||
        selectedSemester == null ||
        selectedCourseName == null ||
        selectedCourseCode.isEmpty ||
        selectedNoteType == null ||
        selectedFileBytes == null ||
        selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Lütfen tüm gerekli alanları doldur ve dosya seç.',
              'Please fill in all required fields and select a file.',
            ),
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        isUploading = true;
      });

      final uploadResult = await cloudinaryService.uploadFile(
        fileBytes: selectedFileBytes!,
        fileName: selectedFileName!,
      );

      final fileUrl = uploadResult['secure_url'];
      final publicId = uploadResult['public_id'];
      final noteText = extractTextFromSelectedFile(
        fileName: selectedFileName!,
        fileBytes: selectedFileBytes!,
      );

      final note = NoteModel(
        title: title,
        description: description,
        university: university,
        department: department,
        grade: selectedGrade!,
        semester: selectedSemester!,
        courseName: selectedCourseName!,
        courseCode: selectedCourseCode,
        noteType: selectedNoteType!,
        fileName: selectedFileName!,
        fileUrl: fileUrl,
        publicId: publicId,
        noteText: noteText,
      );
      final result = await noteApiService.createNote(note);

      final similarity = result['similarity'] ?? 0;
      final message = result['message'] ?? '';
      final isTooSimilar = result['isTooSimilar'] ?? false;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$message\n${t('Benzerlik', 'Similarity')}: %$similarity',
          ),
          backgroundColor: isTooSimilar ? Colors.orange : _Palette.success,
        ),
      );

      setState(() {
        titleController.clear();
        descriptionController.clear();
        selectedSemester = null;
        selectedCourseName = null;
        selectedCourseCode = '';
        selectedNoteType = null;
        selectedFileName = null;
        selectedFileBytes = null;
      });
    } catch (e) {
      final cleanMessage = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleanMessage),
          backgroundColor: _Palette.danger,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Widget _stepBadge(int number) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_Palette.indigo, _Palette.violet]),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _sectionHeader(int number, String title, {String? helper}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepBadge(number),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _Palette.ink,
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    helper,
                    style: const TextStyle(
                        fontSize: 12.5, color: _Palette.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReadOnlyBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final hasValue = value.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _Palette.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _Palette.goldSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: _Palette.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _Palette.muted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  hasValue ? value : '—',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _Palette.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: _Palette.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: _Palette.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Palette.indigo, width: 1.6),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: _Palette.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _Palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _Palette.indigo, width: 1.6),
      ),
    );
  }

  Widget _responsivePair({
    required bool stacked,
    required Widget left,
    required Widget right,
    double spacing = 16,
  }) {
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          SizedBox(height: spacing),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: spacing),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = courses;

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;
    final isTablet = width >= 650 && width < 1000;
    final stacked = isMobile;

    final cardWidth = isMobile ? double.infinity : (isTablet ? 700.0 : 850.0);
    final cardPadding = isMobile ? 20.0 : 32.0;
    final outerHPadding = isMobile ? 16.0 : 32.0;
    final outerVPadding = isMobile ? 24.0 : 40.0;
    final sectionGap = isMobile ? 24.0 : 30.0;

    return Scaffold(
      backgroundColor: _Palette.paper,
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: outerHPadding,
                      vertical: outerVPadding,
                    ),
                    child: Center(
                      child: Container(
                        width: cardWidth,
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          color: _Palette.card,
                          borderRadius:
                              BorderRadius.circular(isMobile ? 18 : 24),
                          border: Border.all(color: _Palette.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(20, 0, 0, 0),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SelectionArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('Not Yükle', 'Upload Note'),
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 30,
                                  fontWeight: FontWeight.w800,
                                  color: _Palette.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t(
                                  'Ders notunu sisteme yükle ve diğer öğrencilerle paylaş.',
                                  'Upload your course note and share it with other students.',
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: _Palette.muted,
                                ),
                              ),
                              SizedBox(height: sectionGap),

                              // Step 1 — basics
                              _sectionHeader(
                                1,
                                t('Temel Bilgiler', 'Basic Information'),
                                helper: t(
                                  'Notun başlığı ve hesap bilgilerin.',
                                  'Note title and your account details.',
                                ),
                              ),
                              buildInput(
                                controller: titleController,
                                label: t('Not Başlığı', 'Note Title'),
                                hint: t(
                                  'Örn: Veri Yapıları Final Özeti',
                                  'E.g.: Data Structures Final Summary',
                                ),
                              ),
                              const SizedBox(height: 14),
                              _responsivePair(
                                stacked: stacked,
                                left: buildReadOnlyBox(
                                  icon: Icons.account_balance_rounded,
                                  label: t('Üniversite', 'University'),
                                  value: university,
                                ),
                                right: buildReadOnlyBox(
                                  icon: Icons.apartment_rounded,
                                  label: t('Bölüm', 'Department'),
                                  value: department,
                                ),
                              ),
                              SizedBox(height: sectionGap),

                              // Step 2 — class / semester / course
                              _sectionHeader(
                                2,
                                t('Sınıf, Dönem ve Ders', 'Year, Semester & Course'),
                                helper: t(
                                  'Notun ait olduğu sınıfı ve dersi seç.',
                                  'Select the year and course this note belongs to.',
                                ),
                              ),
                              _responsivePair(
                                stacked: stacked,
                                left: DropdownButtonFormField<String>(
                                  // value her zaman kanonik (Türkçe) değer
                                  // olduğu için dil değişse bile listede
                                  // bulunamama sorunu yaşanmaz.
                                  value: selectedGrade,
                                  isExpanded: true,
                                  items: gradeOptions.map((option) {
                                    return DropdownMenuItem<String>(
                                      value: option.value,
                                      child: Text(option.label),
                                    );
                                  }).toList(),
                                  onChanged: onGradeChanged,
                                  decoration: _dropdownDecoration(
                                    t('Sınıf', 'Year'),
                                    null,
                                  ),
                                ),
                                right: DropdownButtonFormField<String>(
                                  value: selectedSemester,
                                  isExpanded: true,
                                  items: semesterOptions.map((option) {
                                    return DropdownMenuItem<String>(
                                      value: option.value,
                                      child: Text(option.label),
                                    );
                                  }).toList(),
                                  onChanged: onSemesterChanged,
                                  decoration: _dropdownDecoration(
                                    t('Dönem', 'Semester'),
                                    t('Dönem seç', 'Select semester'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                value: selectedCourseName,
                                isExpanded: true,
                                items: filteredCourses.map((course) {
                                  return DropdownMenuItem<String>(
                                    value: course['courseName'],
                                    child: Text(
                                      course['courseName'].toString(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: filteredCourses.isEmpty
                                    ? null
                                    : onCourseChanged,
                                decoration: _dropdownDecoration(
                                  t('Ders Adı', 'Course Name'),
                                  filteredCourses.isEmpty
                                      ? t(
                                          'Önce sınıf ve dönem seç',
                                          'Select year and semester first',
                                        )
                                      : t('Ders seç', 'Select course'),
                                ),
                              ),
                              const SizedBox(height: 14),
                              buildReadOnlyBox(
                                icon: Icons.tag_rounded,
                                label: t('Ders Kodu', 'Course Code'),
                                value: selectedCourseCode,
                              ),
                              SizedBox(height: sectionGap),

                              // Step 3 — note type
                              _sectionHeader(
                                3,
                                t('Not Türü', 'Note Type'),
                                helper: t(
                                  'Bu içerik hangi kategoriye giriyor?',
                                  'Which category does this content belong to?',
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                value: selectedNoteType,
                                isExpanded: true,
                                items: noteTypeOptions.map((option) {
                                  return DropdownMenuItem<String>(
                                    value: option.value,
                                    child: Text(option.label),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedNoteType = value;
                                  });
                                },
                                decoration: _dropdownDecoration(
                                  t('Not Türü', 'Note Type'),
                                  t('Not türünü seç', 'Select note type'),
                                ),
                              ),
                              SizedBox(height: sectionGap),

                              // Step 4 — description
                              _sectionHeader(
                                4,
                                t('Açıklama', 'Description'),
                                helper: t(
                                  'Diğer öğrencilere notun içeriğini özetle.',
                                  'Briefly describe the content of your note for other students.',
                                ),
                              ),
                              buildInput(
                                controller: descriptionController,
                                label: t('Açıklama', 'Description'),
                                hint: t(
                                  'Not hakkında kısa açıklama yaz...',
                                  'Write a short description about the note...',
                                ),
                                maxLines: 5,
                              ),
                              SizedBox(height: sectionGap),

                              // Step 5 — file
                              _sectionHeader(
                                5,
                                t('Dosya', 'File'),
                                helper: t(
  'PDF, Word, PowerPoint, Excel, görsel veya video yükleyebilirsin.',
  'You can upload PDF, Word, PowerPoint, Excel, image or video files.',
),
                              ),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(isMobile ? 14 : 18),
                                decoration: BoxDecoration(
                                  color: _Palette.paper,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _Palette.border),
                                ),
                                child: isMobile
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: _Palette.goldSoft,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  selectedFileName == null
                                                      ? Icons.upload_file_rounded
                                                      : Icons.description_rounded,
                                                  color: _Palette.gold,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: SelectableText(
                                                  selectedFileName ??
                                                      t(
                                                        'Henüz dosya seçilmedi',
                                                        'No file selected yet',
                                                      ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: _Palette.ink,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: pickFile,
                                              icon: const Icon(Icons.attach_file),
                                              label: Text(
                                                selectedFileName == null
                                                    ? t('Dosya Seç', 'Select File')
                                                    : t('Değiştir', 'Change'),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _Palette.indigo,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: _Palette.goldSoft,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              selectedFileName == null
                                                  ? Icons.upload_file_rounded
                                                  : Icons.description_rounded,
                                              color: _Palette.gold,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: SelectableText(
                                              selectedFileName ??
                                                  t(
                                                    'Henüz dosya seçilmedi',
                                                    'No file selected yet',
                                                  ),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: _Palette.ink,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton.icon(
                                            onPressed: pickFile,
                                            icon: const Icon(Icons.attach_file),
                                            label: Text(
                                              selectedFileName == null
                                                  ? t('Dosya Seç', 'Select File')
                                                  : t('Değiştir', 'Change'),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _Palette.indigo,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 14,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 28),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isUploading ? null : uploadNote,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _Palette.indigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isUploading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          t('Notu Yükle', 'Upload Note'),
                                          style:
                                              const TextStyle(fontSize: 16),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const CustomFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String extractTextFromSelectedFile({
  required String fileName,
  required Uint8List fileBytes,
}) {
  final lowerFileName = fileName.toLowerCase();

  if (lowerFileName.endsWith('.pdf')) {
    return extractTextFromPdf(fileBytes);
  }

  if (lowerFileName.endsWith('.docx')) {
    return extractTextFromDocx(fileBytes);
  }
  if (lowerFileName.endsWith('.pptx')) {
    return extractTextFromPptx(fileBytes);
  }
  if (lowerFileName.endsWith('.xlsx')) {
    return extractTextFromXlsx(fileBytes);
  }
  if (lowerFileName.endsWith('.txt')) {
    return utf8.decode(fileBytes, allowMalformed: true);
  }

  return '';
}

String extractTextFromPdf(Uint8List fileBytes) {
  final document = PdfDocument(inputBytes: fileBytes);
  final text = PdfTextExtractor(document).extractText();
  document.dispose();
  return text;
}

String extractTextFromDocx(Uint8List fileBytes) {
  final archive = ZipDecoder().decodeBytes(fileBytes);

  final documentFile = archive.files.firstWhere(
    (file) => file.name == 'word/document.xml',
  );

  final xmlString = utf8.decode(documentFile.content as List<int>);
  final document = XmlDocument.parse(xmlString);

  return document
      .findAllElements('w:t')
      .map((node) => node.innerText)
      .join(' ');
}


String extractTextFromPptx(Uint8List fileBytes) {
  try {
    final archive = ZipDecoder().decodeBytes(fileBytes);
    final buffer = StringBuffer();

    // PPTX içindeki her slayt XML dosyasını tara
    for (final file in archive.files) {
      if (file.name.startsWith('ppt/slides/slide') &&
          file.name.endsWith('.xml')) {
        final xmlString = utf8.decode(
          file.content as List<int>,
          allowMalformed: true,
        );
        final document = XmlDocument.parse(xmlString);

        // Slayttaki tüm metin elementlerini çek
        final texts = document
            .findAllElements('a:t')
            .map((node) => node.innerText.trim())
            .where((text) => text.isNotEmpty)
            .join(' ');

        buffer.write('$texts ');
      }
    }

    return buffer.toString().trim();
  } catch (e) {
    return '';
  }
}
String extractTextFromXlsx(Uint8List fileBytes) {
  try {
    final archive = ZipDecoder().decodeBytes(fileBytes);
    final buffer = StringBuffer();

    for (final file in archive.files) {
      if (file.name == 'xl/sharedStrings.xml') {
        final xmlString = utf8.decode(
          file.content as List<int>,
          allowMalformed: true,
        );
        final document = XmlDocument.parse(xmlString);
        final texts = document
            .findAllElements('t')
            .map((node) => node.innerText.trim())
            .where((text) => text.isNotEmpty)
            .join(' ');
        buffer.write(texts);
      }
    }
    return buffer.toString().trim();
  } catch (e) {
    return '';
  }
}