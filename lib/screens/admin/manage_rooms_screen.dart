import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class ManageRoomsScreen extends StatefulWidget {
  final UserModel user;
  const ManageRoomsScreen({super.key, required this.user});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return CampusScaffold(
      title: 'Classrooms & Labs',
      subtitle: 'Track rooms, labs, halls, and capacity for scheduling.',
      icon: Icons.meeting_room_rounded,
      body: StreamBuilder<List<RoomModel>>(
        stream: _supabaseService.getRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.meeting_room,
              title: 'No Classrooms',
              subtitle: 'Add classrooms, labs, and seminar halls.',
              actionLabel: 'Add Room',
              onAction: () => _showRoomDialog(),
            );
          }

          // Group by type
          final classrooms =
              rooms.where((r) => r.roomType == 'Classroom').toList();
          final labs = rooms.where((r) => r.roomType == 'Lab').toList();
          final others = rooms
              .where((r) => r.roomType != 'Classroom' && r.roomType != 'Lab')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                Row(children: [
                  Expanded(
                      child: _summaryCard('Classrooms', classrooms.length,
                          Icons.class_, AppTheme.primary, isDark)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _summaryCard('Labs', labs.length, Icons.science,
                          AppTheme.warning, isDark)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _summaryCard('Others', others.length, Icons.room,
                          AppTheme.success, isDark)),
                ]),
                const SizedBox(height: 20),
                ...rooms.map((r) => _buildRoomCard(r, isDark)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoomDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
      ),
    );
  }

  Widget _summaryCard(
      String label, int count, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text('$count',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: AppTheme.subtitleColor(context))),
      ]),
    );
  }

  Widget _buildRoomCard(RoomModel r, bool isDark) {
    final typeColor = r.roomType == 'Lab'
        ? AppTheme.warning
        : r.roomType == 'Seminar Hall'
            ? AppTheme.success
            : AppTheme.primary;
    final typeIcon = r.roomType == 'Lab'
        ? Icons.science
        : r.roomType == 'Seminar Hall'
            ? Icons.groups
            : Icons.meeting_room;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: AppTheme.adaptiveShadow(context),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: typeColor.withValues(alpha: isDark ? 0.2 : 0.12),
          child: Icon(typeIcon, color: typeColor, size: 22),
        ),
        title: Text(r.roomId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Capacity: ${r.capacity}',
                  style: TextStyle(
                      color: AppTheme.subtitleColor(context), fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(r.roomType,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: typeColor)),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary),
              onPressed: () => _showRoomDialog(room: r),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.error),
              onPressed: () => _confirmDelete(r),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDialog({RoomModel? room}) {
    final nameCtrl = TextEditingController(text: room?.roomId ?? '');
    final capCtrl = TextEditingController(
        text: room != null ? room.capacity.toString() : '40');
    String selectedType = room?.roomType ?? 'Classroom';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(room == null ? 'Add Room' : 'Edit Room'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Room Name *',
                    hintText: 'e.g. Room 101',
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Capacity *',
                    hintText: 'e.g. 60',
                    prefixIcon: Icon(Icons.people),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Room Type:',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    children: ['Classroom', 'Lab', 'Seminar Hall']
                        .map((t) => ChoiceChip(
                              label: Text(t),
                              selected: selectedType == t,
                              onSelected: (_) => setDlg(() => selectedType = t),
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                  color: selectedType == t
                                      ? Colors.white
                                      : AppTheme.textColor(context),
                                  fontWeight: FontWeight.w600),
                            ))
                        .toList()),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    capCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                final newRoom = RoomModel(
                  id: room?.id ??
                      'room_${DateTime.now().millisecondsSinceEpoch}',
                  roomId: nameCtrl.text.trim(),
                  capacity: int.parse(capCtrl.text.trim()),
                  roomType: selectedType,
                );
                try {
                  final warning = await _supabaseService.saveRoom(newRoom);
                  if (!mounted) return;
                  if (warning != null) {
                    // Room was saved but schema is missing room_type column — show amber warning
                    showAppSnackBar(context, warning, isError: true);
                  } else {
                    showAppSnackBar(
                        context, '${newRoom.roomType} saved successfully!');
                  }
                } catch (e) {
                  if (mounted) {
                    showAppSnackBar(
                      context,
                      e.toString().replaceFirst('Exception: ', ''),
                      isError: true,
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(RoomModel room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete ${room.roomId}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              await _supabaseService.deleteRoom(room.id);
              if (mounted) {
                Navigator.pop(ctx);
                showAppSnackBar(context, 'Room deleted!');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
