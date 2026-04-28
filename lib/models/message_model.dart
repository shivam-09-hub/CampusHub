import '../utils/model_serializers.dart';

class MessageModel {
  final String id;
  final String title;
  final String content;
  final String priority; // 'normal', 'important', 'urgent'
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.title,
    required this.content,
    this.priority = 'normal',
    required this.createdBy,
    this.createdByName = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'priority': priority,
        'created_by': createdBy,
        'created_by_name': createdByName,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory MessageModel.fromMap(Map<String, dynamic> m) => MessageModel(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        content: m['content'] ?? '',
        priority: m['priority'] ?? 'normal',
        createdBy: m['created_by'] ?? m['createdBy'] ?? '',
        createdByName: m['created_by_name'] ?? m['createdByName'] ?? '',
        createdAt: dateTimeFromMapValue(m['created_at'] ?? m['createdAt']),
      );

  bool get isUrgent => priority == 'urgent';
  bool get isImportant => priority == 'important';
}
