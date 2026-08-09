import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/note_entry.dart';
import '../../providers/notes_provider.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/dr_design.dart';

enum _EditorTool { checklist, camera, mic, text, color, tag }

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  final NoteEntry? draft;

  const NoteEditorScreen({super.key, this.noteId, this.draft}) : assert(noteId != null || draft != null);

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _bodyFocus = FocusNode();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  bool _recording = false;
  int _recordSec = 0;
  bool _playing = false;
  _EditorTool? _activeTool;

  static const _editorColorIndices = [0, 1, 2, 3, 4, 5, 6, 7];

  late NoteEntry _workingNote;
  bool _isNew = false;
  bool _dirty = false;
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNote());
  }

  void _loadNote() {
    if (widget.draft != null) {
      _workingNote = widget.draft!;
      _isNew = true;
    } else {
      final note = context.read<NotesProvider>().findById(widget.noteId!);
      if (note == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      _workingNote = note;
    }
    _titleCtrl.text = _workingNote.title;
    _bodyCtrl.text = _workingNote.body;
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _bodyFocus.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  NoteEntry _currentNote() {
    return _workingNote.copyWith(title: _titleCtrl.text, body: _bodyCtrl.text);
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  void _updateNote(NoteEntry note) {
    setState(() {
      _workingNote = note;
      _dirty = true;
    });
  }

  bool _isBlank(NoteEntry note) {
    if (note.title.trim().isNotEmpty || note.body.trim().isNotEmpty) return false;
    if (note.imagePath != null || note.voicePath != null) return false;
    if (note.checklist.any((c) => c.text.trim().isNotEmpty)) return false;
    return true;
  }

  Future<void> _save() async {
    if (_saving) return;
    final note = _currentNote();
    if (_isBlank(note)) {
      AppToast.show(context, title: AppStrings.t(context, 'noteEmpty'));
      return;
    }

    final notesProv = context.read<NotesProvider>();
    final shop = context.read<ShopProvider>();

    if (_isNew && !notesProv.canAddNote(shop.hasUnlimitedNotes)) {
      AppToast.show(context, title: AppStrings.t(context, 'noteLimitReached'));
      return;
    }

    if (note.pinned) {
      final existing = notesProv.findById(note.id);
      final wasPinned = existing?.pinned ?? false;
      if (!wasPinned && !notesProv.canPin(shop.hasUnlimitedPins)) {
        AppToast.show(context, title: AppStrings.t(context, 'pinLimitReached'));
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await notesProv.saveNote(note);
      if (_isNew) await shop.rewardForNoteCreated();
      if (!mounted) return;
      AppToast.show(context, title: AppStrings.t(context, 'noteSaved'));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(ctx, 'discardChangesTitle')),
        content: Text(AppStrings.t(ctx, 'discardChangesBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.t(ctx, 'keepEditing'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.t(ctx, 'discard'))),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleBack() async {
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    if (await _confirmDiscard() && mounted) Navigator.pop(context);
  }

  Future<void> _deleteNote() async {
    if (_isNew) {
      Navigator.pop(context);
      return;
    }
    await context.read<NotesProvider>().deleteNote(_workingNote.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showLabelPicker(NoteEntry note, List<NoteLabel> labels) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.55;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: DrSheetHandle(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(AppStrings.t(ctx, 'labels'), style: AppTypography.titleLarge().copyWith(fontSize: 18)),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: labels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (_, i) {
                      final l = labels[i];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        leading: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: NotePalette.labelColors[l.colorIndex % NotePalette.labelColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(l.name),
                        trailing: note.labelId == l.id ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20) : null,
                        onTap: () => Navigator.pop(ctx, l.id),
                      );
                    },
                  ),
                ),
                if (note.labelId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, ''),
                      child: Text(AppStrings.t(ctx, 'clearLabel')),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    if (picked.isEmpty) {
      _updateNote(note.copyWith(clearLabel: true));
    } else {
      _updateNote(note.copyWith(labelId: picked));
    }
  }

  void _toggleChecklistMode(NoteEntry note) {
    setState(() => _activeTool = _EditorTool.checklist);
    if (note.type != NoteType.checklist) {
      _updateNote(note.copyWith(
        type: NoteType.checklist,
        checklist: [
          ChecklistItem(
            id: const Uuid().v4(),
            text: note.body.trim().isNotEmpty ? note.body.trim() : '',
          ),
        ],
      ));
      return;
    }

    final last = note.checklist.isNotEmpty ? note.checklist.last : null;
    if (last != null && last.text.trim().isEmpty) return;

    _updateNote(note.copyWith(
      checklist: [...note.checklist, ChecklistItem(id: const Uuid().v4(), text: '')],
    ));
  }

  void _removeChecklistItem(NoteEntry note, int index) {
    final items = [...note.checklist]..removeAt(index);
    if (items.isEmpty) {
      _switchToTextMode(note);
      return;
    }
    _updateNote(note.copyWith(checklist: items));
  }

  void _switchToTextMode(NoteEntry note) {
    setState(() => _activeTool = _EditorTool.text);
    final lines = note.checklist
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => c.checked ? '✓ ${c.text.trim()}' : c.text.trim())
        .join('\n');
    _bodyCtrl.text = lines;
    _updateNote(note.copyWith(type: NoteType.text, body: lines, checklist: []));
    _bodyFocus.requestFocus();
  }

  LinearGradient _editorGradient(int colorIndex) => NotePalette.cardGradient(colorIndex);

  Color _editorBackground(int colorIndex) {
    final g = _editorGradient(colorIndex);
    return Color.lerp(const Color(0xFFFAF8F4), g.colors.first, 0.28)!;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const DrScaffold(
        extendBody: false,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final notesProv = context.watch<NotesProvider>();
    final shop = context.watch<ShopProvider>();
    final note = _workingNote;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: _editorBackground(note.colorIndex),
        appBar: AppBar(
          backgroundColor: _editorBackground(note.colorIndex),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: AppColors.textPrimary,
                onPressed: _handleBack,
              ),
              Expanded(
                child: Center(
                  child: !_dirty && !_isNew
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success.withValues(alpha: 0.85)),
                            const SizedBox(width: 5),
                            Text(
                              AppStrings.t(context, 'saved'),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              if (_dirty)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _EditorSaveButton(saving: _saving, onPressed: _save),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _deleteNote();
                  } else if (value == 'pin') {
                    await _togglePin(note, notesProv, shop);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(note.pinned ? AppStrings.t(context, 'unpin') : AppStrings.t(context, 'pinNote')),
                  ),
                  PopupMenuItem(value: 'delete', child: Text(AppStrings.t(context, 'delete'))),
                ],
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _editorGradient(note.colorIndex).colors.first.withValues(alpha: 0.22),
                _editorGradient(note.colorIndex).colors.last.withValues(alpha: 0.1),
                const Color(0xFFFAF8F4),
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
          child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      onChanged: (_) => _markDirty(),
                      style: AppTypography.playfair(size: 28, weight: FontWeight.w700, height: 1.2),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: AppStrings.t(context, 'untitledNote'),
                        border: InputBorder.none,
                        hintStyle: AppTypography.playfair(size: 28, weight: FontWeight.w700, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (note.type == NoteType.checklist)
                      ...note.checklist.asMap().entries.map(
                            (e) => _ChecklistItemField(
                              key: ValueKey(e.value.id),
                              item: e.value,
                              onChecked: (v) {
                                final items = [...note.checklist];
                                items[e.key] = e.value.copyWith(checked: v);
                                _updateNote(note.copyWith(checklist: items));
                              },
                              onTextChanged: (v) {
                                final items = [...note.checklist];
                                items[e.key] = e.value.copyWith(text: v);
                                _updateNote(note.copyWith(checklist: items));
                              },
                              onDelete: () {
                                if (note.checklist.length == 1) {
                                  _switchToTextMode(note);
                                } else {
                                  _removeChecklistItem(note, e.key);
                                }
                              },
                            ),
                          )
                    else
                      TextField(
                        controller: _bodyCtrl,
                        focusNode: _bodyFocus,
                        onChanged: (_) => _markDirty(),
                        maxLines: null,
                        style: AppTypography.playfair(size: 17, weight: FontWeight.w400, color: AppColors.textSecondary, height: 1.55),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: AppStrings.t(context, 'startWriting'),
                          border: InputBorder.none,
                          hintStyle: AppTypography.playfair(size: 17, weight: FontWeight.w400, color: AppColors.textMuted, height: 1.55),
                        ),
                      ),
                    if (note.imagePath != null) ...[
                      const SizedBox(height: 20),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(File(note.imagePath!), width: double.infinity, height: 220, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _updateNote(note.copyWith(clearImage: true)),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (note.voicePath != null) ...[
                      const SizedBox(height: 20),
                      _VoiceBar(
                        durationSec: note.voiceDurationSec,
                        playing: _playing,
                        onPlay: () => _togglePlay(note.voicePath!),
                        onDelete: () => _updateNote(note.copyWith(clearVoice: true)),
                      ),
                    ],
                    if (_recording) ...[
                      const SizedBox(height: 20),
                      _RecordingBar(seconds: _recordSec),
                    ],
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FloatingToolBar(
                      activeTool: _recording ? _EditorTool.mic : _activeTool,
                      checklistActive: note.type == NoteType.checklist,
                      colorIndex: note.colorIndex,
                      onChecklist: () => _toggleChecklistMode(note),
                      onCamera: () {
                        setState(() => _activeTool = _EditorTool.camera);
                        _showImageSourcePicker(note);
                      },
                      onMic: () {
                        setState(() => _activeTool = _EditorTool.mic);
                        _toggleRecord(note, shop);
                      },
                      onText: () {
                        if (note.type == NoteType.checklist) {
                          _switchToTextMode(note);
                        } else {
                          setState(() => _activeTool = _EditorTool.text);
                          _bodyFocus.requestFocus();
                        }
                      },
                      onColor: () => setState(() => _activeTool = _EditorTool.color),
                      onTag: () {
                        setState(() => _activeTool = _EditorTool.tag);
                        _showLabelPicker(note, notesProv.labels);
                      },
                    ),
                    const SizedBox(height: 14),
                    _EditorColorRow(
                      selected: note.colorIndex,
                      indices: _editorColorIndices,
                      onPick: (i) {
                        setState(() => _activeTool = _EditorTool.color);
                        _updateNote(note.copyWith(colorIndex: i));
                      },
                    ),
                    const SizedBox(height: 12),
                    _EditorLabelPicker(
                      label: notesProv.labelFor(note.labelId),
                      onTap: () => _showLabelPicker(note, notesProv.labels),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _togglePin(NoteEntry note, NotesProvider notesProv, ShopProvider shop) async {
    if (!note.pinned) {
      final existing = notesProv.findById(note.id);
      final wasPinned = existing?.pinned ?? false;
      if (!wasPinned && !notesProv.canPin(shop.hasUnlimitedPins)) {
        AppToast.show(context, title: AppStrings.t(context, 'pinLimitReached'));
        return;
      }
    }

    final updated = note.copyWith(pinned: !note.pinned);

    if (!_isNew) {
      final stored = notesProv.findById(note.id);
      if (stored != null) {
        await notesProv.saveNote(stored.copyWith(pinned: updated.pinned));
      }
    } else {
      _markDirty();
    }

    if (mounted) setState(() => _workingNote = _currentNote().copyWith(pinned: updated.pinned));
  }

  Future<void> _showImageSourcePicker(NoteEntry note) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(ctx).bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DrSheetHandle(),
            Text(
              AppStrings.t(ctx, 'pickPhotoSource'),
              style: AppTypography.titleLarge(color: AppColors.textPrimary).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            DrCreateTypeTile(
              icon: Icons.photo_camera_outlined,
              color: const Color(0xFF2563EB),
              title: AppStrings.t(ctx, 'takePhoto'),
              subtitle: AppStrings.t(ctx, 'photoNoteDesc'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            DrCreateTypeTile(
              icon: Icons.photo_library_outlined,
              color: const Color(0xFFEC4899),
              title: AppStrings.t(ctx, 'chooseFromGallery'),
              subtitle: AppStrings.t(ctx, 'photoNoteDesc'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _pickImage(note, source);
  }

  Future<void> _pickImage(NoteEntry note, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/${const Uuid().v4()}.jpg';
    await File(file.path).copy(dest);
    _updateNote(note.copyWith(imagePath: dest, type: NoteType.photo));
  }

  Future<void> _toggleRecord(NoteEntry note, ShopProvider shop) async {
    if (!shop.hasVoiceMemo && note.voicePath == null) {
      AppToast.show(context, title: AppStrings.t(context, 'voiceLocked'));
      return;
    }
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path != null) {
        _updateNote(note.copyWith(voicePath: path, voiceDurationSec: _recordSec, type: NoteType.voice));
      }
      return;
    }
    final limit = context.read<NotesProvider>().voiceLimitSec(shop.hasVoiceMemo);
    if (!await _recorder.hasPermission()) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${const Uuid().v4()}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() {
      _recording = true;
      _recordSec = 0;
    });
    for (var i = 0; i < limit; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_recording) break;
      setState(() => _recordSec = i + 1);
      if (i + 1 >= limit) {
        await _toggleRecord(note, shop);
        break;
      }
    }
  }

  Future<void> _togglePlay(String path) async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    await _player.play(DeviceFileSource(path));
    setState(() => _playing = true);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }
}

class _ChecklistItemField extends StatefulWidget {
  final ChecklistItem item;
  final ValueChanged<bool> onChecked;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onDelete;

  const _ChecklistItemField({
    super.key,
    required this.item,
    required this.onChecked,
    required this.onTextChanged,
    required this.onDelete,
  });

  @override
  State<_ChecklistItemField> createState() => _ChecklistItemFieldState();
}

class _ChecklistItemFieldState extends State<_ChecklistItemField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
  }

  @override
  void didUpdateWidget(_ChecklistItemField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.text != _controller.text) {
      _controller.text = widget.item.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: widget.item.checked,
            activeColor: AppColors.primary,
            side: const BorderSide(color: AppColors.textMuted, width: 1.5),
            onChanged: (v) => widget.onChecked(v ?? false),
          ),
          Expanded(
            child: Focus(
              onKeyEvent: (_, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.backspace && _controller.text.isEmpty) {
                  widget.onDelete();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _controller,
                onChanged: widget.onTextChanged,
                style: AppTypography.playfair(
                  size: 17,
                  weight: FontWeight.w400,
                  color: widget.item.checked ? AppColors.textMuted : AppColors.textSecondary,
                ).copyWith(decoration: widget.item.checked ? TextDecoration.lineThrough : null),
                cursorColor: AppColors.primary,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Task',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 16),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: widget.onDelete,
            tooltip: AppStrings.t(context, 'delete'),
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _VoiceBar extends StatelessWidget {
  final int durationSec;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _VoiceBar({required this.durationSec, required this.playing, required this.onPlay, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    const heights = [0.3, 0.55, 0.75, 0.4, 0.65, 0.85, 0.5, 0.7, 0.45, 0.8, 0.6, 0.9, 0.35, 0.72, 0.58, 0.82];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPlay,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final h in heights)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Container(
                        width: 2.5,
                        height: 28 * h,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final int seconds;

  const _RecordingBar({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            'Recording ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _FloatingToolBar extends StatelessWidget {
  final _EditorTool? activeTool;
  final bool checklistActive;
  final int colorIndex;
  final VoidCallback onChecklist;
  final VoidCallback onCamera;
  final VoidCallback onMic;
  final VoidCallback onText;
  final VoidCallback onColor;
  final VoidCallback onTag;

  const _FloatingToolBar({
    required this.activeTool,
    required this.checklistActive,
    required this.colorIndex,
    required this.onChecklist,
    required this.onCamera,
    required this.onMic,
    required this.onText,
    required this.onColor,
    required this.onTag,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolBtn(
              icon: Icons.checklist_rounded,
              active: activeTool == _EditorTool.checklist || checklistActive,
              onTap: onChecklist,
            ),
            _toolDivider(),
            _ToolBtn(icon: Icons.photo_camera_outlined, active: activeTool == _EditorTool.camera, onTap: onCamera),
            _toolDivider(),
            _ToolBtn(icon: Icons.mic_none_rounded, active: activeTool == _EditorTool.mic, onTap: onMic),
            _toolDivider(),
            _ToolBtn(icon: Icons.text_fields_rounded, active: activeTool == _EditorTool.text, onTap: onText),
            _toolDivider(),
            _ToolBtn(
              icon: Icons.palette_outlined,
              active: activeTool == _EditorTool.color,
              onTap: onColor,
              customIcon: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: NotePalette.cardGradient(colorIndex),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: NotePalette.cardColor(colorIndex).withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            _toolDivider(),
            _ToolBtn(icon: Icons.sell_outlined, active: activeTool == _EditorTool.tag, onTap: onTag),
          ],
        ),
      ),
    );
  }

  Widget _toolDivider() => Container(width: 1, height: 22, color: AppColors.border.withValues(alpha: 0.9));
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Widget? customIcon;

  const _ToolBtn({
    required this.icon,
    required this.active,
    required this.onTap,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              customIcon ?? Icon(icon, size: 20, color: active ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 4),
              Container(
                width: 18,
                height: 2,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorColorRow extends StatelessWidget {
  final int selected;
  final List<int> indices;
  final ValueChanged<int> onPick;

  const _EditorColorRow({required this.selected, required this.indices, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: indices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, idx) {
          final i = indices[idx];
          final isSelected = selected == i;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onPick(i),
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isSelected ? 38 : 34,
                height: isSelected ? 38 : 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: NotePalette.cardGradient(i),
                  border: Border.all(
                    color: isSelected ? AppColors.textPrimary : Colors.white.withValues(alpha: 0.9),
                    width: isSelected ? 2.5 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NotePalette.cardColor(i).withValues(alpha: isSelected ? 0.35 : 0.22),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Center(child: Icon(Icons.check_rounded, size: 16, color: AppColors.textPrimary))
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EditorLabelPicker extends StatelessWidget {
  final NoteLabel? label;
  final VoidCallback onTap;

  const _EditorLabelPicker({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dotColor = label != null
        ? NotePalette.labelColors[label!.colorIndex % NotePalette.labelColors.length]
        : AppColors.textMuted;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  label?.name ?? AppStrings.t(context, 'selectLabel'),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorSaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onPressed;

  const _EditorSaveButton({required this.saving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: saving ? null : onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    AppStrings.t(context, 'save'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
