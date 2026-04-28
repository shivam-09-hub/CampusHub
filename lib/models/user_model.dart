import '../utils/model_serializers.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' or 'student'
  final String department;
  final String semester;
  final DateTime createdAt;
  final String? createdBy;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.department = '',
    this.semester = '',
    required this.createdAt,
    this.createdBy,
  });

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'department': department,
        'semester': semester,
        'created_at': createdAt.toUtc().toIso8601String(),
        'created_by': createdBy,
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        uid: m['uid'] ?? '',
        email: m['email'] ?? '',
        name: m['name'] ?? '',
        role: m['role'] ?? 'student',
        department: m['department'] ?? '',
        semester: m['semester'] ?? '',
        createdAt: dateTimeFromMapValue(m['created_at'] ?? m['createdAt']),
        createdBy: m['created_by'] ?? m['createdBy'],
      );

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? department,
    String? semester,
    DateTime? createdAt,
    String? createdBy,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        name: name ?? this.name,
        role: role ?? this.role,
        department: department ?? this.department,
        semester: semester ?? this.semester,
        createdAt: createdAt ?? this.createdAt,
        createdBy: createdBy ?? this.createdBy,
      );
}
