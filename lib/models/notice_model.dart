import '../utils/model_serializers.dart';

class NoticeModel {
  final String id;
  final String title;
  final String description;
  final String targetAudience; // 'all', or department name, or 'dept-sem'
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    this.targetAudience = 'all',
    required this.createdBy,
    this.createdByName = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'target_audience': targetAudience,
        'created_by': createdBy,
        'created_by_name': createdByName,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory NoticeModel.fromMap(Map<String, dynamic> m) => NoticeModel(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        targetAudience: m['target_audience'] ?? m['targetAudience'] ?? 'all',
        createdBy: m['created_by'] ?? m['createdBy'] ?? '',
        createdByName: m['created_by_name'] ?? m['createdByName'] ?? '',
        createdAt: dateTimeFromMapValue(m['created_at'] ?? m['createdAt']),
      );
}
