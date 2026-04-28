import '../utils/model_serializers.dart';

class GlobalSubjectModel {
  final String id;
  final String subjectName;
  final String departmentId;
  final String departmentName;
  final String classId;
  final String semester;
  final String assignedFacultyId;
  final String assignedFacultyName;
  final int hoursPerWeek;
  final String subjectType; // Theory, Lab, Tutorial
  final DateTime createdAt;
  final String createdBy;

  GlobalSubjectModel({
    required this.id,
    required this.subjectName,
    required this.departmentId,
    required this.departmentName,
    required this.classId,
    required this.semester,
    this.assignedFacultyId = '',
    this.assignedFacultyName = '',
    this.hoursPerWeek = 3,
    this.subjectType = 'Theory',
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_name': subjectName,
        'department_id': departmentId,
        'department_name': departmentName,
        'class_id': classId,
        'semester': semester,
        'assigned_faculty_id': assignedFacultyId,
        'assigned_faculty_name': assignedFacultyName,
        'hours_per_week': hoursPerWeek,
        'subject_type': subjectType,
        'created_at': createdAt.toUtc().toIso8601String(),
        'created_by': createdBy,
      };

  factory GlobalSubjectModel.fromMap(Map<String, dynamic> m) => GlobalSubjectModel(
        id: m['id'] ?? '',
        subjectName: m['subject_name'] ?? m['subjectName'] ?? '',
        departmentId: m['department_id'] ?? m['departmentId'] ?? '',
        departmentName: m['department_name'] ?? m['departmentName'] ?? '',
        classId: m['class_id'] ?? m['classId'] ?? '',
        semester: m['semester'] ?? '',
        assignedFacultyId: m['assigned_faculty_id'] ?? m['assignedFacultyId'] ?? '',
        assignedFacultyName: m['assigned_faculty_name'] ?? m['assignedFacultyName'] ?? '',
        hoursPerWeek: m['hours_per_week'] ?? m['hoursPerWeek'] ?? 3,
        subjectType: m['subject_type'] ?? m['subjectType'] ?? 'Theory',
        createdAt: dateTimeFromMapValue(m['created_at'] ?? m['createdAt']),
        createdBy: m['created_by'] ?? m['createdBy'] ?? '',
      );
}
