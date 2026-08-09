import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/note_entry.dart';

class ExportService {
  ExportService._();

  static Future<void> exportNotes(List<NoteEntry> notes) async {
    final buffer = StringBuffer('DECISION REPLAY NOTES EXPORT\n${'=' * 32}\n\n');
    for (final note in notes) {
      buffer.writeln('# ${note.displayTitle}');
      buffer.writeln('Type: ${note.type.name} · Updated: ${note.updatedAt}');
      if (note.body.isNotEmpty) buffer.writeln(note.body);
      if (note.checklist.isNotEmpty) {
        for (final item in note.checklist) {
          buffer.writeln('${item.checked ? '[x]' : '[ ]'} ${item.text}');
        }
      }
      buffer.writeln('');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/dr_notes_export.txt');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], subject: 'Decision Replay Notes Export');
  }

  static Future<void> backupData(String jsonContent) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/dr_backup.json');
    await file.writeAsString(jsonContent);
    await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')], subject: 'Decision Replay Backup');
  }
}
