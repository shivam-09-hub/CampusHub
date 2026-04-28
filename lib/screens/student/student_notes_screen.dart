import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../core/services/supabase_notes_service.dart';
import '../../models/note_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common_widgets.dart';

class StudentNotesScreen extends StatefulWidget {
  final UserModel user;
  const StudentNotesScreen({super.key, required this.user});

  @override
  State<StudentNotesScreen> createState() => _StudentNotesScreenState();
}

class _StudentNotesScreenState extends State<StudentNotesScreen> {
  final _notesService = SupabaseNotesService();
  late Future<List<NoteModel>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _notesFuture = _notesService.fetchNotes();
  }

  Future<void> _refreshNotes() async {
    setState(() {
      _notesFuture = _notesService.fetchNotes();
    });
    await _notesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes & Materials')),
      body: FutureBuilder<List<NoteModel>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Supabase notes fetch failed: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48,
                      color: AppTheme.error.withOpacity(0.7)),
                  const SizedBox(height: 12),
                  Text('Failed to load notes',
                      style: TextStyle(color: AppTheme.textColor(context))),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refreshNotes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final allNotes = snapshot.data ?? [];
          final notes = allNotes.where(_matchesStudent).toList();

          debugPrint('StudentNotes: total=${allNotes.length}, filtered=${notes.length}');
          debugPrint('StudentNotes: user dept="${widget.user.department}", semester="${widget.user.semester}"');
          for (final n in allNotes) {
            debugPrint('  Note: "${n.title}" dept="${n.department}" class="${n.className}" match=${_matchesStudent(n)}');
          }

          if (notes.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshNotes,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyStateWidget(
                    icon: Icons.note_alt_outlined,
                    title: 'No Notes',
                    subtitle: 'No study materials available for your class.\nPull down to refresh.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshNotes,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (_, i) => _buildNoteCard(notes[i]),
            ),
          );
        },
      ),
    );
  }

  /// Matches notes to student based on department and class/semester.
  /// Uses case-insensitive, trimmed comparison. Also checks if the
  /// note's class name is contained within the user's semester or vice-versa
  /// to handle mismatches like "Sem 1" vs "Semester 1".
  bool _matchesStudent(NoteModel note) {
    final noteDept = note.department.trim().toLowerCase();
    final noteClass = note.className.trim().toLowerCase();
    final userDept = widget.user.department.trim().toLowerCase();
    final userSem = widget.user.semester.trim().toLowerCase();

    // If note has no department filter, it's for everyone
    final matchesDept = noteDept.isEmpty || noteDept == userDept;

    // If note has no class filter, it's for all classes
    // Also do a contains check for partial matches (e.g. "Sem 1" vs "Semester 1")
    final matchesClass = noteClass.isEmpty ||
        noteClass == userSem ||
        noteClass.contains(userSem) ||
        userSem.contains(noteClass);

    return matchesDept && matchesClass;
  }

  Widget _buildNoteCard(NoteModel note) {
    final date = DateFormat('MMM d, yyyy').format(note.createdAt);
    final fileIcon = switch (note.fileType) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'image' => Icons.image_rounded,
      'doc' => Icons.description_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
    final fileColor = switch (note.fileType) {
      'pdf' => Colors.red,
      'image' => Colors.blue,
      'doc' => AppTheme.primary,
      _ => Colors.grey,
    };

    return ThemedListCard(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: fileColor.withOpacity(AppTheme.isDark(context) ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(fileIcon, color: fileColor, size: 24),
        ),
        title: Text(
          note.title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textColor(context)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${note.fileTypeLabel} - ${note.department.isEmpty ? 'General' : note.department} - ${note.className.isEmpty ? 'All classes' : note.className}',
              style: TextStyle(fontSize: 13, color: AppTheme.subtitleColor(context)),
            ),
            if (note.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                note.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppTheme.subtitleColor(context)),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(fontSize: 11, color: AppTheme.subtitleColor(context)),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_rounded, color: AppTheme.primary),
          onPressed: () => _notesService.openNote(note),
        ),
      ),
    );
  }
}
