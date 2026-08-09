import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/note_entry.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/dr_design.dart';
import '../notes/create_note_sheet.dart';
import '../notes/note_editor_screen.dart';

enum _TaskTab { today, upcoming, completed }

class _FlatTask {
  final NoteEntry note;
  final ChecklistItem item;

  const _FlatTask({required this.note, required this.item});
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskTab _tab = _TaskTab.today;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  DateTime get _today => DateTime.now();
  bool get _isSelectedToday => _sameDay(_selectedDay, _today);

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> get _weekDays {
    final weekday = _selectedDay.weekday;
    final monday = _selectedDay.subtract(Duration(days: weekday - 1));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  List<_FlatTask> _flatten(List<NoteEntry> notes) {
    final tasks = <_FlatTask>[];
    for (final note in notes) {
      for (final item in note.checklist) {
        if (item.text.trim().isEmpty) continue;
        tasks.add(_FlatTask(note: note, item: item));
      }
    }
    return tasks;
  }

  List<_FlatTask> _filtered(List<_FlatTask> all) {
    return switch (_tab) {
      _TaskTab.today => all.where((t) => _sameDay(t.note.updatedAt, _selectedDay)).toList(),
      _TaskTab.upcoming => all.where((t) {
          if (t.item.checked) return false;
          final noteDay = DateTime(t.note.updatedAt.year, t.note.updatedAt.month, t.note.updatedAt.day);
          return noteDay.isAfter(_selectedDay);
        }).toList(),
      _TaskTab.completed => all.where((t) => t.item.checked).toList(),
    };
  }

  Future<void> _toggleTask(_FlatTask task) async {
    final note = task.note;
    final items = note.checklist
        .map((c) => c.id == task.item.id ? c.copyWith(checked: !c.checked) : c)
        .toList();
    await context.read<NotesProvider>().saveNote(note.copyWith(checklist: items, updatedAt: DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final notesProv = context.watch<NotesProvider>();
    final all = _flatten(notesProv.checklistNotes());
    final tasks = _filtered(all);
    final pending = tasks.where((t) => !t.item.checked).toList();
    final done = tasks.where((t) => t.item.checked).toList();

    return DrScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.t(context, 'tasks'),
                      style: AppTypography.titleLarge(color: AppColors.textPrimary).copyWith(fontSize: 28, letterSpacing: -0.6),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    onPressed: () => CreateNoteSheet.show(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _WeekStrip(
              days: _weekDays,
              selected: _selectedDay,
              onSelect: (d) => setState(() => _selectedDay = d),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TaskTabBar(
                tab: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: all.isEmpty
                  ? DrEmptyState(
                      icon: Icons.checklist_rtl_rounded,
                      message: AppStrings.t(context, 'noTasks'),
                      action: AppStrings.t(context, 'createNew'),
                      onAction: () => CreateNoteSheet.show(context),
                    )
                  : tasks.isEmpty
                      ? DrEmptyState(
                          icon: Icons.event_available_outlined,
                          message: AppStrings.t(context, 'noTasksToday'),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          children: [
                            if (_tab == _TaskTab.today) ...[
                              if (pending.isNotEmpty) ...[
                                _SectionHeader(
                                  title: _isSelectedToday
                                      ? '${AppStrings.t(context, 'today')} • ${AppStrings.t(context, 'tasksCount', {'count': pending.length.toString()})}'
                                      : _formatSectionDate(_selectedDay),
                                  accent: AppColors.primary,
                                ),
                                _TaskGroup(
                                  tasks: pending,
                                  notesProv: notesProv,
                                  onToggle: _toggleTask,
                                  onOpen: (note) => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)),
                                  ),
                                ),
                              ],
                              if (done.isNotEmpty) ...[
                                if (pending.isNotEmpty) const SizedBox(height: 16),
                                _SectionHeader(
                                  title: AppStrings.t(context, 'done'),
                                  accent: AppColors.textSecondary,
                                ),
                                _TaskGroup(
                                  tasks: done,
                                  notesProv: notesProv,
                                  onToggle: _toggleTask,
                                  onOpen: (note) => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)),
                                  ),
                                ),
                              ],
                            ] else if (_tab == _TaskTab.upcoming && pending.isNotEmpty) ...[
                              _SectionHeader(
                                title: AppStrings.t(context, 'upcoming'),
                                accent: AppColors.primary,
                              ),
                              _TaskGroup(
                                tasks: pending,
                                notesProv: notesProv,
                                onToggle: _toggleTask,
                                onOpen: (note) => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)),
                                ),
                              ),
                            ] else if (_tab == _TaskTab.completed && done.isNotEmpty) ...[
                              _SectionHeader(
                                title: AppStrings.t(context, 'completedTab'),
                                accent: AppColors.textSecondary,
                              ),
                              _TaskGroup(
                                tasks: done,
                                notesProv: notesProv,
                                onToggle: _toggleTask,
                                onOpen: (note) => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)),
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSectionDate(DateTime d) {
    if (_sameDay(d, _today)) return AppStrings.t(context, 'today');
    return DateFormat('EEE, MMM d').format(d);
  }
}

class _WeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const _WeekStrip({required this.days, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final d = days[i];
          final active = d.year == selected.year && d.month == selected.month && d.day == selected.day;
          return GestureDetector(
            onTap: () => onSelect(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              decoration: BoxDecoration(
                color: active ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(d).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.primary : AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.primary : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM').format(d).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskTabBar extends StatelessWidget {
  final _TaskTab tab;
  final ValueChanged<_TaskTab> onChanged;

  const _TaskTabBar({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tabChip(context, _TaskTab.today, AppStrings.t(context, 'today')),
          _tabChip(context, _TaskTab.upcoming, AppStrings.t(context, 'upcoming')),
          _tabChip(context, _TaskTab.completed, AppStrings.t(context, 'completedTab')),
        ],
      ),
    );
  }

  Widget _tabChip(BuildContext context, _TaskTab value, String label) {
    final active = tab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color accent;

  const _SectionHeader({required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          color: accent,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TaskGroup extends StatelessWidget {
  final List<_FlatTask> tasks;
  final NotesProvider notesProv;
  final Future<void> Function(_FlatTask) onToggle;
  final void Function(NoteEntry) onOpen;

  const _TaskGroup({
    required this.tasks,
    required this.notesProv,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < tasks.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.border.withValues(alpha: 0.8), indent: 52),
            _TaskRow(
              task: tasks[i],
              label: notesProv.labelFor(tasks[i].note.labelId),
              onToggle: () => onToggle(tasks[i]),
              onOpen: () => onOpen(tasks[i].note),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final _FlatTask task;
  final NoteLabel? label;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  const _TaskRow({
    required this.task,
    required this.label,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final checked = task.item.checked;
    final time = DateFormat('h:mm a').format(task.note.updatedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: checked ? AppColors.primaryGradient : null,
                      color: checked ? null : Colors.transparent,
                      border: Border.all(
                        color: checked ? Colors.transparent : AppColors.textMuted,
                        width: 1.5,
                      ),
                    ),
                    child: checked ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.item.text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: checked ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: checked ? TextDecoration.lineThrough : null,
                        height: 1.3,
                      ),
                    ),
                    if (label != null) ...[
                      const SizedBox(height: 6),
                      _LabelChip(label: label!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final NoteLabel label;

  const _LabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final gradient = NotePalette.labelGradient(label.colorIndex);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradient.colors.first.withValues(alpha: 0.18), gradient.colors.last.withValues(alpha: 0.12)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.name,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
    );
  }
}
