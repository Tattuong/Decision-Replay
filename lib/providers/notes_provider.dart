import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/iap_constants.dart';
import '../core/services/storage_service.dart';
import '../core/services/widget_service.dart';
import '../models/note_entry.dart';

class NotesProvider extends ChangeNotifier {
  static const _notesKey = 'dr_notes';
  static const _labelsKey = 'dr_labels';
  static const _onboardedKey = 'dr_onboarded';

  List<NoteEntry> _notes = [];
  List<NoteLabel> _labels = [];
  bool _onboardingComplete = false;

  List<NoteEntry> get notes => List.unmodifiable(_notes);
  List<NoteLabel> get labels => List.unmodifiable(_labels);
  bool get onboardingComplete => _onboardingComplete;

  int get pinnedCount => _notes.where((n) => n.pinned).length;

  Future<void> init() async {
    _onboardingComplete = await StorageService.instance.getBool(_onboardedKey) ?? false;

    final noteList = await StorageService.instance.getDataList(_notesKey);
    if (noteList != null) {
      _notes = noteList.map((e) => NoteEntry.fromJson(Map<String, dynamic>.from(e))).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    final labelList = await StorageService.instance.getDataList(_labelsKey);
    if (labelList != null && labelList.isNotEmpty) {
      _labels = labelList.map((e) => NoteLabel.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      _labels = const [
        NoteLabel(id: 'work', name: 'Work', colorIndex: 1),
        NoteLabel(id: 'personal', name: 'Personal', colorIndex: 2),
        NoteLabel(id: 'ideas', name: 'Ideas', colorIndex: 3),
        NoteLabel(id: 'travel', name: 'Travel', colorIndex: 4),
      ];
      await _saveLabels();
    }

    await WidgetService.syncPinnedNotes(_notes);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    await StorageService.instance.saveBool(_onboardedKey, true);
    notifyListeners();
  }

  List<NoteEntry> filtered({String query = '', String? labelId, bool pinnedOnly = false, NoteType? type}) {
    var list = _notes;
    if (pinnedOnly) list = list.where((n) => n.pinned).toList();
    if (labelId != null && labelId != 'all') {
      if (labelId == 'unlabelled') {
        list = list.where((n) => n.labelId == null).toList();
      } else {
        list = list.where((n) => n.labelId == labelId).toList();
      }
    }
    if (type != null) list = list.where((n) => n.type == type).toList();
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((n) {
        return n.displayTitle.toLowerCase().contains(q) ||
            n.body.toLowerCase().contains(q) ||
            n.checklist.any((c) => c.text.toLowerCase().contains(q));
      }).toList();
    }
    return list;
  }

  int countForLabel(String? labelId) {
    if (labelId == null || labelId == 'unlabelled') {
      return _notes.where((n) => n.labelId == null).length;
    }
    return _notes.where((n) => n.labelId == labelId).length;
  }

  List<NoteEntry> checklistNotes() => _notes.where((n) => n.type == NoteType.checklist).toList();

  NoteEntry? findById(String id) {
    for (final n in _notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  NoteLabel? labelFor(String? id) {
    if (id == null) return null;
    for (final l in _labels) {
      if (l.id == id) return l;
    }
    return null;
  }

  bool canAddNote(bool hasPremium) => _notes.length < noteLimit(hasPremium);

  bool canPin(bool hasPremium) => pinnedCount < pinLimit(hasPremium);

  bool canAddLabel(bool hasPremium) => _labels.length < labelLimit(hasPremium);

  int noteLimit(bool hasPremium) => hasPremium ? IapConstants.premiumNoteLimit : IapConstants.freeNoteLimit;

  int labelLimit(bool hasPremium) => hasPremium ? IapConstants.premiumLabelLimit : IapConstants.freeLabelLimit;

  int pinLimit(bool hasPremium) => hasPremium ? IapConstants.premiumPinLimit : IapConstants.freePinLimit;

  int voiceLimitSec(bool hasPremium) => hasPremium ? IapConstants.premiumVoiceSeconds : IapConstants.freeVoiceSeconds;

  NoteEntry createDraft(NoteType type) {
    final now = DateTime.now();
    return NoteEntry(
      id: const Uuid().v4(),
      type: type,
      checklist: type == NoteType.checklist
          ? [ChecklistItem(id: const Uuid().v4(), text: '')]
          : const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> saveNote(NoteEntry note) async {
    final i = _notes.indexWhere((n) => n.id == note.id);
    final updated = note.copyWith(updatedAt: DateTime.now());
    if (i >= 0) {
      _notes[i] = updated;
    } else {
      _notes.insert(0, updated);
    }
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _saveNotes();
    await WidgetService.syncPinnedNotes(_notes);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveNotes();
    await WidgetService.syncPinnedNotes(_notes);
    notifyListeners();
  }

  Future<bool> togglePin(String id, {required bool hasPremium}) async {
    final note = findById(id);
    if (note == null) return false;
    if (!note.pinned && !canPin(hasPremium)) return false;
    await saveNote(note.copyWith(pinned: !note.pinned));
    return true;
  }

  Future<bool> addLabel(String name, {required bool hasPremium}) async {
    if (!canAddLabel(hasPremium)) return false;
    _labels.add(NoteLabel(id: const Uuid().v4(), name: name, colorIndex: _labels.length % NotePalette.labelColors.length));
    await _saveLabels();
    notifyListeners();
    return true;
  }

  Future<void> removeLabel(String id) async {
    _labels.removeWhere((l) => l.id == id);
    _notes = _notes.map((n) => n.labelId == id ? n.copyWith(clearLabel: true) : n).toList();
    await _saveLabels();
    await _saveNotes();
    notifyListeners();
  }

  String backupJson() => StorageService.encodeList(_notes.map((n) => n.toJson()).toList());

  Future<void> restoreFromJson(String raw) async {
    final list = StorageService.decodeList(raw);
    _notes = list.map((e) => NoteEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    await _saveNotes();
    notifyListeners();
  }

  Future<void> _saveNotes() async {
    await StorageService.instance.saveDataList(_notesKey, _notes.map((n) => n.toJson()).toList());
  }

  Future<void> _saveLabels() async {
    await StorageService.instance.saveDataList(_labelsKey, _labels.map((l) => l.toJson()).toList());
  }
}
