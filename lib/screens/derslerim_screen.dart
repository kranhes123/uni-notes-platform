import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_group.dart';
import '../models/note_model.dart';
import '../services/note_api_service.dart';
import '../widgets/custom_footer.dart';
import '../widgets/custom_header.dart';
import 'course_detail_screen.dart';

class DerslerimScreen extends StatefulWidget {
  const DerslerimScreen({super.key});

  @override
  State<DerslerimScreen> createState() => _DerslerimScreenState();
}

class _DerslerimScreenState extends State<DerslerimScreen> {
  late Future<List<NoteModel>> futureNotes;

  final NoteApiService noteApiService = NoteApiService(
    baseUrl: 'https://uni-notes-platform-production.up.railway.app',
  );

  final Set<String> savedCourseKeys = {};
  String userEmail = '';
  String language = 'TR';

  bool get isEnglish => language == 'EN';

  String t(String tr, String en) => isEnglish ? en : tr;

  @override
  void initState() {
    super.initState();
    futureNotes = noteApiService.getNotes();
    loadUserCourses();
  }

  Future<void> loadUserCourses() async {
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
  }

  Future<void> removeCourse(CourseGroup courseGroup) async {
    if (userEmail.isEmpty) return;

    await noteApiService.removeUserCourse(
      email: userEmail,
      courseName: courseGroup.courseName,
      courseCode: courseGroup.courseCode,
    );

    final key = '${courseGroup.courseCode}_${courseGroup.courseName}';

    setState(() {
      savedCourseKeys.remove(key);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(
          t(
            'Ders Derslerim listesinden kaldırıldı.',
            'Course removed from My Courses.',
          ),
        ),
      ),
    );
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
    final isTablet = width >= 650 && width < 1000;
    final horizontalPadding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: FutureBuilder<List<NoteModel>>(
              future: futureNotes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SingleChildScrollView(
                    child: Column(
                      children: const [
                        SizedBox(
                          height: 520,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        CustomFooter(),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 520,
                          child: Center(
                            child: SelectableText('Hata: ${snapshot.error}'),
                          ),
                        ),
                        const CustomFooter(),
                      ],
                    ),
                  );
                }

                final notes = snapshot.data ?? [];
                final allGroups = groupNotesByCourse(notes);

                final myGroups = allGroups.where((group) {
                  final key = '${group.courseCode}_${group.courseName}';
                  return savedCourseKeys.contains(key);
                }).toList();

                final totalNotes = myGroups.fold<int>(
                  0,
                  (sum, group) => sum + group.noteCount,
                );

                final department =
                    myGroups.isNotEmpty ? myGroups.first.department : '-';

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: isMobile ? 28 : 40,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 1240,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  t('Derslerim', 'My Courses'),
                                  style: TextStyle(
                                    fontSize: isMobile ? 28 : 34,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SelectableText(
                                  t(
                                    'Eklediğin dersleri buradan hızlıca açabilirsin.',
                                    'You can quickly access your saved courses here.',
                                  ),
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    height: 1.5,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                if (isMobile)
                                  Column(
                                    children: [
                                      _SummaryCard(
                                        icon: Icons.bookmark_added_rounded,
                                        value: '${myGroups.length}',
                                        label: t(
                                          'Kayıtlı Ders',
                                          'Saved Courses',
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      _SummaryCard(
                                        icon: Icons.folder_copy_rounded,
                                        value: '$totalNotes',
                                        label: t(
                                          'Toplam Not',
                                          'Total Notes',
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      _SummaryCard(
                                        icon: Icons.school_rounded,
                                        value: department,
                                        label: t('Bölüm', 'Department'),
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _SummaryCard(
                                          icon: Icons.bookmark_added_rounded,
                                          value: '${myGroups.length}',
                                          label: t(
                                            'Kayıtlı Ders',
                                            'Saved Courses',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: _SummaryCard(
                                          icon: Icons.folder_copy_rounded,
                                          value: '$totalNotes',
                                          label: t(
                                            'Toplam Not',
                                            'Total Notes',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: _SummaryCard(
                                          icon: Icons.school_rounded,
                                          value: department,
                                          label: t('Bölüm', 'Department'),
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 30),

                                if (myGroups.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    constraints:
                                        const BoxConstraints(minHeight: 320),
                                    padding: EdgeInsets.symmetric(
                                      vertical: isMobile ? 42 : 56,
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Center(
                                      child: Text(
                                        t(
                                          'Henüz Derslerim listesine ders eklemedin.',
                                          'You have not added any courses yet.',
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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: myGroups.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: getCrossAxisCount(width),
                                      crossAxisSpacing: 18,
                                      mainAxisSpacing: 18,
                                      childAspectRatio:
                                          getChildAspectRatio(width),
                                    ),
                                    itemBuilder: (context, index) {
                                      final courseGroup = myGroups[index];

                                      return _MyCourseCard(
                                        courseGroup: courseGroup,
                                        color: getCardColor(index),
                                        onRemove: () =>
                                            removeCourse(courseGroup),
                                        isEnglish: isEnglish,
                                        isMobile: isMobile,
                                        isTablet: isTablet,
                                      );
                                    },
                                  ),

                                const SizedBox(height: 70),
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
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;

    return Container(
      width: double.infinity,
      height: isMobile ? 102 : 118,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(14, 0, 0, 0),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 46 : 52,
            height: isMobile ? 46 : 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.indigo,
              size: isMobile ? 24 : 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SelectableText(
                  value,
                  maxLines: 1,
                  
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyCourseCard extends StatelessWidget {
  final CourseGroup courseGroup;
  final Color color;
  final VoidCallback onRemove;
  final bool isEnglish;
  final bool isMobile;
  final bool isTablet;

  const _MyCourseCard({
    required this.courseGroup,
    required this.color,
    required this.onRemove,
    required this.isEnglish,
    required this.isMobile,
    required this.isTablet,
  });

  String t(String tr, String en) => isEnglish ? en : tr;

  @override
  Widget build(BuildContext context) {
    void openCourse() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(
            courseGroup: courseGroup,
          ),
        ),
      );
    }

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
            height: isMobile ? 100 : 110,
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
                Row(
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
                      child: SelectableText(
                        courseGroup.courseCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: t('Listeden kaldır', 'Remove from list'),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onRemove,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
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
              padding: EdgeInsets.fromLTRB(
                18,
                isMobile ? 14 : 16,
                18,
                isMobile ? 12 : 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    courseGroup.courseName,
                    maxLines: 2,
                    
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: isMobile ? 10 : 12),
                  SelectableText(
                    t(
                      'Bu derse ait yüklenmiş notları inceleyin.',
                      'View uploaded notes for this course.',
                    ),
                    maxLines: 2,
                    
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      height: 1.45,
                      color: const Color(0xFF6B7280),
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
                          child: SelectableText(
                            isEnglish
                                ? '${courseGroup.noteCount} Notes'
                                : '${courseGroup.noteCount} Not',
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
                  SelectableText(
                    courseGroup.department,
                    maxLines: 1,
                    
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: openCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 13 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        t('Dersi İncele', 'View Course'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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