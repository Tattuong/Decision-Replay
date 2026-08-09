import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/note_entry.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/dr_design.dart';
import '../notes/note_editor_screen.dart';

enum _TypeFilter { all, text, checklist, photo, voice }

String _formatDuration(int sec) {
  final m = sec ~/ 60;
  final s = sec % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  _TypeFilter _typeFilter = _TypeFilter.all;
  String? _labelFilter;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  NoteType? get _noteType {
    return switch (_typeFilter) {
      _TypeFilter.text => NoteType.text,
      _TypeFilter.checklist => NoteType.checklist,
      _TypeFilter.photo => NoteType.photo,
      _TypeFilter.voice => NoteType.voice,
      _ => null,
    };
  }

  bool get _hasActiveFilters =>
      _query.trim().isNotEmpty || _typeFilter != _TypeFilter.all || _labelFilter != null;

  void _openNote(NoteEntry note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProv = context.watch<NotesProvider>();
    final results = notesProv.filtered(
      query: _query,
      labelId: _labelFilter,
      type: _noteType,
    );

    return DrScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrPageHeader(
              subtitle: AppStrings.t(context, 'appName'),
              title: AppStrings.t(context, 'search'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _SearchBar(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                hint: AppStrings.t(context, 'searchHint'),
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  DrFilterChip(
                    label: AppStrings.t(context, 'allTypes'),
                    selected: _typeFilter == _TypeFilter.all,
                    onTap: () => setState(() => _typeFilter = _TypeFilter.all),
                  ),
                  DrFilterChip(
                    label: AppStrings.t(context, 'filterNotes'),
                    selected: _typeFilter == _TypeFilter.text,
                    onTap: () => setState(() => _typeFilter = _TypeFilter.text),
                  ),
                  DrFilterChip(
                    label: AppStrings.t(context, 'filterChecklists'),
                    selected: _typeFilter == _TypeFilter.checklist,
                    onTap: () => setState(() => _typeFilter = _TypeFilter.checklist),
                  ),
                  DrFilterChip(
                    label: AppStrings.t(context, 'filterPhotos'),
                    selected: _typeFilter == _TypeFilter.photo,
                    onTap: () => setState(() => _typeFilter = _TypeFilter.photo),
                  ),
                  DrFilterChip(
                    label: AppStrings.t(context, 'filterVoice'),
                    selected: _typeFilter == _TypeFilter.voice,
                    onTap: () => setState(() => _typeFilter = _TypeFilter.voice),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  if (_hasActiveFilters) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                        child: Text(
                          AppStrings.t(context, 'resultsCount').replaceAll('{count}', '${results.length}'),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (results.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: DrEmptyState(
                          icon: Icons.search_off_rounded,
                          message: AppStrings.t(context, 'noSearchResults'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        sliver: SliverList.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _SearchResultCard(
                            note: results[i],
                            query: _query,
                            label: notesProv.labelFor(results[i].labelId),
                            onTap: () => _openNote(results[i]),
                          ),
                        ),
                      ),
                  ],
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, _hasActiveFilters ? 16 : 4, 20, 10),
                      child: Text(
                        AppStrings.t(context, 'browseLabels'),
                        style: AppTypography.titleLarge(color: AppColors.textPrimary).copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 52,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final labels = notesProv.labels;
                          final total = labels.length + 1;
                          if (i >= total) return null;

                          if (i < labels.length) {
                            final label = labels[i];
                            return _LabelBrowseTile(
                              name: label.name,
                              count: notesProv.countForLabel(label.id),
                              color: NotePalette.labelColors[label.colorIndex % NotePalette.labelColors.length],
                              selected: _labelFilter == label.id,
                              onTap: () => setState(() {
                                _labelFilter = _labelFilter == label.id ? null : label.id;
                              }),
                            );
                          }

                          return _LabelBrowseTile(
                            name: AppStrings.t(context, 'unlabelled'),
                            count: notesProv.countForLabel('unlabelled'),
                            color: AppColors.textMuted,
                            selected: _labelFilter == 'unlabelled',
                            onTap: () => setState(() {
                              _labelFilter = _labelFilter == 'unlabelled' ? null : 'unlabelled';
                            }),
                          );
                        },
                        childCount: notesProv.labels.length + 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.border,
          width: focused ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: focused
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: focused ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(Icons.search_rounded, color: focused ? AppColors.primary : AppColors.textMuted),
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final NoteEntry note;
  final String query;
  final NoteLabel? label;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.note,
    required this.query,
    this.label,
    required this.onTap,
  });

  Color get _bgColor => switch (note.type) {
        NoteType.voice => const Color(0xFFE8F5E9),
        NoteType.checklist => const Color(0xFFF3E5F5),
        NoteType.photo => const Color(0xFFFFF3E0),
        _ => AppColors.surface,
      };

  Color get _iconColor => switch (note.type) {
        NoteType.voice => const Color(0xFF43A047),
        NoteType.checklist => const Color(0xFF9C27B0),
        NoteType.photo => const Color(0xFFF57C00),
        _ => AppColors.textPrimary,
      };

  IconData get _icon => switch (note.type) {
        NoteType.checklist => Icons.checklist_rounded,
        NoteType.photo => Icons.photo_outlined,
        NoteType.voice => Icons.graphic_eq_rounded,
        _ => Icons.description_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final borderColor = note.type == NoteType.text ? AppColors.border : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                      ),
                      child: note.type == NoteType.photo && note.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(File(note.imagePath!), fit: BoxFit.cover),
                            )
                          : Icon(_icon, color: _iconColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _HighlightedText(
                                  text: note.displayTitle,
                                  query: query,
                                  style: AppTypography.titleLarge(color: AppColors.textPrimary).copyWith(fontSize: 15),
                                ),
                              ),
                              if (note.type == NoteType.voice && note.voiceDurationSec > 0)
                                Text(
                                  _formatDuration(note.voiceDurationSec),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (note.type == NoteType.voice)
                            _WaveformPreview(color: _iconColor.withValues(alpha: 0.55))
                          else if (note.type == NoteType.checklist)
                            ...note.checklist.where((c) => c.text.trim().isNotEmpty).take(2).map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item.checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                          size: 16,
                                          color: item.checked ? AppColors.success : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _HighlightedText(
                                            text: item.text,
                                            query: query,
                                            maxLines: 1,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                          else if (note.body.trim().isNotEmpty)
                            _HighlightedText(
                              text: note.body.trim(),
                              query: query,
                              maxLines: 2,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (label != null) ...[
                  const SizedBox(height: 10),
                  _LabelChip(
                    name: label!.name,
                    color: NotePalette.labelColors[label!.colorIndex % NotePalette.labelColors.length],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveformPreview extends StatelessWidget {
  final Color color;

  const _WaveformPreview({required this.color});

  @override
  Widget build(BuildContext context) {
    const heights = [0.35, 0.55, 0.8, 0.45, 0.65, 0.9, 0.5, 0.7, 0.4, 0.75, 0.55, 0.85];
    return SizedBox(
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in heights)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Container(
                width: 3,
                height: 22 * h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String name;
  final Color color;

  const _LabelChip({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LabelBrowseTile extends StatelessWidget {
  final String name;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _LabelBrowseTile({
    required this.name,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final int maxLines;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    if (q.isEmpty) {
      return Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: style);
    }

    final lower = text.toLowerCase();
    final needle = q.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final i = lower.indexOf(needle, start);
      if (i < 0) {
        if (start < text.length) spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (i > start) spans.add(TextSpan(text: text.substring(start, i), style: style));
      spans.add(
        TextSpan(
          text: text.substring(i, i + needle.length),
          style: style.copyWith(
            backgroundColor: const Color(0xFFFFF176),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = i + needle.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}
