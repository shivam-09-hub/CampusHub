import '../utils/model_serializers.dart';

class NoteModel {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String fileUrl;
  final String storagePath;
  final String department;
  final String className;
  final String fileType;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.fileName,
    required this.fileUrl,
    required this.storagePath,
    this.department = '',
    this.className = '',
    this.fileType = 'file',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'file_name': fileName,
        'file_url': fileUrl,
        'storage_path': storagePath,
        'department': department,
        'class_name': className,
        'file_type': fileType,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toSupabaseInsertMap() => {
        'title': title,
        'description': description,
        'file_name': fileName,
        'file_url': fileUrl,
        'storage_path': storagePath,
        'department': department,
        'class_name': className,
        'file_type': fileType,
      };

  factory NoteModel.fromMap(Map<String, dynamic> m) => NoteModel(
        id: '${m['id'] ?? ''}',
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        fileName: m['file_name'] ?? m['fileName'] ?? '',
        fileUrl: m['file_url'] ?? m['fileUrl'] ?? '',
        storagePath: m['storage_path'] ?? m['storagePath'] ?? '',
        department: m['department'] ?? '',
        className: m['class_name'] ?? m['className'] ?? m['semester'] ?? '',
        fileType: m['file_type'] ?? m['fileType'] ?? 'file',
        createdAt: dateTimeFromMapValue(m['created_at'] ?? m['createdAt']),
      );

  String get fileTypeLabel {
    switch (fileType) {
      case 'pdf':
        return 'PDF';
      case 'image':
        return 'Image';
      case 'doc':
        return 'Document';
      default:
        return 'File';
    }
  }
}
