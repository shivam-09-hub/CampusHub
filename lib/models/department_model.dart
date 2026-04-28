import '../utils/model_serializers.dart';

class DepartmentModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final String createdBy;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toUtc().toIso8601String(),
        'created_by': createdBy,
      };

  factory DepartmentModel.fromMap(Map<String, dynamic> m) => DepartmentModel(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        createdAt: dateTimeFromMapValue(m['created_at'] ?? m['createdAt']),
        createdBy: m['created_by'] ?? m['createdBy'] ?? '',
      );
}
