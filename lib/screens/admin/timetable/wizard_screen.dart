import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../models/user_model.dart';
import '../../../models/department_model.dart';
import '../../../models/faculty_model.dart';
import '../../../models/class_model.dart';
import '../../../models/subject_model.dart';
import '../../../config/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/timetable_generator.dart';
import '../../../utils/conflict_engine.dart';
import 'result_screen.dart';

class WizardScreen extends StatefulWidget {
  final TimetableProject? existingProject;
  final UserModel user;
  final bool isDemo;
  const WizardScreen(
      {super.key,
      required this.existingProject,
      required this.user,
      this.isDemo = false});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  int _step = 1;
  final int _totalSteps = 5;
  final _classNameCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();
  int _workingDays = 5;
  int _slotsPerDay = 6;

  List<SubjectModel> _subjects = [];
  List<RoomModel> _rooms = [];
  List<FacultyAvailability> _availability = [];
  List<TimeSlotDef> _timeSlots = [];

  // --- Existing DB data for dropdowns ---
  final _supabaseService = SupabaseService();
  List<DepartmentModel> _dbDepartments = [];
  List<FacultyModel> _dbFaculty = [];
  List<RoomModel> _dbRooms = [];
  List<GlobalSubjectModel> _dbSubjects = [];
  List<ClassModel> _dbClasses = [];

  // --- Conflict analysis ---
  List<TimetableProject> _existingTimetables = [];
  Map<String, int> _facultyMaxLectures = {};
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProject != null) {
      final p = widget.existingProject!;
      _classNameCtrl.text = p.className;
      _workingDays = p.workingDays;
      _slotsPerDay = p.slotsPerDay;
      _subjects = List.from(p.subjects);
      _rooms = List.from(p.rooms);
      _availability = List.from(p.facultyAvailability);
      _timeSlots = List.from(p.timeSlots);
      if (p.department.isNotEmpty) _departmentCtrl.text = p.department;
      if (p.semester.isNotEmpty) _semesterCtrl.text = p.semester;
    }
    if (_timeSlots.isEmpty) _generateDefaultSlots();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      _supabaseService.getDepartments().first.then((d) {
        if (mounted) setState(() => _dbDepartments = d);
      });
      _supabaseService.getFaculties().first.then((f) {
        if (mounted) setState(() => _dbFaculty = f);
      });
      _supabaseService.getRooms().first.then((r) {
        if (mounted) setState(() => _dbRooms = r);
      });
      _supabaseService.getSubjects().first.then((s) {
        if (mounted) setState(() => _dbSubjects = s);
      });
      _supabaseService.getClasses().first.then((c) {
        if (mounted) setState(() => _dbClasses = c);
      });
    } catch (_) {}
  }

  void _generateDefaultSlots() {
    _timeSlots = List.generate(_slotsPerDay, (i) {
      final hour = 9 + i;
      return TimeSlotDef(
          startTime: '${hour.toString().padLeft(2, '0')}:00',
          endTime: '${hour.toString().padLeft(2, '0')}:50');
    });
  }

  @override
  void dispose() {
    _classNameCtrl.dispose();
    _departmentCtrl.dispose();
    _semesterCtrl.dispose();
    super.dispose();
  }

  bool _validateStep() {
    if (_step == 1) {
      if (_classNameCtrl.text.trim().isEmpty) {
        _showError('Enter class name');
        return false;
      }
      if (_departmentCtrl.text.trim().isEmpty) {
        _showError('Enter department name');
        return false;
      }
      if (_semesterCtrl.text.trim().isEmpty) {
        _showError('Enter semester');
        return false;
      }
    }
    if (_step == 2 && _subjects.isEmpty) {
      _showError('Add at least one subject');
      return false;
    }
    if (_step == 2 &&
        _subjects.any((subject) =>
            subject.facultyName.trim().isEmpty ||
            subject.facultyName.trim().toUpperCase() == 'TBA')) {
      _showError('Assign faculty to every subject before generation');
      return false;
    }
    if (_step == 3 && _rooms.isEmpty) {
      _showError('Add at least one room');
      return false;
    }
    if (_step == 3 &&
        _subjects
            .any((subject) => subject.subjectType.toLowerCase() == 'lab') &&
        !_rooms.any((room) => room.roomType.toLowerCase() == 'lab')) {
      _showError('Add at least one lab for lab subjects');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating));
  }

  bool get _isDarkMode => AppTheme.isDark(context);

  Color get _wizardPrimary =>
      _isDarkMode ? const Color(0xFF8B84FF) : AppTheme.primary;

  Color get _primaryLabelColor =>
      _isDarkMode ? const Color(0xFFC7C3FF) : AppTheme.primary;

  Color get _chipBackground =>
      _isDarkMode ? const Color(0xFF20243E) : const Color(0xFFF3F5FF);

  Color get _disabledChipBackground =>
      _isDarkMode ? const Color(0xFF17192B) : Colors.grey.shade100;

  TextStyle _chipLabelStyle(bool selected,
          {double? fontSize, FontWeight fontWeight = FontWeight.w600}) =>
      TextStyle(
          fontSize: fontSize,
          color: selected ? Colors.white : AppTheme.textColor(context),
          fontWeight: fontWeight);

  TextStyle _softChipLabelStyle(bool selected, Color accent,
          {double? fontSize}) =>
      TextStyle(
          fontSize: fontSize,
          color: selected
              ? (_isDarkMode ? const Color(0xFFE3E1FF) : accent)
              : AppTheme.subtitleColor(context),
          fontWeight: FontWeight.w600);

  BorderSide _chipSide(bool selected, [Color? accent]) => BorderSide(
      color: selected
          ? (accent ?? _wizardPrimary).withValues(alpha: _isDarkMode ? 0.8 : 1)
          : AppTheme.borderColor(context),
      width: 1);

  Color _softFill(Color accent, {double light = 0.08, double dark = 0.14}) =>
      Color.alphaBlend(accent.withValues(alpha: _isDarkMode ? dark : light),
          AppTheme.cardColor(context));

  void _next() {
    if (!_validateStep()) return;
    if (_step < _totalSteps) setState(() => _step++);
  }

  void _prev() {
    if (_step > 1) setState(() => _step--);
  }

  Future<void> _generateAndNavigate() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      _slotsPerDay = _timeSlots.length;
      // Fetch existing timetables for cross-conflict detection
      _existingTimetables = await _supabaseService.getAllTimetablesOnce();
      final facultyMap = await _supabaseService.getFacultyMap();
      _facultyMaxLectures = {
        for (final e in facultyMap.entries) e.key: e.value.maxLecturesPerDay
      };

      // Ensure all faculty have availability entries
      final allFaculty = _subjects.map((s) => s.facultyName).toSet();
      for (final f in allFaculty) {
        if (!_availability.any((a) => a.facultyName == f)) {
          // Check DB for faculty availability preferences
          final dbFac = facultyMap[f];
          _availability.add(FacultyAvailability(
            facultyName: f,
            availableDays: dbFac?.availableDays.isNotEmpty == true
                ? List.from(dbFac!.availableDays)
                : List.generate(_workingDays, (i) => i),
            availableSlots: dbFac?.availableSlots.isNotEmpty == true
                ? List.from(dbFac!.availableSlots)
                : List.generate(_slotsPerDay, (i) => i),
          ));
        }
      }

      final (entries, messages) = TimetableGenerator.generate(
        workingDays: _workingDays,
        timeSlots: _timeSlots,
        subjects: _subjects,
        rooms: _rooms,
        facultyAvailability: _availability,
        existingTimetables: _existingTimetables,
        facultyMaxLectures: _facultyMaxLectures,
        className: _classNameCtrl.text.trim(),
        excludeProjectId: widget.existingProject?.id,
      );

      // Apply time info to entries
      for (final e in entries) {
        if (e.slot < _timeSlots.length) {
          e.startTime = _timeSlots[e.slot].startTime;
          e.endTime = _timeSlots[e.slot].endTime;
        }
      }

      // Post-generation conflict analysis
      final conflicts = ConflictEngine.analyzeGlobal(
        existingTimetables: _existingTimetables
            .where((t) => t.id != widget.existingProject?.id)
            .toList(),
        newEntries: entries,
        newClassName: _classNameCtrl.text.trim(),
        workingDays: _workingDays,
        timeSlots: _timeSlots,
        facultyMaxLectures: _facultyMaxLectures,
        facultyAvailability: {
          for (final item in _availability) item.facultyName: item,
        },
      );

      // Mark conflicting entries
      for (final c in conflicts) {
        if (c.day != null && c.slot != null) {
          for (final e in entries) {
            if (e.day == c.day && e.slot == c.slot) {
              e.hasConflict = true;
            }
          }
        }
      }

      final errorCount = conflicts.where((c) => c.severity == 'error').length;
      if (errorCount > 0) {
        messages.add(
            '🔴 $errorCount cross-timetable conflict(s) detected! Review in the result screen.');
      }

      final project = TimetableProject(
        id: widget.existingProject?.id ??
            'proj_${DateTime.now().millisecondsSinceEpoch}',
        className: _classNameCtrl.text.trim(),
        workingDays: _workingDays,
        slotsPerDay: _slotsPerDay,
        subjects: _subjects,
        rooms: _rooms,
        facultyAvailability: _availability,
        entries: entries,
        timeSlots: _timeSlots,
        createdAt: DateTime.now(),
        department: _departmentCtrl.text.trim(),
        semester: _semesterCtrl.text.trim(),
        createdBy: widget.user.uid,
      );

      await _supabaseService.saveTimetable(project);

      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ResultScreen(
                  project: project, messages: messages, user: widget.user)));
    } catch (e) {
      if (mounted) {
        _showError('Generation failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Timetable'), actions: [
        TextButton(
            onPressed: _showResetDialog,
            child:
                const Text('Reset', style: TextStyle(color: AppTheme.error))),
      ]),
      body: Column(children: [
        _buildProgress(),
        Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(20), child: _buildCurrentStep())),
        _buildNavButtons(),
      ]),
    );
  }

  Widget _buildProgress() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Step $_step of $_totalSteps',
                style: TextStyle(
                    color: _primaryLabelColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            Text('${((_step / _totalSteps) * 100).round()}%',
                style: TextStyle(
                    color: AppTheme.subtitleColor(context), fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: _step / _totalSteps,
              backgroundColor:
                  _isDarkMode ? const Color(0xFF2B304D) : AppTheme.lightGrey,
              valueColor: AlwaysStoppedAnimation(_wizardPrimary),
              minHeight: 6,
              borderRadius: BorderRadius.circular(4)),
        ]));
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return const SizedBox();
    }
  }

  // Step 1: Basic Details + Department + Time Slots
  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Basic Details', Icons.info_outline),

      // --- Department: dropdown + manual entry ---
      if (_dbDepartments.isNotEmpty) ...[
        Text('Select Department',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.subtitleColor(context))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _dbDepartments
              .map((d) => ChoiceChip(
                    label: Text(d.name),
                    selected: _departmentCtrl.text == d.name,
                    onSelected: (_) =>
                        setState(() => _departmentCtrl.text = d.name),
                    selectedColor: _wizardPrimary,
                    backgroundColor: _chipBackground,
                    checkmarkColor: Colors.white,
                    side: _chipSide(_departmentCtrl.text == d.name),
                    labelStyle: _chipLabelStyle(_departmentCtrl.text == d.name),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
      ],
      if (_dbDepartments.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('No departments found. Add them in the Admin Dashboard first.', style: TextStyle(color: AppTheme.error)),
        ),
      const SizedBox(height: 16),

      // --- Class: dropdown + manual entry ---
      if (_dbClasses.isNotEmpty) ...[
        Text('Select Class',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.subtitleColor(context))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _dbClasses.map((c) {
            final label =
                '${c.className} (${c.departmentName} - Sem ${c.semester})';
            final isSelected = _classNameCtrl.text == c.className;
            return ChoiceChip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => setState(() {
                _classNameCtrl.text = c.className;
                _departmentCtrl.text = c.departmentName;
                _semesterCtrl.text = c.semester;
              }),
              selectedColor: _wizardPrimary,
              backgroundColor: _chipBackground,
              checkmarkColor: Colors.white,
              side: _chipSide(isSelected),
              labelStyle: _chipLabelStyle(isSelected, fontSize: 12),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
      if (_dbClasses.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('No classes found. Add them in the Admin Dashboard first.', style: TextStyle(color: AppTheme.error)),
        ),
      const SizedBox(height: 20),
      Text('Working Days',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.textColor(context))),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          children: List.generate(7, (i) {
            final day = i + 1;
            return ChoiceChip(
                label: Text('$day'),
                selected: _workingDays == day,
                onSelected: (_) => setState(() => _workingDays = day),
                selectedColor: _wizardPrimary,
                backgroundColor: _chipBackground,
                checkmarkColor: Colors.white,
                side: _chipSide(_workingDays == day),
                labelStyle: _chipLabelStyle(_workingDays == day));
          })),
      const SizedBox(height: 20),
      Text('Slots Per Day',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.textColor(context))),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          children: [4, 5, 6, 7, 8, 9, 10]
              .map((n) => ChoiceChip(
                  label: Text('$n'),
                  selected: _slotsPerDay == n,
                  onSelected: (_) {
                    setState(() {
                      _slotsPerDay = n;
                      _generateDefaultSlots();
                    });
                  },
                  selectedColor: _wizardPrimary,
                  backgroundColor: _chipBackground,
                  checkmarkColor: Colors.white,
                  side: _chipSide(_slotsPerDay == n),
                  labelStyle: _chipLabelStyle(_slotsPerDay == n)))
              .toList()),
      const SizedBox(height: 24),
      _sectionHeader('Time Slots (Editable)', Icons.access_time),
      ..._timeSlots.asMap().entries.map((e) => _buildTimeSlotRow(e.key)),
      const SizedBox(height: 12),
      OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Break'),
          onPressed: () {
            setState(() => _timeSlots.add(TimeSlotDef(
                startTime: '12:00',
                endTime: '12:30',
                isBreak: true,
                breakName: 'Lunch Break')));
          }),
    ]);
  }

  Widget _buildTimeSlotRow(int index) {
    final slot = _timeSlots[index];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: slot.isBreak
                          ? _softFill(AppTheme.warning, light: 0.15, dark: 0.18)
                          : _softFill(_wizardPrimary, light: 0.1, dark: 0.16),
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                      child: Text(slot.isBreak ? '☕' : '${index + 1}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: slot.isBreak
                                  ? (_isDarkMode
                                      ? const Color(0xFFFDE68A)
                                      : AppTheme.warning)
                                  : _primaryLabelColor)))),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    if (slot.isBreak)
                      Text(slot.breakName.isNotEmpty ? slot.breakName : 'Break',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.textColor(context))),
                    Text('${slot.startTime} - ${slot.endTime}',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.subtitleColor(context))),
                  ])),
              IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editTimeSlot(index)),
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.error),
                  onPressed: () => setState(() => _timeSlots.removeAt(index))),
            ])));
  }

  void _editTimeSlot(int index) {
    final slot = _timeSlots[index];
    final startCtrl = TextEditingController(text: slot.startTime);
    final endCtrl = TextEditingController(text: slot.endTime);
    final nameCtrl = TextEditingController(text: slot.breakName);
    bool isBreak = slot.isBreak;

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDlg) => AlertDialog(
                  title: const Text('Edit Time Slot'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: startCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Start Time', hintText: '09:00')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(
                            labelText: 'End Time', hintText: '09:50')),
                    const SizedBox(height: 12),
                    SwitchListTile(
                        title: const Text('Is Break/Recess'),
                        value: isBreak,
                        onChanged: (v) => setDlg(() => isBreak = v)),
                    if (isBreak)
                      TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Break Name',
                              hintText: 'Lunch Break')),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _timeSlots[index] = TimeSlotDef(
                                startTime: startCtrl.text,
                                endTime: endCtrl.text,
                                isBreak: isBreak,
                                breakName: nameCtrl.text);
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save')),
                  ],
                )));
  }

  // Step 2: Subjects
  Widget _buildStep2() {
    final selectedDepartment = _departmentCtrl.text.trim();
    final selectedSemester = _semesterCtrl.text.trim();
    final importableSubjects = _dbSubjects.where((subject) {
      final departmentMatches = selectedDepartment.isEmpty ||
          subject.departmentName == selectedDepartment;
      final semesterMatches =
          selectedSemester.isEmpty || subject.semester == selectedSemester;
      return departmentMatches && semesterMatches;
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Subjects', Icons.book_outlined),
      // Import from existing DB subjects
      if (importableSubjects.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.auto_awesome, color: AppTheme.success, size: 18),
              SizedBox(width: 8),
              Text('Quick Import',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.success)),
            ]),
            const SizedBox(height: 8),
            Text('Tap to add subjects from your database:',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.subtitleColor(context))),
            const SizedBox(height: 8),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: importableSubjects.map((gs) {
                  final alreadyAdded =
                      _subjects.any((s) => s.name == gs.subjectName);
                  return ActionChip(
                    label: Text('${gs.subjectName} (${gs.subjectType})',
                        style: TextStyle(
                          fontSize: 12,
                          color: alreadyAdded
                              ? AppTheme.subtitleColor(context)
                              : _primaryLabelColor,
                          decoration:
                              alreadyAdded ? TextDecoration.lineThrough : null,
                        )),
                    avatar: Icon(alreadyAdded ? Icons.check : Icons.add,
                        size: 16,
                        color: alreadyAdded
                            ? AppTheme.subtitleColor(context)
                            : _primaryLabelColor),
                    backgroundColor: alreadyAdded
                        ? _disabledChipBackground
                        : _softFill(_wizardPrimary),
                    side: BorderSide(
                        color: alreadyAdded
                            ? AppTheme.borderColor(context)
                            : _wizardPrimary.withValues(alpha: 0.35)),
                    onPressed: alreadyAdded
                        ? null
                        : () {
                            setState(() {
                              _subjects.add(SubjectModel(
                                id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                                name: gs.subjectName,
                                facultyName: gs.assignedFacultyName.isNotEmpty
                                    ? gs.assignedFacultyName
                                    : 'TBA',
                                hoursPerWeek: gs.hoursPerWeek,
                                colorIndex: _subjects.length,
                                subjectType: gs.subjectType,
                              ));
                            });
                          },
                  );
                }).toList()),
          ]),
        ),
      ] else
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No subjects found. Go to Manage Subjects in the Admin Dashboard to add subjects first.',
                  style: TextStyle(fontSize: 12, color: AppTheme.subtitleColor(context)),
                ),
              ),
            ],
          ),
        ),
      ..._subjects.asMap().entries.map((e) => _subjectCard(e.key, e.value)),
      if (_subjects.isEmpty) _emptyCard('Tap a subject chip above to add it'),
    ]);
  }

  /// Edit only the faculty assignment, hours/week and type for an already-imported subject.
  void _editSubjectFacultyDialog(int index) {
    final editing = _subjects[index];
    final facultyCtrl = TextEditingController(text: editing.facultyName);
    int hours = editing.hoursPerWeek;
    String subjectType = editing.subjectType;

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDlg) => AlertDialog(
                  title: Text('Edit: ${editing.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // Faculty picker
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Assign Faculty:',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor(ctx))),
                    ),
                    const SizedBox(height: 6),
                    if (_dbFaculty.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _dbFaculty
                            .map((f) => ChoiceChip(
                                  label: Text(f.name,
                                      style: const TextStyle(fontSize: 12)),
                                  selected: facultyCtrl.text == f.name,
                                  onSelected: (_) =>
                                      setDlg(() => facultyCtrl.text = f.name),
                                  selectedColor: _wizardPrimary,
                                  backgroundColor: _chipBackground,
                                  checkmarkColor: Colors.white,
                                  side: _chipSide(facultyCtrl.text == f.name),
                                  labelStyle: _chipLabelStyle(
                                      facultyCtrl.text == f.name,
                                      fontSize: 12),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      )
                    else
                      TextField(
                        controller: facultyCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Faculty Name',
                            hintText: 'Enter faculty name'),
                      ),
                    const SizedBox(height: 16),
                    // Subject type
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Subject Type:',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor(ctx))),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['Theory', 'Lab', 'Tutorial']
                          .map((type) => ChoiceChip(
                                label: Text(type,
                                    style: const TextStyle(fontSize: 12)),
                                selected: subjectType == type,
                                onSelected: (_) =>
                                    setDlg(() => subjectType = type),
                                selectedColor: _wizardPrimary,
                                backgroundColor: _chipBackground,
                                checkmarkColor: Colors.white,
                                side: _chipSide(subjectType == type),
                                labelStyle: _chipLabelStyle(subjectType == type,
                                    fontSize: 12),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    // Hours slider
                    Text('Hours/week: $hours',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Slider(
                        value: hours.toDouble(),
                        min: 1,
                        max: (_workingDays * 2).toDouble(),
                        divisions: (_workingDays * 2 - 1).clamp(1, 100),
                        label: '$hours',
                        activeColor: _wizardPrimary,
                        onChanged: (v) => setDlg(() => hours = v.round())),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () {
                          if (facultyCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('Please assign a faculty')));
                            return;
                          }
                          setState(() {
                            _subjects[index] = SubjectModel(
                                id: editing.id,
                                name: editing.name,
                                facultyName: facultyCtrl.text.trim(),
                                hoursPerWeek: hours,
                                colorIndex: editing.colorIndex,
                                subjectType: subjectType);
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save')),
                  ],
                )));
  }

  Widget _subjectCard(int index, SubjectModel s) {
    final lightBg =
        AppTheme.subjectColors[s.colorIndex % AppTheme.subjectColors.length];
    final accent =
        AppTheme.subjectAccents[s.colorIndex % AppTheme.subjectAccents.length];
    final bg = _isDarkMode
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.18), AppTheme.cardColor(context))
        : lightBg;
    return Card(
        color: bg,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
            borderRadius: AppTheme.cardRadius,
            side: BorderSide(
                color: _isDarkMode
                    ? accent.withValues(alpha: 0.25)
                    : Colors.transparent)),
        child: ListTile(
          iconColor: AppTheme.subtitleColor(context),
          leading: CircleAvatar(
              backgroundColor: accent,
              child: Text(s.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          title: Text(s.name,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context))),
          subtitle: Text(
              '${s.facultyName} • ${s.hoursPerWeek} hrs/week • ${s.subjectType}',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.subtitleColor(context))),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit faculty / hours',
                onPressed: () => _editSubjectFacultyDialog(index)),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.error, size: 20),
                onPressed: () => setState(() => _subjects.removeAt(index))),
          ]),
        ));
  }

  // Step 3: Rooms
  Widget _buildStep3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Classrooms & Labs', Icons.meeting_room_outlined),
      // Import from existing DB rooms
      if (_dbRooms.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.auto_awesome, color: AppTheme.success, size: 18),
              SizedBox(width: 8),
              Text('Quick Import Rooms',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.success)),
            ]),
            const SizedBox(height: 8),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _dbRooms.map((dbR) {
                  final alreadyAdded =
                      _rooms.any((r) => r.roomId == dbR.roomId);
                  return ActionChip(
                    label:
                        Text('${dbR.roomId} (${dbR.roomType}, ${dbR.capacity})',
                            style: TextStyle(
                              fontSize: 12,
                              color: alreadyAdded
                                  ? AppTheme.subtitleColor(context)
                                  : _primaryLabelColor,
                              decoration: alreadyAdded
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                    avatar: Icon(alreadyAdded ? Icons.check : Icons.add,
                        size: 16,
                        color: alreadyAdded
                            ? AppTheme.subtitleColor(context)
                            : _primaryLabelColor),
                    backgroundColor: alreadyAdded
                        ? _disabledChipBackground
                        : _softFill(_wizardPrimary),
                    side: BorderSide(
                        color: alreadyAdded
                            ? AppTheme.borderColor(context)
                            : _wizardPrimary.withValues(alpha: 0.35)),
                    onPressed: alreadyAdded
                        ? null
                        : () {
                            setState(() {
                              _rooms.add(RoomModel(
                                id: 'room_${DateTime.now().millisecondsSinceEpoch}',
                                roomId: dbR.roomId,
                                capacity: dbR.capacity,
                                roomType: dbR.roomType,
                              ));
                            });
                          },
                  );
                }).toList()),
          ]),
        ),
      ],
      ..._rooms.map((r) => Card(
              child: ListTile(
            leading: CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.meeting_room,
                    color: Colors.white, size: 20)),
            title: Text(r.roomId,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${r.roomType} • Capacity: ${r.capacity}'),
            trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                onPressed: () => setState(() => _rooms.remove(r))),
          ))),
      if (_rooms.isEmpty) _emptyCard('No rooms added yet'),
      // Custom room addition removed per user request
    ]);
  }



  // Step 4: Faculty Availability
  Widget _buildStep4() {
    final faculties = _subjects.map((s) => s.facultyName).toSet();
    final infoColor =
        _isDarkMode ? const Color(0xFF93C5FD) : Colors.blue.shade700;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Faculty Availability', Icons.person_pin_outlined),
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: _softFill(infoColor, light: 0.1, dark: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: infoColor.withValues(alpha: 0.28))),
          child: Row(children: [
            Icon(Icons.info_outline, color: infoColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Skip = all faculty available all day',
                    style: TextStyle(fontSize: 13, color: infoColor)))
          ])),
      const SizedBox(height: 16),
      ...faculties.map((f) => _buildFacultyCard(f)),
      if (faculties.isEmpty)
        Text('Add subjects first',
            style: TextStyle(color: AppTheme.subtitleColor(context))),
    ]);
  }

  Widget _buildFacultyCard(String faculty) {
    FacultyAvailability avail =
        _availability.firstWhere((a) => a.facultyName == faculty, orElse: () {
      final fa = FacultyAvailability(
          facultyName: faculty,
          availableDays: List.generate(_workingDays, (i) => i),
          availableSlots: List.generate(_slotsPerDay, (i) => i));
      _availability.add(fa);
      return fa;
    });
    return Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    radius: 16,
                    child: Text(faculty[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14))),
                const SizedBox(width: 10),
                Text(faculty,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15))
              ]),
              const SizedBox(height: 12),
              const Text('Days:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Wrap(
                  spacing: 6,
                  children: List.generate(
                      _workingDays,
                      (d) => FilterChip(
                          label: Text(AppConst.dayLabel(d).substring(0, 3)),
                          selected: avail.availableDays.contains(d),
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                if (!avail.availableDays.contains(d)) {
                                  avail.availableDays.add(d);
                                }
                              } else {
                                avail.availableDays.remove(d);
                              }
                              avail.availableDays.sort();
                            });
                          },
                          backgroundColor: _chipBackground,
                          selectedColor: _softFill(_wizardPrimary,
                              light: 0.14, dark: 0.24),
                          checkmarkColor: _primaryLabelColor,
                          side: _chipSide(
                              avail.availableDays.contains(d), _wizardPrimary),
                          labelStyle: _softChipLabelStyle(
                              avail.availableDays.contains(d),
                              _wizardPrimary)))),
              const SizedBox(height: 10),
              const Text('Slots:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Wrap(
                  spacing: 6,
                  children: List.generate(
                      _slotsPerDay,
                      (s) => FilterChip(
                          label: Text('S${s + 1}'),
                          selected: avail.availableSlots.contains(s),
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                if (!avail.availableSlots.contains(s)) {
                                  avail.availableSlots.add(s);
                                }
                              } else {
                                avail.availableSlots.remove(s);
                              }
                              avail.availableSlots.sort();
                            });
                          },
                          backgroundColor: _chipBackground,
                          selectedColor: _softFill(AppTheme.success,
                              light: 0.14, dark: 0.24),
                          checkmarkColor: _isDarkMode
                              ? const Color(0xFF86EFAC)
                              : AppTheme.success,
                          side: _chipSide(avail.availableSlots.contains(s),
                              AppTheme.success),
                          labelStyle: _softChipLabelStyle(
                              avail.availableSlots.contains(s),
                              AppTheme.success)))),
            ])));
  }

  // Step 5: Review & Pre-flight Conflict Analysis
  Widget _buildStep5() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Review & Generate', Icons.check_circle_outline),
      _reviewItem('Class', _classNameCtrl.text.trim()),
      _reviewItem('Department', _departmentCtrl.text.trim()),
      _reviewItem('Semester', _semesterCtrl.text.trim()),
      _reviewItem('Working Days', '$_workingDays Days'),
      _reviewItem('Slots Per Day', '$_slotsPerDay Slots'),
      const Divider(height: 24),
      _reviewItem('Subjects', '${_subjects.length}'),
      _reviewItem('Rooms', '${_rooms.length}'),
      _reviewItem(
          'Faculty', '${_subjects.map((s) => s.facultyName).toSet().length}'),
      const SizedBox(height: 16),

      // Pre-flight info card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            _softFill(AppTheme.success, light: 0.1, dark: 0.12),
            _softFill(const Color(0xFF06B6D4), light: 0.06, dark: 0.08),
          ]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.shield_outlined, color: AppTheme.success, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Smart Conflict Avoidance',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _isDarkMode
                            ? const Color(0xFF86EFAC)
                            : AppTheme.success))),
          ]),
          const SizedBox(height: 8),
          Text('The engine will automatically:',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.subtitleColor(context))),
          const SizedBox(height: 6),
          _checkItem('Check faculty schedules across ALL timetables'),
          _checkItem('Verify room availability globally'),
          _checkItem('Enforce max lectures per day per faculty'),
          _checkItem('Distribute subjects evenly across days'),
        ]),
      ),

      const SizedBox(height: 20),
      SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateAndNavigate,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bolt),
              label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Timetable',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18)))),
    ]);
  }

  Widget _checkItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(Icons.check_circle,
              size: 14,
              color: _isDarkMode ? const Color(0xFF86EFAC) : AppTheme.success),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.subtitleColor(context)))),
        ]),
      );

  Widget _reviewItem(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text('$label: ',
            style: TextStyle(color: AppTheme.subtitleColor(context))),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context)))
      ]));

  Widget _sectionHeader(String title, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _softFill(_wizardPrimary, light: 0.1, dark: 0.16),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _primaryLabelColor, size: 22)),
        const SizedBox(width: 12),
        Text(title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context))),
      ]));

  Widget _emptyCard(String text) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF17192B) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor(context))),
      child: Center(
          child: Text(text,
              style: TextStyle(color: AppTheme.subtitleColor(context)))));

  Widget _buildNavButtons() {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            border: Border(
                top: BorderSide(
                    color: AppTheme.borderColor(context)
                        .withValues(alpha: _isDarkMode ? 0.8 : 1))),
            boxShadow: _isDarkMode
                ? []
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4))
                  ]),
        child: Row(children: [
          if (_step > 1)
            Expanded(
                child: OutlinedButton(
                    onPressed: _prev, child: const Text('← Back'))),
          if (_step > 1) const SizedBox(width: 12),
          if (_step < _totalSteps)
            Expanded(
                flex: 2,
                child: ElevatedButton(
                    onPressed: _next,
                    child: Text(_step == 4 ? 'Review →' : 'Next →'))),
        ]));
  }

  void _showResetDialog() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Reset?'),
                content: const Text('Clear all data?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _step = 1;
                          _classNameCtrl.clear();
                          _departmentCtrl.clear();
                          _semesterCtrl.clear();
                          _workingDays = 5;
                          _slotsPerDay = 6;
                          _subjects.clear();
                          _rooms.clear();
                          _availability.clear();
                          _generateDefaultSlots();
                        });
                      },
                      child: const Text('Reset')),
                ]));
  }
}
