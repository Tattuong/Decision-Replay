import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/app_theme_preset.dart';
import '../models/note_entry.dart';
import '../providers/shop_provider.dart';
import 'app_ui.dart';

class DrBackground extends StatelessWidget {
  final Widget child;

  const DrBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bg = context.select<ShopProvider, AppBackground>((s) => s.activeBackground);
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(decoration: BoxDecoration(gradient: bg.gradient)),
        Positioned(top: -80, right: -60, child: _orb(200, AppColors.primary.withValues(alpha: 0.05))),
        Positioned(bottom: 120, left: -80, child: _orb(160, AppColors.accent.withValues(alpha: 0.04))),
        child,
      ],
    );
  }

  Widget _orb(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class DrScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  const DrScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      backgroundColor: AppColors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: DrBackground(child: body),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Hero header: greeting + title + optional trailing (coins).
class DrPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const DrPageHeader({super.key, required this.title, this.subtitle, this.trailing});

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle ?? greeting(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.titleLarge(color: AppColors.textPrimary).copyWith(fontSize: 26, height: 1.15),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class DrFab extends StatelessWidget {
  final VoidCallback onPressed;

  const DrFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class DrEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  const DrEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onAction,
                child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DrNoteCard extends StatelessWidget {
  final NoteEntry note;
  final NoteLabel? label;
  final VoidCallback onTap;
  final VoidCallback? onPin;

  const DrNoteCard({super.key, required this.note, this.label, required this.onTap, this.onPin});

  bool get _hasTitle => note.title.trim().isNotEmpty;

  List<ChecklistItem> get _visibleChecklist =>
      note.checklist.where((c) => c.text.trim().isNotEmpty).take(6).toList();

  @override
  Widget build(BuildContext context) {
    final hasImage = note.imagePath != null;
    final isWhite = note.colorIndex % NotePalette.cardColors.length == 0;
    final skin = context.select<ShopProvider, CardStyle>((s) => s.activeCardStyle);
    final radius = skin.borderRadius;
    final borderColor = skin.borderWidth > 0
        ? skin.borderColor
        : Colors.black.withValues(alpha: isWhite ? 0.08 : 0.05);
    final borderWidth = skin.borderWidth > 0 ? skin.borderWidth : 1.0;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(
            gradient: NotePalette.cardGradient(note.colorIndex),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(color: NotePalette.cardColor(note.colorIndex).withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.file(
                          File(note.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (note.type == NoteType.checklist) ...[
                          if (_hasTitle)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, right: 20),
                              child: Text(
                                note.title.trim(),
                                style: AppTypography.titleLarge(color: AppColors.textPrimary).copyWith(fontSize: 15),
                              ),
                            ),
                          if (_visibleChecklist.isEmpty)
                            Text(
                              'Empty checklist',
                              style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.9), fontSize: 13),
                            )
                          else
                            ..._visibleChecklist.map(_checklistRow),
                        ] else ...[
                          if (_hasTitle)
                            Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: Text(
                                note.title.trim(),
                                style: AppTypography.titleLarge(color: AppColors.textPrimary).copyWith(fontSize: 15),
                              ),
                            ),
                          if (note.body.trim().isNotEmpty) ...[
                            if (_hasTitle) const SizedBox(height: 6),
                            Text(
                              note.body.trim(),
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                height: 1.45,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ] else if (!_hasTitle)
                            Text(
                              note.displayTitle,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.45),
                            ),
                        ],
                        if (note.type == NoteType.voice && note.voicePath != null) ...[
                          const SizedBox(height: 10),
                          _VoiceChip(durationSec: note.voiceDurationSec),
                        ],
                        if (label != null) ...[
                          const SizedBox(height: 10),
                          _labelPill(label!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (note.pinned)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.push_pin_rounded, size: 15, color: AppColors.textPrimary.withValues(alpha: 0.45)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checklistRow(ChecklistItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              item.checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 17,
              color: item.checked ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.text.trim(),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.35,
                decoration: item.checked ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelPill(NoteLabel label) {
    final c = NotePalette.labelColors[label.colorIndex % NotePalette.labelColors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.name,
        style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _VoiceChip extends StatelessWidget {
  final int durationSec;

  const _VoiceChip({required this.durationSec});

  @override
  Widget build(BuildContext context) {
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.textPrimary.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            durationSec > 0 ? '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' : 'Voice',
            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Two-column masonry layout (Google Keep style).
class DrMasonryGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const DrMasonryGrid({super.key, required this.children, this.spacing = 10});

  @override
  Widget build(BuildContext context) {
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final child = Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: children[i],
      );
      if (i.isEven) {
        left.add(child);
      } else {
        right.add(child);
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: left)),
        SizedBox(width: spacing),
        Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: right)),
      ],
    );
  }
}

/// Compact notes header — title + actions only (no duplicate search/note bars).
class DrNotesHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onSearch;

  const DrNotesHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleLarge(color: AppColors.textPrimary).copyWith(
                fontSize: 24,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ),
          if (onSearch != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 24),
              onPressed: onSearch,
            ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

@Deprecated('Use DrNotesHeader')
class DrNotesTopBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onSearch;

  const DrNotesTopBar({
    super.key,
    required this.title,
    this.trailing,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return DrNotesHeader(title: title, trailing: trailing, onSearch: onSearch);
  }
}

class DrTaskCard extends StatelessWidget {
  final NoteEntry note;
  final VoidCallback onTap;

  const DrTaskCard({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = note.checklist.where((c) => c.checked).length;
    final total = note.checklist.length;
    final progress = total > 0 ? done / total : 0.0;
    final complete = progress >= 1.0;
    final nextTask = note.checklist.where((c) => !c.checked && c.text.trim().isNotEmpty).map((c) => c.text).firstOrNull;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: total > 0 ? progress : 0,
                        strokeWidth: 3.5,
                        backgroundColor: AppColors.surfaceVariant,
                        color: complete ? AppColors.success : AppColors.primary,
                      ),
                      Text(
                        total > 0 ? '${(progress * 100).round()}%' : '—',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: complete ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleLarge(color: AppColors.textPrimary).copyWith(fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: complete
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$done/$total',
                              style: TextStyle(
                                color: complete ? AppColors.success : AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (nextTask != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          nextTask,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: total > 0 ? progress : 0,
                          minHeight: 5,
                          backgroundColor: AppColors.surfaceVariant,
                          color: complete ? AppColors.success : AppColors.primary,
                        ),
                      ),
                      if (note.checklist.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...note.checklist.take(3).map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      size: 16,
                                      color: item.checked ? AppColors.success : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.text.trim().isEmpty ? 'Empty task' : item.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: item.checked ? AppColors.textMuted : AppColors.textSecondary,
                                          decoration: item.checked ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DrBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const DrBottomNav({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SafeArea(
        top: false,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _item(Icons.sticky_note_2_rounded, Icons.sticky_note_2_outlined, 0, 'Notes'),
              _item(Icons.check_circle_rounded, Icons.check_circle_outline, 1, 'Tasks'),
              _item(Icons.search_rounded, Icons.search, 2, 'Search'),
              _item(Icons.settings_rounded, Icons.settings_outlined, 3, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData activeIcon, IconData icon, int i, String label) {
    final active = index == i;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(i),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(active ? activeIcon : icon, color: active ? AppColors.primary : AppColors.textMuted, size: 21),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DrFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool vipStyle;

  const DrFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.vipStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: selected && vipStyle ? AppColors.vipGoldGradient : null,
            color: selected && !vipStyle ? AppColors.textPrimary : selected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? (vipStyle ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : AppColors.textPrimary)
                  : AppColors.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: (vipStyle ? const Color(0xFFF59E0B) : Colors.black).withValues(alpha: vipStyle ? 0.25 : 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? (vipStyle ? AppColors.trueBlack : Colors.white) : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class DrSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const DrSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        autofocus: autofocus,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class DrSettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const DrSettingsSection({super.key, required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

class DrSettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Widget? trailing;
  final bool showDivider;
  final bool locked;
  final VoidCallback onTap;

  const DrSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.trailing,
    this.showDivider = true,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.25),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else if (locked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.coin.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 12, color: AppColors.coin),
                          SizedBox(width: 4),
                          Text('Shop', style: TextStyle(color: AppColors.coin, fontSize: 11, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    )
                  else
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
                ],
              ),
            ),
            if (showDivider)
              Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.7), indent: 66),
          ],
        ),
      ),
    );
  }
}

@Deprecated('Use DrSettingsSection + DrSettingsRow')
class DrSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Color? iconColor;
  final VoidCallback onTap;

  const DrSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DrSettingsSection(
      label: '',
      children: [
        DrSettingsRow(
          icon: icon,
          title: title,
          subtitle: subtitle,
          iconColor: iconColor,
          showDivider: false,
          trailing: trailing != null
              ? Text(trailing!, style: const TextStyle(color: AppColors.coin, fontWeight: FontWeight.w800))
              : null,
          onTap: onTap,
        ),
      ],
    );
  }
}

class DrSheetHandle extends StatelessWidget {
  const DrSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class DrCreateTypeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DrCreateTypeTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.82)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleLarge().copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.25),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted.withValues(alpha: 0.7), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
