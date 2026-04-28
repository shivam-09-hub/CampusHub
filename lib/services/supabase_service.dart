import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../models/user_model.dart';
import '../models/notice_model.dart';
import '../models/note_model.dart';
import '../models/message_model.dart';
import '../models/department_model.dart';
import '../models/class_model.dart';
import '../models/faculty_model.dart';
import '../models/subject_model.dart';
import '../models/allocation_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Map<String, dynamic> _row(dynamic row) =>
      Map<String, dynamic>.from(row as Map);

  List<T> _rows<T>(
      Iterable<dynamic> rows, T Function(Map<String, dynamic>) fromMap) {
    return rows.map((row) => fromMap(_row(row))).toList();
  }

  Stream<List<UserModel>> getStudents() {
    return _client
        .from('users')
        .stream(primaryKey: ['uid'])
        .eq('role', 'student')
        .order('created_at', ascending: false)
        .map((rows) => _rows(rows, UserModel.fromMap));
  }

  Stream<List<UserModel>> getStudentsByDepartment(String department) {
    return getStudents().map((users) =>
        users.where((user) => user.department == department).toList());
  }

  Future<int> getUserCount(String role) async {
    final rows = await _client.from('users').select('uid').eq('role', role);
    return rows.length;
  }

  Future<void> saveTimetable(TimetableProject project) async {
    final fullPayload = project.toMap();
    try {
      await _client.from('timetables').upsert(fullPayload);
      await _syncAllocations(project);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204') {
        // Extended columns not yet added — retry without them.
        // ⚠ Run supabase_timetable_management_schema.sql to unlock full features.
        final basePayload = Map<String, dynamic>.from(fullPayload)
          ..remove('department')
          ..remove('semester')
          ..remove('published')
          ..remove('created_by');
        await _client.from('timetables').upsert(basePayload);
        await _syncAllocations(project);
      } else {
        rethrow;
      }
    }
  }

  Stream<List<TimetableProject>> getTimetables() {
    return _client.from('timetables').stream(primaryKey: ['id']).map((rows) {
      final list = _rows(rows, TimetableProject.fromMap);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<TimetableProject>> getPublishedTimetables({
    required String department,
    required String semester,
  }) {
    return _client
        .from('timetables')
        .stream(primaryKey: ['id'])
        .eq('published', true)
        .map((rows) {
          final list = _rows(rows, TimetableProject.fromMap)
              .where((project) =>
                  project.department == department &&
                  project.semester == semester)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> deleteTimetable(String id) async {
    try {
      await _client.from('allocations').delete().eq('timetable_id', id);
    } catch (_) {
      // Older databases may not have the allocations table yet.
    }
    await _client.from('timetables').delete().eq('id', id);
  }

  Future<void> togglePublish(String id, bool published) async {
    await _client
        .from('timetables')
        .update({'published': published}).eq('id', id);
  }

  Future<int> getTimetableCount() async {
    final rows = await _client.from('timetables').select('id');
    return rows.length;
  }

  Future<int> getDepartmentCount() async {
    final rows = await _client.from('departments').select('id');
    return rows.length;
  }

  Future<int> getClassCount() async {
    final rows = await _client.from('classes').select('id');
    return rows.length;
  }

  Future<int> getFacultyCount() async {
    final rows = await _client.from('faculties').select('id');
    return rows.length;
  }

  Future<int> getSubjectCount() async {
    final rows = await _client.from('subjects').select('id');
    return rows.length;
  }

  Future<int> getRoomCount() async {
    final rows = await _client.from('rooms').select('id');
    return rows.length;
  }

  /// One-shot fetch of all timetables (used by conflict engine)
  Future<List<TimetableProject>> getAllTimetablesOnce() async {
    final rows = await _client.from('timetables').select();
    return _rows(rows, TimetableProject.fromMap);
  }

  /// Fetch all faculty as a map of name→FacultyModel (for max lectures lookup)
  Future<Map<String, FacultyModel>> getFacultyMap() async {
    final rows = await _client.from('faculties').select();
    final list = _rows(rows, FacultyModel.fromMap);
    return {for (final f in list) f.name: f};
  }

  Future<void> _syncAllocations(TimetableProject project) async {
    try {
      await _client.from('allocations').delete().eq('timetable_id', project.id);

      final createdAt = DateTime.now();
      final rows = project.entries
          .where((entry) => !entry.isBreak)
          .map((entry) => AllocationModel(
                id: '${project.id}_${entry.day}_${entry.slot}_${entry.subjectName.hashCode.abs()}',
                timetableId: project.id,
                department: project.department,
                className: project.className,
                semester: project.semester,
                subjectName: entry.subjectName,
                facultyName: entry.facultyName,
                roomId: entry.roomId,
                day: entry.day,
                slot: entry.slot,
                startTime: entry.startTime,
                endTime: entry.endTime,
                createdAt: createdAt,
                createdBy: project.createdBy ?? '',
              ).toMap())
          .toList();

      if (rows.isNotEmpty) {
        await _client.from('allocations').insert(rows);
      }
    } catch (_) {
      // Keep legacy timetable saves working when the flat allocation table
      // has not been created in Supabase yet.
    }
  }

  Stream<List<AllocationModel>> getAllocations() {
    return _client
        .from('allocations')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => _rows(rows, AllocationModel.fromMap));
  }

  Future<List<AllocationModel>> getAllocationsOnce() async {
    final rows = await _client.from('allocations').select();
    return _rows(rows, AllocationModel.fromMap);
  }

  Future<void> saveNotice(NoticeModel notice) async {
    await _client.from('notices').upsert(notice.toMap());
  }

  Stream<List<NoticeModel>> getNotices() {
    return _client
        .from('notices')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => _rows(rows, NoticeModel.fromMap));
  }

  Stream<List<NoticeModel>> getNoticesForStudent({
    required String department,
    required String semester,
  }) {
    return getNotices().map((notices) => notices
        .where((notice) =>
            notice.targetAudience == 'all' ||
            notice.targetAudience == department ||
            notice.targetAudience == '$department-$semester')
        .toList());
  }

  Future<void> deleteNotice(String id) async {
    await _client.from('notices').delete().eq('id', id);
  }

  Future<int> getNoticeCount() async {
    final rows = await _client.from('notices').select('id');
    return rows.length;
  }

  Future<void> saveNote(NoteModel note) async {
    await _client.from('notes').upsert(note.toMap());
  }

  Stream<List<NoteModel>> getNotes() {
    return _client
        .from('notes')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => _rows(rows, NoteModel.fromMap));
  }

  Stream<List<NoteModel>> getNotesBySubject(String subject) {
    return getNotes();
  }

  Future<void> deleteNote(String id) async {
    await _client.from('notes').delete().eq('id', id);
  }

  Future<void> saveMessage(MessageModel message) async {
    await _client.from('messages').upsert(message.toMap());
  }

  Stream<List<MessageModel>> getMessages() {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => _rows(rows, MessageModel.fromMap));
  }

  Future<void> deleteMessage(String id) async {
    await _client.from('messages').delete().eq('id', id);
  }

  Future<int> getMessageCount() async {
    final rows = await _client.from('messages').select('id');
    return rows.length;
  }

  Future<void> saveDepartment(DepartmentModel dept) async {
    await _client.from('departments').upsert(dept.toMap());
  }

  Stream<List<DepartmentModel>> getDepartments() {
    return _client
        .from('departments')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => _rows(rows, DepartmentModel.fromMap));
  }

  Future<void> deleteDepartment(String id) async {
    await _client.from('departments').delete().eq('id', id);
  }

  Future<void> saveClass(ClassModel cls) async {
    await _client.from('classes').upsert(cls.toMap());
  }

  Stream<List<ClassModel>> getClasses() {
    return _client
        .from('classes')
        .stream(primaryKey: ['id'])
        .order('class_name')
        .map((rows) => _rows(rows, ClassModel.fromMap));
  }

  Future<void> deleteClass(String id) async {
    await _client.from('classes').delete().eq('id', id);
  }

  Future<void> saveFaculty(FacultyModel faculty) async {
    final fullPayload = faculty.toMap();
    try {
      await _client.from('faculties').upsert(fullPayload);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204') {
        // Extended columns not yet added — retry with only the base columns
        // so the save still succeeds on un-migrated databases.
        // ⚠ Run supabase_timetable_management_schema.sql to unlock full features.
        final basePayload = Map<String, dynamic>.from(fullPayload)
          ..remove('available_days')
          ..remove('available_slots')
          ..remove('max_lectures_per_day');
        await _client.from('faculties').upsert(basePayload);
      } else {
        rethrow;
      }
    }
  }

  Stream<List<FacultyModel>> getFaculties() {
    return _client
        .from('faculties')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => _rows(rows, FacultyModel.fromMap));
  }

  Future<void> deleteFaculty(String id) async {
    await _client.from('faculties').delete().eq('id', id);
  }

  Future<void> saveSubject(GlobalSubjectModel subject) async {
    final fullPayload = subject.toMap();
    try {
      await _client.from('subjects').upsert(fullPayload);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204') {
        // Extended columns not yet added — retry without them.
        // ⚠ Run supabase_timetable_management_schema.sql to unlock full features.
        final basePayload = Map<String, dynamic>.from(fullPayload)
          ..remove('hours_per_week')
          ..remove('subject_type');
        await _client.from('subjects').upsert(basePayload);
      } else {
        rethrow;
      }
    }
  }

  Stream<List<GlobalSubjectModel>> getSubjects() {
    return _client
        .from('subjects')
        .stream(primaryKey: ['id'])
        .order('subject_name')
        .map((rows) => _rows(rows, GlobalSubjectModel.fromMap));
  }

  Future<void> deleteSubject(String id) async {
    await _client.from('subjects').delete().eq('id', id);
  }

  /// Saves a room. Returns a warning string if the DB schema is missing the
  /// `room_type` column (PGRST204), or null on full success.
  Future<String?> saveRoom(RoomModel room) async {
    final payload = room.toMap();
    try {
      await _client.from('rooms').upsert(payload);
      return null; // full success
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204') {
        // The rooms table exists but the room_type column has not been added yet.
        // ⚠ Run supabase_timetable_management_schema.sql to fix this permanently.
        // Fallback: save without room_type so the record isn't lost.
        final basePayload = Map<String, dynamic>.from(payload)
          ..remove('room_type');
        await _client.from('rooms').upsert(basePayload);
        // Room saved successfully — return a soft warning instead of throwing.
        return 'Room saved, but the "room_type" column is missing in Supabase.\n'
            'Labs and Seminar Halls will appear as Classrooms until you run\n'
            'supabase_timetable_management_schema.sql in the Supabase SQL editor.';
      } else {
        rethrow;
      }
    }
  }

  Stream<List<RoomModel>> getRooms() {
    return _client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .order('room_id')
        .map((rows) => _rows(rows, RoomModel.fromMap));
  }

  Future<void> deleteRoom(String id) async {
    await _client.from('rooms').delete().eq('id', id);
  }
}
