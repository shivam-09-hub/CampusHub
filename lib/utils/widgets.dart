import 'package:flutter/material.dart';
import 'app_constants.dart';
import '../models/models.dart';

// ─── Progress Step Indicator ───────────────────────────────────────────────────

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const StepProgressIndicator(
      {super.key, required this.currentStep, required this.totalSteps}) ;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $currentStep of $totalSteps',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '${((currentStep / totalSteps) * 100).round()}% complete',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: currentStep / totalSteps,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Big Action Button ─────────────────────────────────────────────────────────

class BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  const BigButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper Text ──────────────────────────────────────────────────────────────

class HelperText extends StatelessWidget {
  final String text;
  const HelperText(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12, left: 4),
        child: Text(text,
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      );
}

// ─── Subject Card ─────────────────────────────────────────────────────────────

class SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SubjectCard(
      {super.key,
      required this.subject,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.subjectColors[
        subject.colorIndex % AppColors.subjectColors.length];
    final accent = AppColors.subjectAccents[
        subject.colorIndex % AppColors.subjectAccents.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: bg,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: accent,
          child: Text(
            subject.name.isNotEmpty ? subject.name[0].toUpperCase() : 'S',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(subject.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 ${subject.facultyName}',
                style: const TextStyle(fontSize: 13)),
            Text('🕒 ${subject.hoursPerWeek} hrs/week',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueGrey),
              onPressed: onEdit,
              tooltip: 'Edit subject',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
              tooltip: 'Delete subject',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Room Card ────────────────────────────────────────────────────────────────

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onDelete;

  const RoomCard(
      {super.key, required this.room, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF4A6CF7),
          child: Icon(Icons.meeting_room, color: Colors.white, size: 20),
        ),
        title: Text(room.roomId,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Capacity: ${room.capacity} students'),
        trailing: IconButton(
          icon:
              const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

// ─── Drag Data ────────────────────────────────────────────────────────────────
// Carries the source cell's coordinates when user drags a lecture card.

class DragData {
  final int fromDay;
  final int fromSlot;
  const DragData({required this.fromDay, required this.fromSlot});
}

// ─── Timetable Entry Cell ─────────────────────────────────────────────────────
// Now supports drag-and-drop: it is both a Draggable (source) and a
// DragTarget (drop destination).  Callbacks are optional so the widget can
// still be used in read-only contexts (e.g. Day View).

class TimetableEntryCell extends StatefulWidget {
  final TimetableEntry entry;
  final int colorIndex;

  // Drag-and-drop callbacks — null means drag/drop is disabled for this cell.
  final void Function(int fromDay, int fromSlot, int toDay, int toSlot)?
      onSwap;

  const TimetableEntryCell({
    super.key,
    required this.entry,
    required this.colorIndex,
    this.onSwap,
  });

  @override
  State<TimetableEntryCell> createState() => _TimetableEntryCellState();
}

class _TimetableEntryCellState extends State<TimetableEntryCell> {
  // Turns true when another card is hovering over this cell.
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg =
        AppColors.subjectColors[widget.colorIndex % AppColors.subjectColors.length];
    final accent =
        AppColors.subjectAccents[widget.colorIndex % AppColors.subjectAccents.length];

    // The visual card content — same as before.
    Widget cellContent = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        // Highlight in blue when a card is being dragged on top of this cell.
        color: _isHovered ? Colors.blue.shade100 : bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isHovered
              ? Colors.blue.shade400
              : accent.withOpacity(0.4),
          width: _isHovered ? 2 : 1,
        ),
        boxShadow: _isHovered
            ? [BoxShadow(color: Colors.blue.shade200, blurRadius: 6)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Small drag-handle icon so beginners know it is draggable.
          if (widget.onSwap != null)
            Icon(Icons.drag_indicator,
                size: 12, color: accent.withOpacity(0.6)),
          Text(
            widget.entry.subjectName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 11, color: accent),
          ),
          const SizedBox(height: 2),
          Text(
            widget.entry.facultyName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          Text(
            '[${widget.entry.roomId}]',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 9, color: Colors.black45, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );

    // If drag/drop is not enabled, return plain content.
    if (widget.onSwap == null) return cellContent;

    // ── Make this cell a DRAG SOURCE ─────────────────────────────────────────
    // Draggable wraps the cell; data carries the source coordinates.
    Widget draggable = Draggable<DragData>(
      data: DragData(
          fromDay: widget.entry.day, fromSlot: widget.entry.slot),
      // The card shown under the user's finger while dragging.
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: 106,
            height: 76,
            child: cellContent,
          ),
        ),
      ),
      // The "ghost" left in the original spot while dragging.
      childWhenDragging: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Colors.grey.shade400, style: BorderStyle.solid, width: 1),
        ),
        child: Center(
          child: Icon(Icons.swap_horiz, color: Colors.grey.shade400, size: 20),
        ),
      ),
      child: cellContent,
    );

    // ── Make this cell a DROP TARGET ─────────────────────────────────────────
    // DragTarget listens for a DragData drop and fires onSwap.
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) {
        // Accept any card that is NOT from this exact cell.
        final data = details.data;
        final isSelf =
            data.fromDay == widget.entry.day && data.fromSlot == widget.entry.slot;
        if (!isSelf) setState(() => _isHovered = true);
        return !isSelf;
      },
      onLeave: (_) => setState(() => _isHovered = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHovered = false);
        final data = details.data;
        widget.onSwap!(
            data.fromDay, data.fromSlot, widget.entry.day, widget.entry.slot);
      },
      builder: (ctx, candidateData, rejectedData) => draggable,
    );
  }
}

// ─── Empty Slot Cell ──────────────────────────────────────────────────────────
// Also acts as a DragTarget so users can drag a lecture into an empty slot
// (moves it rather than swapping).

class EmptySlotCell extends StatefulWidget {
  final int day;
  final int slot;

  // Called when a card is dropped onto this empty cell.
  final void Function(int fromDay, int fromSlot, int toDay, int toSlot)?
      onSwap;

  const EmptySlotCell({
    super.key,
    this.day = -1,
    this.slot = -1,
    this.onSwap,
  });

  @override
  State<EmptySlotCell> createState() => _EmptySlotCellState();
}

class _EmptySlotCellState extends State<EmptySlotCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _isHovered ? Colors.green.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: _isHovered
            ? Border.all(color: Colors.green.shade400, width: 2)
            : null,
      ),
      child: Center(
        child: _isHovered
            ? Icon(Icons.add_circle_outline,
                color: Colors.green.shade500, size: 22)
            : Text('—',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
      ),
    );

    // No drag/drop if coordinates are not provided.
    if (widget.onSwap == null || widget.day == -1) return content;

    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHovered = true);
        return true;
      },
      onLeave: (_) => setState(() => _isHovered = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHovered = false);
        final data = details.data;
        widget.onSwap!(data.fromDay, data.fromSlot, widget.day, widget.slot);
      },
      builder: (ctx, _, __) => content,
    );
  }
}
