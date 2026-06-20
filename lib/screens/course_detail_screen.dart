import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_group.dart';
import '../models/note_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CourseDetailScreen extends StatelessWidget {
  final CourseGroup courseGroup;

  const CourseDetailScreen({
    super.key,
    required this.courseGroup,
  });

  @override
  Widget build(BuildContext context) {
    final sortedNotes = [...courseGroup.notes]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final slideNotes =
        sortedNotes.where((note) => note.noteType == 'Slayt').toList();

    final pastExamNotes = sortedNotes
        .where((note) => note.noteType == 'Çıkmış Sorular')
        .toList();

    final videoNotes =
        sortedNotes.where((note) => note.noteType == 'Video').toList();

    final otherNotes =
        sortedNotes.where((note) => note.noteType == 'Diğer Notlar').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        title: Text(courseGroup.courseName),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                courseGroup.courseName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${courseGroup.courseCode} • ${courseGroup.department} • ${courseGroup.noteCount} dosya',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _NoteSection(
                      title: 'Slaytlar',
                      notes: slideNotes,
                    ),
                    const SizedBox(height: 24),
                    _NoteSection(
                      title: 'Çıkmış Sorular',
                      notes: pastExamNotes,
                    ),
                    const SizedBox(height: 24),
                    _NoteSection(
                      title: 'Videolar',
                      notes: videoNotes,
                    ),
                    const SizedBox(height: 24),
                    _NoteSection(
                      title: 'Diğer Notlar',
                      notes: otherNotes,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bölüm başlığı (Slaytlar, Videolar vb.) - tıklanınca tüm bölüm açılıp kapanır.
class _NoteSection extends StatefulWidget {
  final String title;
  final List<NoteModel> notes;

  const _NoteSection({
    required this.title,
    required this.notes,
  });

  @override
  State<_NoteSection> createState() => _NoteSectionState();
}

class _NoteSectionState extends State<_NoteSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  '${widget.title} (${widget.notes.length})',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: !_expanded
              ? const SizedBox.shrink()
              : widget.notes.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Text(
                        'Bu kategoride henüz not yok.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  : Column(
                      children: widget.notes
                          .map(
                            (note) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _UploadedNoteCard(note: note),
                            ),
                          )
                          .toList(),
                    ),
        ),
      ],
    );
  }
}

/// Tek bir not kartı - varsayılan kapalı, üstüne tıklayınca açılır.
class _UploadedNoteCard extends StatefulWidget {
  final NoteModel note;

  const _UploadedNoteCard({required this.note});

  @override
  State<_UploadedNoteCard> createState() => _UploadedNoteCardState();
}

class _UploadedNoteCardState extends State<_UploadedNoteCard> {
  bool _expanded = false;

  Future<void> openFile(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dosya açılamadı.'),
        ),
      );
    }
  }

  String formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';

    try {
      final date = DateTime.parse(rawDate).toLocal();
      return '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}  '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(18, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tıklanabilir başlık satırı - her zaman görünür.
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(note.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Açılınca gelen detaylar.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 14),
                        if (note.description.isNotEmpty) ...[
                          Text(
                            note.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _InfoChip(label: note.noteType),
                            _InfoChip(label: note.courseCode),
                            _InfoChip(label: note.grade),
                            _InfoChip(label: note.semester),
                            _InfoChip(label: note.fileName),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              await openFile(context, note.fileUrl);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Dosyayı Gör'),
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

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF374151),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}