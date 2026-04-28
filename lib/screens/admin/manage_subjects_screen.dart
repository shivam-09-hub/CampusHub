import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/subject_model.dart';
import '../../models/department_model.dart';
import '../../models/class_model.dart';
import '../../models/faculty_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class ManageSubjectsScreen extends StatefulWidget {
  final UserModel user;
  const ManageSubjectsScreen({super.key, required this.user});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Subjects')),
      body: StreamBuilder<List<GlobalSubjectModel>>(
        stream: _supabaseService.getSubjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final subjects = snapshot.data ?? [];
          if (subjects.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.book,
              title: 'No Subjects',
              subtitle: 'Add subjects to use in the timetable builder.',
              actionLabel: 'Add Subject',
              onAction: () => _showSubjectDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            itemBuilder: (_, i) {
              final s = subjects[i];
              final typeColor = s.subjectType == 'Lab'
                  ? AppTheme.warning
                  : s.subjectType == 'Tutorial'
                      ? AppTheme.success
                      : AppTheme.primary;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: AppTheme.cardRadius,
                  border: Border.all(color: AppTheme.borderColor(context)),
                  boxShadow: AppTheme.adaptiveShadow(context),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: typeColor.withValues(
                        alpha: AppTheme.isDark(context) ? 0.2 : 0.15),
                    child: Icon(
                        s.subjectType == 'Lab'
                            ? Icons.science
                            : s.subjectType == 'Tutorial'
                                ? Icons.quiz
                                : Icons.book,
                        color: typeColor),
                  ),
                  title: Row(children: [
                    Expanded(
                        child: Text(s.subjectName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor(context)))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(s.subjectType,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: typeColor)),
                    ),
                  ]),
                  subtitle: Text(
                      '${s.departmentName} • Sem ${s.semester} • ${s.hoursPerWeek} hrs/wk\nFaculty: ${s.assignedFacultyName.isNotEmpty ? s.assignedFacultyName : "Unassigned"}',
                      style: TextStyle(
                          color: AppTheme.subtitleColor(context),
                          fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppTheme.primary, size: 20),
                        onPressed: () => _showSubjectDialog(subject: s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: AppTheme.error, size: 20),
                        onPressed: () => _confirmDelete(s),
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
        onPressed: () => _showSubjectDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
    );
  }

  void _showSubjectDialog({GlobalSubjectModel? subject}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SubjectDialog(
        user: widget.user,
        subject: subject,
        supabaseService: _supabaseService,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
      showAppSnackBar(context, 'Subject saved successfully!');
    }
  }

  void _confirmDelete(GlobalSubjectModel subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content:
            Text('Are you sure you want to delete ${subject.subjectName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              try {
                await _supabaseService.deleteSubject(subject.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  setState(() {});
                  showAppSnackBar(context, 'Subject deleted successfully!');
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

class _SubjectDialog extends StatefulWidget {
  final UserModel user;
  final GlobalSubjectModel? subject;
  final SupabaseService supabaseService;

  const _SubjectDialog({
    required this.user,
    this.subject,
    required this.supabaseService,
  });

  @override
  State<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<_SubjectDialog> {
  final _nameCtrl = TextEditingController();

  String? _selectedDeptId;
  String? _selectedDeptName;
  String? _selectedSemester;
  String? _selectedClassId;

  String? _selectedFacultyId;
  String? _selectedFacultyName;

  int _hoursPerWeek = 3;
  String _subjectType = 'Theory';

  List<DepartmentModel> _departments = [];
  List<ClassModel> _classes = [];
  List<FacultyModel> _faculties = [];
  bool _loadingData = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameCtrl.text = widget.subject!.subjectName;
      _selectedDeptId = widget.subject!.departmentId;
      _selectedDeptName = widget.subject!.departmentName;
      _selectedSemester = widget.subject!.semester;
      _selectedClassId = widget.subject!.classId;
      _hoursPerWeek = widget.subject!.hoursPerWeek;
      _subjectType = widget.subject!.subjectType;
      if (widget.subject!.assignedFacultyId.isNotEmpty) {
        _selectedFacultyId = widget.subject!.assignedFacultyId;
        _selectedFacultyName = widget.subject!.assignedFacultyName;
      }
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final depts = await widget.supabaseService.getDepartments().first;
    final classes = await widget.supabaseService.getClasses().first;
    final faculties = await widget.supabaseService.getFaculties().first;

    if (mounted) {
      setState(() {
        _departments = depts;
        _classes = classes;
        _faculties = faculties;

        if (depts.isNotEmpty && _selectedDeptId == null) {
          _selectedDeptId = depts.first.id;
          _selectedDeptName = depts.first.name;
        }
        _loadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_departments.isEmpty) {
      return AlertDialog(
        title: const Text('Missing Data'),
        content: const Text('Add departments first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('OK'),
          ),
        ],
      );
    }

    final availableClasses =
        _classes.where((c) => c.departmentId == _selectedDeptId).toList();
    final availableFaculties = _faculties.where((faculty) {
      return faculty.departmentId == _selectedDeptId ||
          faculty.departmentName == _selectedDeptName ||
          faculty.departmentId.isEmpty;
    }).toList()
      ..sort((a, b) {
        final subjectName = _nameCtrl.text.trim().toLowerCase();
        final aMatch = a.subjects
            .any((subject) => subject.toLowerCase().contains(subjectName));
        final bMatch = b.subjects
            .any((subject) => subject.toLowerCase().contains(subjectName));
        if (aMatch == bMatch) return a.name.compareTo(b.name);
        return aMatch ? -1 : 1;
      });
    if (availableClasses.isNotEmpty &&
        (_selectedClassId == null ||
            !availableClasses.any((c) => c.id == _selectedClassId))) {
      _selectedSemester = availableClasses.first.semester;
      _selectedClassId = availableClasses.first.id;
    }
    if (_selectedFacultyId != null &&
        !availableFaculties
            .any((faculty) => faculty.id == _selectedFacultyId)) {
      _selectedFacultyId = null;
      _selectedFacultyName = '';
    }

    return AlertDialog(
      title: Text(widget.subject == null ? 'Add Subject' : 'Edit Subject'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Subject Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedDeptId,
              decoration: const InputDecoration(labelText: 'Department'),
              items: _departments
                  .map(
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDeptId = val;
                  _selectedDeptName =
                      _departments.firstWhere((d) => d.id == val).name;
                  _selectedSemester = null;
                  _selectedClassId = null;
                  _selectedFacultyId = null;
                  _selectedFacultyName = '';
                });
              },
            ),
            const SizedBox(height: 12),
            if (availableClasses.isEmpty)
              const Text('No classes found in this dept.',
                  style: TextStyle(color: Colors.red))
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedClassId,
                decoration:
                    const InputDecoration(labelText: 'Class / Semester'),
                items: availableClasses
                    .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                            '${c.className} - ${c.semester}${c.section.isNotEmpty ? ' (${c.section})' : ''}')))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    final selected =
                        availableClasses.firstWhere((c) => c.id == val);
                    _selectedClassId = selected.id;
                    _selectedSemester = selected.semester;
                  });
                },
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedFacultyId,
              decoration:
                  const InputDecoration(labelText: 'Assign Faculty (Optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...availableFaculties.map((f) => DropdownMenuItem(
                    value: f.id,
                    child: Text(f.subjects.isEmpty
                        ? f.name
                        : '${f.name} • ${f.subjects.take(2).join(", ")}')))
              ],
              onChanged: (val) {
                setState(() {
                  _selectedFacultyId = val;
                  if (val != null) {
                    _selectedFacultyName =
                        _faculties.firstWhere((f) => f.id == val).name;
                  } else {
                    _selectedFacultyName = '';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            // Hours per week
            Text('Hours/Week: $_hoursPerWeek',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Slider(
              value: _hoursPerWeek.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_hoursPerWeek',
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _hoursPerWeek = v.round()),
            ),
            const SizedBox(height: 8),
            // Subject type
            const Text('Subject Type:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
                spacing: 8,
                children: ['Theory', 'Lab', 'Tutorial']
                    .map((t) => ChoiceChip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          selected: _subjectType == t,
                          onSelected: (_) => setState(() => _subjectType = t),
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(
                              color: _subjectType == t
                                  ? Colors.white
                                  : AppTheme.textColor(context),
                              fontWeight: FontWeight.w600),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (availableClasses.isEmpty || _saving)
              ? null
              : () async {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  setState(() => _saving = true);

                  final subj = GlobalSubjectModel(
                    id: widget.subject?.id ??
                        'sub_${DateTime.now().millisecondsSinceEpoch}',
                    subjectName: _nameCtrl.text.trim(),
                    departmentId: _selectedDeptId!,
                    departmentName: _selectedDeptName!,
                    classId: _selectedClassId!,
                    semester: _selectedSemester!,
                    assignedFacultyId: _selectedFacultyId ?? '',
                    assignedFacultyName: _selectedFacultyName ?? '',
                    hoursPerWeek: _hoursPerWeek,
                    subjectType: _subjectType,
                    createdAt: widget.subject?.createdAt ?? DateTime.now(),
                    createdBy: widget.subject?.createdBy ?? widget.user.uid,
                  );

                  try {
                    await widget.supabaseService.saveSubject(subj);
                    if (_selectedFacultyId != null) {
                      final faculty = _faculties
                          .firstWhere((f) => f.id == _selectedFacultyId);
                      final expertise = [...faculty.subjects];
                      if (!expertise.contains(subj.subjectName)) {
                        expertise.add(subj.subjectName);
                        await widget.supabaseService.saveFaculty(FacultyModel(
                          id: faculty.id,
                          name: faculty.name,
                          email: faculty.email,
                          departmentId: faculty.departmentId,
                          departmentName: faculty.departmentName,
                          subjects: expertise,
                          unavailableTimes: faculty.unavailableTimes,
                          maxLecturesPerDay: faculty.maxLecturesPerDay,
                          availableDays: faculty.availableDays,
                          availableSlots: faculty.availableSlots,
                          createdAt: faculty.createdAt,
                          createdBy: faculty.createdBy,
                        ));
                      }
                    }
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
        )
      ],
    );
  }
}
