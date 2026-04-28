import '../utils/model_serializers.dart';

class ClassModel {
  final String id;
  final String departmentId;
  final String departmentName;
  final String className;
  final String semester;
  final String section;
  final DateTime createdAt;
  final String createdBy;

  ClassModel({
    required this.id,
    required this.departmentId,
    required this.departmentName,
    required this.className,
    required this.semester,
    this.section = '',
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'department_id': departmentId,
        'department_name': departmentName,
        'class_name': className,
        'semester': semester,
        'section': section,
        'created_at': createdAt.toUtc().toIso8601String(),
        'created_by': createdBy,
      };

  factory ClassModel.fromMap(Map<String, dynamic> m) => ClassModel(
        id: m['id'] ?? '',
        departmentId: m['department_id'] ?? m['departmentId'] ?? '',
        departmentName: m['department_name'] ?? m['departmentName'] ?? '',
        className: m['class_name'] ?? m['className'] ?? '',
        semester: m['semester'] ?? '',
        section: m['section'] ?? '',
        createdAt: dateTimeFromMapValue(m['created_at'] ?? m['createdAt']),
        createdBy: m['created_by'] ?? m['createdBy'] ?? '',
      );
}
