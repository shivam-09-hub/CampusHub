import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../../models/department_model.dart';
import '../../models/class_model.dart';

class ManageStudentsScreen extends StatefulWidget {
  final UserModel adminUser;
  const ManageStudentsScreen({super.key, required this.adminUser});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final _supabaseService = SupabaseService();
  final _authService = AuthService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _supabaseService.getStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Supabase Error: ${snapshot.error}');
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Student list loading failed. Please contact admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.error, fontSize: 16),
                ),
              ),
            );
          }

          var students = snapshot.data ?? [];
          if (_searchQuery.isNotEmpty) {
            students = students
                .where((s) =>
                    s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    s.email
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    s.department
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                .toList();
          }

          if (students.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.people_outline,
              title: 'No Students Yet',
              subtitle:
                  'Create student accounts so they can access timetables, notices, and more.',
              actionLabel: 'Create Student',
              onAction: () => _showCreateDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (_, i) => _buildStudentCard(students[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _buildStudentCard(UserModel student) {
    return ThemedListCard(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(
              AppTheme.isDark(context) ? 0.2 : 0.1),
          radius: 24,
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
        title: Text(student.name,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textColor(context))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(student.email,
                style: TextStyle(
                    color: AppTheme.subtitleColor(context), fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                ThemedChip(text: student.department, color: AppTheme.primary),
                const SizedBox(width: 6),
                ThemedChip(text: 'Sem ${student.semester}', color: AppTheme.success),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _showEditDialog(student);
            if (v == 'delete') _confirmDelete(student);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppTheme.error))),
          ],
        ),
      ),
    );
  }

  // _chipLabel removed — now using ThemedChip widget from common_widgets.dart

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(text: _searchQuery);
        return AlertDialog(
          title: const Text('Search Students'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by name, email, or department',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.pop(ctx);
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _searchQuery = ctrl.text);
                Navigator.pop(ctx);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _StudentDialog(adminUser: widget.adminUser, supabaseService: _supabaseService, authService: _authService, onReLoginNeeded: _showReLoginDialog),
    );
  }

  void _showReLoginDialog(String adminEmail) {
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Creating student accounts requires re-authentication.'),
            const SizedBox(height: 16),
            Text('Email: $adminEmail',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Your Admin Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.signIn(adminEmail, passwordCtrl.text.trim());
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Invalid password. Try again.')));
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(UserModel student) {
    showDialog(
      context: context,
      builder: (ctx) => _StudentDialog(adminUser: widget.adminUser, supabaseService: _supabaseService, authService: _authService, onReLoginNeeded: _showReLoginDialog, student: student),
    );
  }

  void _confirmDelete(UserModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
            'Remove "${student.name}" from the system?\n\nThis will delete their Supabase profile. Their auth account will remain but they won\'t be able to login.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              await _authService.deleteUserDoc(student.uid);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student deleted.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StudentDialog extends StatefulWidget {
  final UserModel adminUser;
  final UserModel? student;
  final SupabaseService supabaseService;
  final AuthService authService;
  final Function(String) onReLoginNeeded;

  const _StudentDialog({
    required this.adminUser,
    this.student,
    required this.supabaseService,
    required this.authService,
    required this.onReLoginNeeded,
  });

  @override
  State<_StudentDialog> createState() => _StudentDialogState();
}

class _StudentDialogState extends State<_StudentDialog> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  
  String? _selectedDeptId;
  String? _selectedDeptName;
  String? _selectedSemester;

  List<DepartmentModel> _departments = [];
  List<ClassModel> _classes = [];
  bool _loadingData = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameCtrl.text = widget.student!.name;
      _emailCtrl.text = widget.student!.email;
      _selectedDeptName = widget.student!.department;
      _selectedSemester = widget.student!.semester;
    }
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    final depts = await widget.supabaseService.getDepartments().first;
    final classes = await widget.supabaseService.getClasses().first;
    
    if (mounted) {
      setState(() {
        _departments = depts;
        _classes = classes;
        
        if (depts.isNotEmpty) {
          if (_selectedDeptName != null) {
            final match = depts.where((d) => d.name == _selectedDeptName).toList();
            if (match.isNotEmpty) {
              _selectedDeptId = match.first.id;
            } else {
              _selectedDeptId = depts.first.id;
              _selectedDeptName = depts.first.name;
            }
          } else {
            _selectedDeptId = depts.first.id;
            _selectedDeptName = depts.first.name;
          }
        }
        
        if (_selectedSemester != null && _selectedDeptId != null) {
           final semMatch = _classes.where((c) => c.departmentId == _selectedDeptId && c.semester == _selectedSemester).toList();
           if (semMatch.isEmpty) _selectedSemester = null;
        }

        _loadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const AlertDialog(
        content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_departments.isEmpty) {
      return AlertDialog(
        title: const Text('Missing Data'),
        content: const Text('No departments found. Please add a department in "Manage Departments" first.'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      );
    }

    final isEdit = widget.student != null;
    
    // Filter classes by selected department
    final availableClasses = _classes.where((c) => c.departmentId == _selectedDeptId).map((c) => c.semester).toSet().toList();
    if (availableClasses.isNotEmpty && (_selectedSemester == null || !availableClasses.contains(_selectedSemester))) {
       _selectedSemester = availableClasses.first;
    }

    return AlertDialog(
      title: Text(isEdit ? 'Edit Student Account' : 'Create Student Account', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            if (!isEdit) ...[
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password *', hintText: 'Min 6 characters', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              value: _selectedDeptId,
              decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined)),
              items: _departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDeptId = val;
                  _selectedDeptName = _departments.firstWhere((d) => d.id == val).name;
                  _selectedSemester = null; // reset semester
                });
              },
            ),
            const SizedBox(height: 12),
            if (availableClasses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No classes/semesters found for this department. Add them in "Manage Classes" first.', style: TextStyle(color: Colors.red, fontSize: 12)),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                decoration: const InputDecoration(labelText: 'Semester/Class', prefixIcon: Icon(Icons.school_outlined)),
                items: availableClasses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedSemester = val),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving || availableClasses.isEmpty
              ? null
              : () async {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  if (!isEdit && (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty)) return;
                  if (!isEdit && _passwordCtrl.text.trim().length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                    return;
                  }

                  setState(() => _saving = true);

                  try {
                    if (isEdit) {
                      final updated = widget.student!.copyWith(
                        name: _nameCtrl.text.trim(),
                        department: _selectedDeptName!,
                        semester: _selectedSemester!,
                      );
                      await widget.authService.updateUser(updated);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Student updated!')));
                      }
                    } else {
                      final adminEmail = widget.adminUser.email;
                      await widget.authService.createStudentAccount(
                        email: _emailCtrl.text.trim(),
                        password: _passwordCtrl.text.trim(),
                        name: _nameCtrl.text.trim(),
                        department: _selectedDeptName!,
                        semester: _selectedSemester!,
                        adminUid: widget.adminUser.uid,
                      );
                      Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Student created! Please sign in again.'), backgroundColor: AppTheme.success));
                        widget.onReLoginNeeded(adminEmail);
                      }
                    }
                  } on AuthException catch (e) {
                    setState(() => _saving = false);
                    final detail = e.message.toLowerCase();
                    final message = detail.contains('already')
                        ? 'Email already registered.'
                        : 'Failed: ${e.message}';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                  } catch (e) {
                    setState(() => _saving = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
        ),
      ],
    );
  }
}
