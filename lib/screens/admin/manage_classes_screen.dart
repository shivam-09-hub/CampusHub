import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../models/department_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class ManageClassesScreen extends StatefulWidget {
  final UserModel user;
  const ManageClassesScreen({super.key, required this.user});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      title: 'Classes & Semesters',
      subtitle: 'Build class groups that students and timetables can target.',
      icon: Icons.class_rounded,
      body: StreamBuilder<List<ClassModel>>(
        stream: _supabaseService.getClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final classes = snapshot.data ?? [];
          if (classes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.class_outlined,
              title: 'No Classes',
              subtitle: 'Add classes and semesters for your departments.',
              actionLabel: 'Add Class',
              onAction: () => _showClassDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (_, i) {
              final c = classes[i];
              return ThemedListCard(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.success.withValues(
                        alpha: AppTheme.isDark(context) ? 0.2 : 0.15),
                    child: const Icon(Icons.class_, color: AppTheme.success),
                  ),
                  title: Text(
                    '${c.className} - ${c.semester} ${c.section.isNotEmpty ? '(${c.section})' : ''}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor(context)),
                  ),
                  subtitle: Text('Dept: ${c.departmentName}',
                      style: TextStyle(color: AppTheme.subtitleColor(context))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.primary),
                        onPressed: () => _showClassDialog(cls: c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.error),
                        onPressed: () => _confirmDelete(c),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClassDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
    );
  }

  void _showClassDialog({ClassModel? cls}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ClassDialog(
        user: widget.user,
        cls: cls,
        supabaseService: _supabaseService,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
      showAppSnackBar(context, 'Class saved successfully!');
    }
  }

  void _confirmDelete(ClassModel cls) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete ${cls.className}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              try {
                await _supabaseService.deleteClass(cls.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  setState(() {});
                  showAppSnackBar(context, 'Class deleted successfully!');
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  showAppSnackBar(context, 'Failed to delete: $e',
                      isError: true);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ClassDialog extends StatefulWidget {
  final UserModel user;
  final ClassModel? cls;
  final SupabaseService supabaseService;

  const _ClassDialog({
    required this.user,
    this.cls,
    required this.supabaseService,
  });

  @override
  State<_ClassDialog> createState() => _ClassDialogState();
}

class _ClassDialogState extends State<_ClassDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _semCtrl;
  late TextEditingController _secCtrl;
  String? _selectedDeptId;
  String? _selectedDeptName;
  List<DepartmentModel> _departments = [];
  bool _loadingDepts = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.cls?.className ?? '');
    _semCtrl = TextEditingController(text: widget.cls?.semester ?? '');
    _secCtrl = TextEditingController(text: widget.cls?.section ?? '');
    _selectedDeptId = widget.cls?.departmentId;
    _selectedDeptName = widget.cls?.departmentName;
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final depts = await widget.supabaseService.getDepartments().first;
    if (mounted) {
      setState(() {
        _departments = depts;
        if (_selectedDeptId == null && depts.isNotEmpty) {
          _selectedDeptId = depts.first.id;
          _selectedDeptName = depts.first.name;
        }
        _loadingDepts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDepts) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Text(widget.cls == null ? 'Add Class' : 'Edit Class'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Department'),
              initialValue: _selectedDeptId,
              items: _departments
                  .map(
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDeptId = val;
                  _selectedDeptName =
                      _departments.firstWhere((d) => d.id == val).name;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Class / Course Name',
                hintText: 'e.g. BCA',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _semCtrl,
              decoration: const InputDecoration(
                labelText: 'Semester',
                hintText: 'e.g. Semester 1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secCtrl,
              decoration: const InputDecoration(
                labelText: 'Section (Optional)',
                hintText: 'e.g. A',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_nameCtrl.text.trim().isEmpty ||
                      _semCtrl.text.trim().isEmpty ||
                      _selectedDeptId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill required fields')),
                    );
                    return;
                  }
                  setState(() => _saving = true);
                  final newCls = ClassModel(
                    id: widget.cls?.id ??
                        'cls_${DateTime.now().millisecondsSinceEpoch}',
                    departmentId: _selectedDeptId!,
                    departmentName: _selectedDeptName!,
                    className: _nameCtrl.text.trim(),
                    semester: _semCtrl.text.trim(),
                    section: _secCtrl.text.trim(),
                    createdAt: widget.cls?.createdAt ?? DateTime.now(),
                    createdBy: widget.cls?.createdBy ?? widget.user.uid,
                  );
                  try {
                    await widget.supabaseService.saveClass(newCls);
                    if (mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (mounted) {
                      setState(() => _saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save: $e'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
