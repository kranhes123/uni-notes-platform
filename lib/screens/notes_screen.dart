import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_group.dart';
import '../models/note_model.dart';
import '../services/note_api_service.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_footer.dart';
import 'course_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late Future<List<NoteModel>> futureNotes;

  final NoteApiService noteApiService = NoteApiService(
    baseUrl: 'http://localhost:8080',
  );

  String selectedDepartment = 'Tümü';
  String selectedGrade = 'Tümü';
  String selectedSemester = 'Tümü';
  String searchQuery = '';
  String userEmail = '';
  String language = 'TR';

  int currentPage = 1;
  static const int itemsPerPage = 8;

  String _toTurkishLowerCase(String text) {
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ö', 'ö')
        .toLowerCase();
  }

  final Set<String> savedCourseKeys = {};

  bool get isEnglish => language == 'EN';

  String t(String tr, String en) => isEnglish ? en : tr;

  @override
  void initState() {
    super.initState();
    futureNotes = noteApiService.getNotes();
    loadSavedCourses();
  }

  Future<void> loadSavedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final email = (prefs.getString('email') ?? '').trim().toLowerCase();
    final selectedLanguage = prefs.getString('language') ?? 'TR';

    if (email.isEmpty) {
      setState(() {
        userEmail = '';
        language = selectedLanguage;
        savedCourseKeys.clear();
      });
      return;
    }

    try {
      final courses = await noteApiService.getUserCourses(email);

      setState(() {
        userEmail = email;
        language = selectedLanguage;
        savedCourseKeys
          ..clear()
          ..addAll(
            courses.map(
              (course) => '${course['courseCode']}_${course['courseName']}',
            ),
          );
      });
    } catch (e) {
      setState(() {
        userEmail = email;
        language = selectedLanguage;
        savedCourseKeys.clear();
      });
    }
  }

  Future<void> saveCourse(CourseGroup courseGroup) async {
    if (userEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('Önce giriş yapmalısın.', 'You need to log in first.')),
        ),
      );
      return;
    }

    final key = '${courseGroup.courseCode}_${courseGroup.courseName}';

    if (savedCourseKeys.contains(key)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText(
            t(
              'Bu ders zaten Derslerim listesinde var.',
              'This course is already in My Courses.',
            ),
          ),
        ),
      );
      return;
    }

    try {
      await noteApiService.addUserCourse(
        email: userEmail,
        courseName: courseGroup.courseName,
        courseCode: courseGroup.courseCode,
        department: courseGroup.department,
      );

      setState(() {
        savedCourseKeys.add(key);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText(
            t(
              'Ders Derslerim listesine eklendi.',
              'Course added to My Courses.',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText(
            isEnglish ? 'Course could not be added: $e' : 'Ders eklenemedi: $e',
          ),
        ),
      );
    }
  }

  List<String> getDepartments(List<NoteModel> notes) {
    final values = notes.map((e) => e.department).toSet().toList()..sort();
    return ['Tümü', ...values];
  }

  List<String> getGrades(List<NoteModel> notes) {
    final values = notes.map((e) => e.grade).toSet().toList()..sort();
    return ['Tümü', ...values];
  }

  List<String> getSemesters(List<NoteModel> notes) {
    final values = notes.map((e) => e.semester).toSet().toList()..sort();
    return ['Tümü', ...values];
  }

  List<CourseGroup> applyFiltersAndGroup(List<NoteModel> notes) {
    final courseGroups = groupNotesByCourse(notes);

    return courseGroups.where((group) {
      final matchesDepartment = selectedDepartment == 'Tümü' || group.department == selectedDepartment;
      final matchesGrade = selectedGrade == 'Tümü' || group.notes.any((n) => n.grade == selectedGrade);
      final matchesSemester = selectedSemester == 'Tümü' || group.notes.any((n) => n.semester == selectedSemester);

      final query = _toTurkishLowerCase(searchQuery.trim());
      final courseNameLower = _toTurkishLowerCase(group.courseName);
      final courseCodeLower = _toTurkishLowerCase(group.courseCode);

      final matchesSearch = query.isEmpty ||
          courseNameLower.contains(query) ||
          courseCodeLower.contains(query) ||
          group.notes.any((n) => _toTurkishLowerCase(n.title).contains(query));

      return matchesDepartment && matchesGrade && matchesSemester && matchesSearch;
    }).toList();
  }

  Color getCardColor(int index) {
    final colors = [
      const Color(0xFF4F46E5),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFF06B6D4),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6),
      const Color(0xFF22C55E),
    ];

    return colors[index % colors.length];
  }

  List<CourseGroup> groupNotesByCourse(List<NoteModel> notes) {
    final Map<String, List<NoteModel>> grouped = {};

    for (final note in notes) {
      final key = '${note.courseCode}_${note.courseName}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(note);
    }

    final groups = grouped.entries.map((entry) {
      final groupNotes = entry.value;
      groupNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final first = groupNotes.first;

      return CourseGroup(
        courseName: first.courseName,
        courseCode: first.courseCode,
        department: first.department,
        university: first.university,
        notes: groupNotes,
      );
    }).toList();

    groups.sort(
      (a, b) => b.latestNote.createdAt.compareTo(a.latestNote.createdAt),
    );

    return groups;
  }

  int getCrossAxisCount(double width) {
    if (width < 650) return 1;
    if (width < 1000) return 2;
    if (width < 1250) return 3;
    return 4;
  }

  double getChildAspectRatio(double width) {
    if (width < 650) return 0.92;
    if (width < 1000) return 0.78;
    return 0.70;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;
    final horizontalPadding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      // SelectionArea sayesinde sayfadaki tüm metinler (başlıklar, kart
      // içerikleri, açıklamalar vb.) seçilebilir/kopyalanabilir olur.
      // SnackBar içerikleri zaten ayrı bir overlay olduğundan bundan
      // etkilenmez; onlarda halihazırda SelectableText kullanılıyor.
      body: SelectionArea(
        child: Column(
          children: [
            const CustomHeader(),
            Expanded(
              child: FutureBuilder<List<NoteModel>>(
                future: futureNotes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SelectableText(
                          isEnglish
                              ? 'Error: ${snapshot.error}'
                              : 'Hata: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final notes = snapshot.data ?? [];

                  if (notes.isEmpty) {
                    return Center(
                      child: SelectableText(
                        t('Henüz not eklenmemiş', 'No notes have been added yet'),
                      ),
                    );
                  }

                  final courseGroups = applyFiltersAndGroup(notes);
                  final totalPages = (courseGroups.length / itemsPerPage).ceil();
                  final safePage = currentPage.clamp(1, totalPages == 0 ? 1 : totalPages);
                  final paginatedGroups = courseGroups
                      .skip((safePage - 1) * itemsPerPage)
                      .take(itemsPerPage)
                      .toList();

                  final departments = getDepartments(notes);
                  final grades = getGrades(notes);
                  final semesters = getSemesters(notes);

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: isMobile ? 28 : 40,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1240),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t('Ders Notları', 'Lecture Notes'),
                                    style: TextStyle(
                                      fontSize: isMobile ? 28 : 34,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    t(
                                      'Bölümlere, popülerliğe ve son eklenenlere göre notları keşfet.',
                                      'Explore notes by departments, courses and recently uploaded materials.',
                                    ),
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      height: 1.5,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Filtre kutusu
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(isMobile ? 16 : 18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color.fromARGB(12, 0, 0, 0),
                                          blurRadius: 14,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Wrap(
                                      spacing: 14,
                                      runSpacing: 14,
                                      children: [
                                        _FilterDropdown(
                                          width: isMobile ? double.infinity : 250,
                                          label: t('Bölüm', 'Department'),
                                          value: selectedDepartment,
                                          items: departments,
                                          isEnglish: isEnglish,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedDepartment = value ?? 'Tümü';
                                              currentPage = 1;
                                            });
                                          },
                                        ),
                                        _FilterDropdown(
                                          width: isMobile ? double.infinity : 250,
                                          label: t('Sınıf', 'Grade'),
                                          value: selectedGrade,
                                          items: grades,
                                          isEnglish: isEnglish,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedGrade = value ?? 'Tümü';
                                              currentPage = 1;
                                            });
                                          },
                                        ),
                                        _FilterDropdown(
                                          width: isMobile ? double.infinity : 250,
                                          label: t('Dönem', 'Semester'),
                                          value: selectedSemester,
                                          items: semesters,
                                          isEnglish: isEnglish,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedSemester = value ?? 'Tümü';
                                              currentPage = 1;
                                            });
                                          },
                                        ),
                                        SizedBox(
                                          width: isMobile ? double.infinity : 280,
                                          child: TextField(
                                            onChanged: (value) {
                                              setState(() {
                                                searchQuery = value;
                                                currentPage = 1;
                                              });
                                            },
                                            decoration: InputDecoration(
                                              labelText: t(
                                                'Ders veya not ara',
                                                'Search course or note',
                                              ),
                                              hintText: t(
                                                'Örn: BZ410, İşletim...',
                                                'Ex: BZ410, Operating...',
                                              ),
                                              prefixIcon: const Icon(Icons.search),
                                              filled: true,
                                              fillColor: const Color(0xFFF8FAFC),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 14,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE5E7EB),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE5E7EB),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: isMobile ? double.infinity : null,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                selectedDepartment = 'Tümü';
                                                selectedGrade = 'Tümü';
                                                selectedSemester = 'Tümü';
                                                searchQuery = '';
                                                currentPage = 1;
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.refresh_rounded,
                                              size: 18,
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Color(0xFFD1D5DB),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 18,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(0xFF374151),
                                            ),
                                            label: Text(
                                              t(
                                                'Filtreleri Temizle',
                                                'Clear Filters',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),
                                  Row(
                                    children: [
                                      Text(
                                        t('Tüm Notlar', 'All Notes'),
                                        style: TextStyle(
                                          fontSize: isMobile ? 21 : 22,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (courseGroups.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${courseGroups.length} ${t('ders', 'courses')}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  if (courseGroups.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      constraints: const BoxConstraints(minHeight: 320),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 48,
                                        horizontal: 24,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromARGB(14, 0, 0, 0),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          t(
                                            'Filtreye uygun ders bulunamadı.',
                                            'No courses found for the selected filters.',
                                          ),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: paginatedGroups.length,
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: getCrossAxisCount(width),
                                        crossAxisSpacing: 18,
                                        mainAxisSpacing: 18,
                                        childAspectRatio: getChildAspectRatio(width),
                                      ),
                                      itemBuilder: (context, index) {
                                        final courseGroup = paginatedGroups[index];
                                        final courseKey = '${courseGroup.courseCode}_${courseGroup.courseName}';
                                        // Gerçek global index rengi için
                                        final globalIndex = (safePage - 1) * itemsPerPage + index;

                                        return _CourseCard(
                                          courseGroup: courseGroup,
                                          color: getCardColor(globalIndex),
                                          isSaved: savedCourseKeys.contains(courseKey),
                                          onAddToMyCourses: () {
                                            saveCourse(courseGroup);
                                          },
                                          isEnglish: isEnglish,
                                        );
                                      },
                                    ),

                                  // Pagination
                                  if (totalPages > 1) ...[
                                    const SizedBox(height: 40),
                                    _PaginationBar(
                                      currentPage: safePage,
                                      totalPages: totalPages,
                                      isEnglish: isEnglish,
                                      onPageChanged: (page) {
                                        setState(() {
                                          currentPage = page;
                                        });
                                      },
                                    ),
                                  ],

                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const CustomFooter(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Dropdown ───────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool isEnglish;

  const _FilterDropdown({
    required this.width,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isEnglish,
  });

  String displayValue(String item) {
    if (!isEnglish) return item;
    return item == 'Tümü' ? 'All' : item;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  displayValue(item),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Course Card ──────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final CourseGroup courseGroup;
  final Color color;
  final bool isSaved;
  final VoidCallback onAddToMyCourses;
  final bool isEnglish;

  const _CourseCard({
    required this.courseGroup,
    required this.color,
    required this.isSaved,
    required this.onAddToMyCourses,
    required this.isEnglish,
  });

  String t(String tr, String en) => isEnglish ? en : tr;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(18, 0, 0, 0),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 105,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    courseGroup.courseCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseGroup.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t(
                      'Bu derse ait yüklenmiş notları inceleyin.',
                      'View uploaded notes for this course.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder_copy_outlined,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isEnglish
                                ? '${courseGroup.notes.length} files uploaded'
                                : '${courseGroup.notes.length} dosya yüklendi',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    courseGroup.department,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isSaved ? null : onAddToMyCourses,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isSaved
                            ? t('Derslerimde', 'Saved')
                            : t('Derslerime Ekle', 'Add to My Courses'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDetailScreen(
                              courseGroup: courseGroup,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(t('Dersi İncele', 'View Course')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pagination Bar ───────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isEnglish;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.isEnglish,
    required this.onPageChanged,
  });

  List<int> _visiblePages() {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = (currentPage - 2).clamp(1, totalPages - 4);
    int end = (start + 4).clamp(5, totalPages);
    start = (end - 4).clamp(1, totalPages);
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final pages = _visiblePages();
    final showStartEllipsis = pages.first > 2;
    final showEndEllipsis = pages.last < totalPages - 1;
    final showFirst = pages.first > 1;
    final showLast = pages.last < totalPages;

    return Center(
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Önceki sayfa butonu
          _NavButton(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),

          // İlk sayfa
          if (showFirst) ...[
            _PageButton(
              page: 1,
              isSelected: currentPage == 1,
              onTap: () => onPageChanged(1),
            ),
            if (showStartEllipsis) _Ellipsis(),
          ],

          // Orta sayfalar
          for (final page in pages)
            _PageButton(
              page: page,
              isSelected: page == currentPage,
              onTap: () => onPageChanged(page),
            ),

          // Son sayfa
          if (showLast) ...[
            if (showEndEllipsis) _Ellipsis(),
            _PageButton(
              page: totalPages,
              isSelected: currentPage == totalPages,
              onTap: () => onPageChanged(totalPages),
            ),
          ],

          // Sonraki sayfa butonu
          _NavButton(
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _Ellipsis extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 32,
      height: 40,
      child: Center(
        child: Text(
          '···',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFF3F4F6),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? const Color(0xFF374151)
                : const Color(0xFFD1D5DB),
          ),
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final int page;
  final bool isSelected;
  final VoidCallback onTap;

  const _PageButton({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Center(
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      ),
    );
  }
}