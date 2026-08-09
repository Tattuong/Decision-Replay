import 'package:flutter/material.dart';

enum NoteType { text, checklist, photo, voice }

class ChecklistItem {
  final String id;
  final String text;
  final bool checked;

  const ChecklistItem({required this.id, required this.text, this.checked = false});

  ChecklistItem copyWith({String? text, bool? checked}) {
    return ChecklistItem(id: id, text: text ?? this.text, checked: checked ?? this.checked);
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'checked': checked};

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      checked: json['checked'] == true,
    );
  }
}

class NoteEntry {
  final String id;
  final NoteType type;
  final String title;
  final String body;
  final List<ChecklistItem> checklist;
  final String? imagePath;
  final String? voicePath;
  final int voiceDurationSec;
  final int colorIndex;
  final String? labelId;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteEntry({
    required this.id,
    required this.type,
    this.title = '',
    this.body = '',
    this.checklist = const [],
    this.imagePath,
    this.voicePath,
    this.voiceDurationSec = 0,
    this.colorIndex = 0,
    this.labelId,
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    if (type == NoteType.checklist) {
      for (final item in checklist) {
        if (item.text.trim().isNotEmpty) return item.text.trim();
      }
    }
    if (body.trim().isNotEmpty) return body.trim().split('\n').first;
    return 'Untitled note';
  }

  String get preview {
    if (type == NoteType.checklist) {
      final unchecked = checklist.where((c) => !c.checked).take(2).map((c) => c.text).join(', ');
      return unchecked.isEmpty ? 'All done' : unchecked;
    }
    if (type == NoteType.photo) return body.trim().isEmpty ? 'Photo note' : body.trim();
    if (type == NoteType.voice) return voiceDurationSec > 0 ? 'Voice memo · ${_fmt(voiceDurationSec)}' : 'Voice memo';
    return body.trim();
  }

  static String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  NoteEntry copyWith({
    NoteType? type,
    String? title,
    String? body,
    List<ChecklistItem>? checklist,
    String? imagePath,
    String? voicePath,
    int? voiceDurationSec,
    int? colorIndex,
    String? labelId,
    bool? pinned,
    DateTime? updatedAt,
    bool clearImage = false,
    bool clearVoice = false,
    bool clearLabel = false,
  }) {
    return NoteEntry(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      checklist: checklist ?? this.checklist,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      voicePath: clearVoice ? null : (voicePath ?? this.voicePath),
      voiceDurationSec: voiceDurationSec ?? this.voiceDurationSec,
      colorIndex: colorIndex ?? this.colorIndex,
      labelId: clearLabel ? null : (labelId ?? this.labelId),
      pinned: pinned ?? this.pinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'checklist': checklist.map((c) => c.toJson()).toList(),
        'imagePath': imagePath,
        'voicePath': voicePath,
        'voiceDurationSec': voiceDurationSec,
        'colorIndex': colorIndex,
        'labelId': labelId,
        'pinned': pinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteEntry.fromJson(Map<String, dynamic> json) {
    return NoteEntry(
      id: json['id'] as String,
      type: NoteType.values.firstWhere((e) => e.name == json['type'], orElse: () => NoteType.text),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      checklist: (json['checklist'] as List<dynamic>? ?? [])
          .map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      imagePath: json['imagePath'] as String?,
      voicePath: json['voicePath'] as String?,
      voiceDurationSec: (json['voiceDurationSec'] as num?)?.toInt() ?? 0,
      colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
      labelId: json['labelId'] as String?,
      pinned: json['pinned'] == true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class NoteLabel {
  final String id;
  final String name;
  final int colorIndex;

  const NoteLabel({required this.id, required this.name, required this.colorIndex});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'colorIndex': colorIndex};

  factory NoteLabel.fromJson(Map<String, dynamic> json) {
    return NoteLabel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Label',
      colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class NotePalette {
  NotePalette._();

  static const cardColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFF475),
    Color(0xFFFFD180),
    Color(0xFFFFAB91),
    Color(0xFFA7FFEB),
    Color(0xFFCBF0F8),
    Color(0xFFE8D5B7),
    Color(0xFFE8EAED),
  ];

  static const cardGradients = [
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF9C4), Color(0xFFFFF475)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE0B2), Color(0xFFFFB74D)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFCCBC), Color(0xFFFF8A80)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFB2DFDB), Color(0xFF64FFDA)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFBBDEFB), Color(0xFF81D4FA)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD7CCC8), Color(0xFFBCAAA4)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)]),
  ];

  static const labelGradients = [
    LinearGradient(colors: [Color(0xFFFF8A80), Color(0xFFFF5252)]),
    LinearGradient(colors: [Color(0xFF64B5F6), Color(0xFF1976D2)]),
    LinearGradient(colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)]),
    LinearGradient(colors: [Color(0xFF81C784), Color(0xFF43A047)]),
    LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFF57C00)]),
    LinearGradient(colors: [Color(0xFF4DB6AC), Color(0xFF00897B)]),
    LinearGradient(colors: [Color(0xFF7986CB), Color(0xFF5C6BC0)]),
    LinearGradient(colors: [Color(0xFFA1887F), Color(0xFF8D6E63)]),
  ];

  static Color cardColor(int index) => cardColors[index % cardColors.length];

  static LinearGradient cardGradient(int index) => cardGradients[index % cardGradients.length];

  static LinearGradient labelGradient(int index) => labelGradients[index % labelGradients.length];

  static const labelColors = [
    Color(0xFFFF8A80),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFF4DB6AC),
    Color(0xFF7986CB),
    Color(0xFFA1887F),
  ];
}
