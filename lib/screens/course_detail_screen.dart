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

class _NoteSection extends StatelessWidget {
  final String title;
  final List<NoteModel> notes;

  const _NoteSection({
    required this.title,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${notes.length})',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 14),
        if (notes.isEmpty)
          Container(
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
        else
          Column(
            children: notes
                .map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _UploadedNoteCard(note: note),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _UploadedNoteCard extends StatelessWidget {
  final NoteModel note;

  const _UploadedNoteCard({required this.note});

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Text(
            note.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            note.description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDate(note.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ),
              ElevatedButton(
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
            ],
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