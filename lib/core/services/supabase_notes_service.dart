import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/supabase_config.dart';
import '../../models/note_model.dart';

class SupabaseNotesService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<NoteModel> uploadNote({
    required File file,
    required String title,
    required String description,
    required String fileName,
    required String department,
    required String className,
    required String fileType,
  }) async {
    final storagePath = _buildStoragePath(
      department: department,
      className: className,
      fileName: fileName,
    );

    // Supabase Storage upload for notes.
    final storage = _client.storage.from(SupabaseConfig.notesBucket);
    await storage.upload(
      storagePath,
      file,
      fileOptions: FileOptions(
        contentType: _contentTypeFor(fileType),
        upsert: false,
      ),
    );

    final fileUrl = storage.getPublicUrl(storagePath);

    final inserted = await _client
        .from(SupabaseConfig.notesTable)
        .insert({
          'title': title,
          'description': description,
          'file_name': fileName,
          'file_url': fileUrl,
          'storage_path': storagePath,
          'department': department,
          'class_name': className,
          'file_type': fileType,
        })
        .select()
        .single();

    return NoteModel.fromMap(Map<String, dynamic>.from(inserted));
  }

  Future<List<NoteModel>> fetchNotes() async {
    final rows = await _client
        .from(SupabaseConfig.notesTable)
        .select()
        .order('created_at', ascending: false);

    return rows
        .map<NoteModel>((row) => NoteModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> deleteNote(NoteModel note) async {
    if (note.storagePath.isNotEmpty) {
      await _client.storage
          .from(SupabaseConfig.notesBucket)
          .remove([note.storagePath]);
    }

    await _client
        .from(SupabaseConfig.notesTable)
        .delete()
        .eq('id', note.id);
  }

  Future<void> openNote(NoteModel note) async {
    final uri = Uri.tryParse(note.fileUrl);
    if (uri == null) {
      debugPrint('Invalid note URL: ${note.fileUrl}');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _buildStoragePath({
    required String department,
    required String className,
    required String fileName,
  }) {
    final safeFileName = _safeFileName(fileName);
    final stampedFileName =
        '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
    final safeDepartment = _safePathSegment(department);
    final safeClassName = _safePathSegment(className);

    if (safeDepartment.isEmpty || safeClassName.isEmpty) {
      return 'notes/general/$stampedFileName';
    }

    return 'notes/$safeDepartment/$safeClassName/$stampedFileName';
  }

  String _safePathSegment(String value) {
    return value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
  }

  String _safeFileName(String value) {
    return value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9.\-]+'), '_');
  }

  String _contentTypeFor(String fileType) {
    switch (fileType) {
      case 'pdf':
        return 'application/pdf';
      case 'image':
        return 'image/jpeg';
      case 'doc':
        return 'application/octet-stream';
      default:
        return 'application/octet-stream';
    }
  }
}
