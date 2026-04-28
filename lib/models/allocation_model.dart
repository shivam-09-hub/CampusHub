import '../utils/model_serializers.dart';

class AllocationModel {
  final String id;
  final String timetableId;
  final String department;
  final String className;
  final String semester;
  final String subjectName;
  final String facultyName;
  final String roomId;
  final int day;
  final int slot;
  final String startTime;
  final String endTime;
  final DateTime createdAt;
  final String createdBy;

  const AllocationModel({
    required this.id,
    required this.timetableId,
    required this.department,
    required this.className,
    required this.semester,
    required this.subjectName,
    required this.facultyName,
    required this.roomId,
    required this.day,
    required this.slot,
    this.startTime = '',
    this.endTime = '',
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timetable_id': timetableId,
        'department': department,
        'class_name': className,
        'semester': semester,
        'subject_name': subjectName,
        'faculty_name': facultyName,
        'room_id': roomId,
        'day': day,
        'slot': slot,
        'start_time': startTime,
        'end_time': endTime,
        'created_at': createdAt.toUtc().toIso8601String(),
        'created_by': createdBy,
      };

  factory AllocationModel.fromMap(Map<String, dynamic> m) => AllocationModel(
        id: m['id'] ?? '',
        timetableId: m['timetable_id'] ?? m['timetableId'] ?? '',
        department: m['department'] ?? '',
        className: m['class_name'] ?? m['className'] ?? '',
        semester: m['semester'] ?? '',
        subjectName: m['subject_name'] ?? m['subjectName'] ?? '',
        facultyName: m['faculty_name'] ?? m['facultyName'] ?? '',
        roomId: m['room_id'] ?? m['roomId'] ?? '',
        day: m['day'] ?? 0,
        slot: m['slot'] ?? 0,
        startTime: m['start_time'] ?? m['startTime'] ?? '',
        endTime: m['end_time'] ?? m['endTime'] ?? '',
        createdAt: dateTimeFromMapValue(m['created_at'] ?? m['createdAt']),
        createdBy: m['created_by'] ?? m['createdBy'] ?? '',
      );
}
