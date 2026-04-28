import '../utils/model_serializers.dart';

class FacultyModel {
  final String id;
  final String name;
  final String email;
  final String departmentId;
  final String departmentName;
  final List<String> subjects;
  final List<String> unavailableTimes;
  final int maxLecturesPerDay;
  final List<int> availableDays;   // 0-indexed day numbers
  final List<int> availableSlots;  // 0-indexed slot numbers
  final DateTime createdAt;
  final String createdBy;

  FacultyModel({
    required this.id,
    required this.name,
    required this.email,
    required this.departmentId,
    required this.departmentName,
    this.subjects = const [],
    this.unavailableTimes = const [],
    this.maxLecturesPerDay = 6,
    this.availableDays = const [],
    this.availableSlots = const [],
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'department_id': departmentId,
        'department_name': departmentName,
        'subjects': subjects,
        'unavailable_times': unavailableTimes,
        'max_lectures_per_day': maxLecturesPerDay,
        'available_days': availableDays,
        'available_slots': availableSlots,
        'created_at': createdAt.toUtc().toIso8601String(),
        'created_by': createdBy,
      };

  factory FacultyModel.fromMap(Map<String, dynamic> m) => FacultyModel(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        departmentId: m['department_id'] ?? m['departmentId'] ?? '',
        departmentName: m['department_name'] ?? m['departmentName'] ?? '',
        subjects: List<String>.from(m['subjects'] ?? []),
        unavailableTimes: List<String>.from(m['unavailable_times'] ?? m['unavailableTimes'] ?? []),
        maxLecturesPerDay: m['max_lectures_per_day'] ?? m['maxLecturesPerDay'] ?? 6,
        availableDays: List<int>.from(m['available_days'] ?? m['availableDays'] ?? []),
        availableSlots: List<int>.from(m['available_slots'] ?? m['availableSlots'] ?? []),
        createdAt: dateTimeFromMapValue(m['created_at'] ?? m['createdAt']),
        createdBy: m['created_by'] ?? m['createdBy'] ?? '',
      );
}
