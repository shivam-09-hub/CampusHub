import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../core/services/supabase_notes_service.dart';
import '../../models/note_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common_widgets.dart';

class ManageNotesScreen extends StatefulWidget {
  final UserModel user;
  const ManageNotesScreen({super.key, required this.user});

  @override
  State<ManageNotesScreen> createState() => _ManageNotesScreenState();
}

class _ManageNotesScreenState extends State<ManageNotesScreen> {
  final _notesService = SupabaseNotesService();
  late Future<List<NoteModel>> _notesFuture;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _notesFuture = _notesService.fetchNotes();
  }

  void _refreshNotes() {
    setState(() {
      _notesFuture = _notesService.fetchNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      title: 'Manage Notes',
      subtitle: 'Upload study materials, PDFs, images, and documents.',
      icon: Icons.note_alt_rounded,
      body: LoadingOverlay(
        isLoading: _uploading,
        message: 'Uploading file...',
        child: FutureBuilder<List<NoteModel>>(
          future: _notesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              debugPrint('Supabase notes fetch failed: ${snapshot.error}');
            }

            final notes = snapshot.data ?? [];
            if (notes.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.note_alt_outlined,
                title: 'No Notes Uploaded',
                subtitle:
                    'Upload study materials, PDFs, and images for students.',
                actionLabel: 'Upload Note',
                onAction: _showUploadDialog,
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _refreshNotes(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                itemBuilder: (_, i) => _buildNoteCard(notes[i]),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
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
            color: fileColor.withValues(
                alpha: AppTheme.isDark(context) ? 0.2 : 0.1),
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
              style: TextStyle(
                  fontSize: 13, color: AppTheme.subtitleColor(context)),
            ),
            if (note.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                note.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, color: AppTheme.subtitleColor(context)),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              note.fileName,
              style: const TextStyle(fontSize: 12, color: AppTheme.primary),
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: TextStyle(
                  fontSize: 11, color: AppTheme.subtitleColor(context)),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, color: AppTheme.primary),
              onPressed: () => _notesService.openNote(note),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              onPressed: () => _confirmDelete(note),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    String? selectedFilePath;
    String? selectedFileName;
    String fileType = 'pdf';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text(
            'Upload Note',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g. DBMS Unit 1 Notes',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: deptCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          hintText: 'e.g. BCA',
                          prefixIcon: Icon(Icons.domain),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: classCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Class Name',
                          hintText: 'e.g. Sem 1',
                          prefixIcon: Icon(Icons.layers_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: [
                        'pdf',
                        'jpg',
                        'jpeg',
                        'png',
                        'doc',
                        'docx',
                        'ppt',
                        'pptx',
                      ],
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setDlg(() {
                        selectedFilePath = result.files.single.path;
                        selectedFileName = result.files.single.name;
                        final ext =
                            result.files.single.extension?.toLowerCase() ?? '';
                        if (ext == 'pdf') {
                          fileType = 'pdf';
                        } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
                          fileType = 'image';
                        } else {
                          fileType = 'doc';
                        }
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selectedFileName != null
                            ? AppTheme.success
                            : AppTheme.borderColor(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          selectedFileName != null
                              ? Icons.check_circle
                              : Icons.cloud_upload_outlined,
                          color: selectedFileName != null
                              ? AppTheme.success
                              : AppTheme.subtitleColor(context),
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedFileName ?? 'Tap to select a file',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selectedFileName != null
                                ? AppTheme.textColor(context)
                                : AppTheme.subtitleColor(context),
                            fontWeight: selectedFileName != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedFilePath == null || selectedFileName == null) {
                  showAppSnackBar(context, 'Please select a file first',
                      isError: true);
                  return;
                }
                if (titleCtrl.text.trim().isEmpty) {
                  showAppSnackBar(context, 'Please fill all required fields',
                      isError: true);
                  return;
                }
                Navigator.pop(ctx);
                await _uploadFile(
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  className: classCtrl.text.trim(),
                  filePath: selectedFilePath!,
                  fileName: selectedFileName!,
                  fileType: fileType,
                );
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile({
    required String title,
    required String description,
    required String department,
    required String className,
    required String filePath,
    required String fileName,
    required String fileType,
  }) async {
    setState(() => _uploading = true);
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        showAppSnackBar(context, 'Please select a file first', isError: true);
        return;
      }

      await _notesService.uploadNote(
        file: file,
        title: title,
        description: description,
        fileName: fileName,
        department: department,
        className: className,
        fileType: fileType,
      );

      _refreshNotes();
      if (mounted) {
        showAppSnackBar(context, 'Note uploaded successfully');
      }
    } catch (e, st) {
      debugPrint('Supabase note upload failed: $e');
      debugPrint('$st');
      if (mounted) {
        showAppSnackBar(context, 'Upload failed. Please try again',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _confirmDelete(NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete "${note.title}"? The file will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              try {
                await _notesService.deleteNote(note);
                _refreshNotes();
                if (mounted) {
                  Navigator.pop(ctx);
                  showAppSnackBar(context, 'Note deleted successfully');
                }
              } catch (e, st) {
                debugPrint('Supabase note delete failed: $e');
                debugPrint('$st');
                if (mounted) {
                  Navigator.pop(ctx);
                  showAppSnackBar(context, 'Delete failed. Please try again',
                      isError: true);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
