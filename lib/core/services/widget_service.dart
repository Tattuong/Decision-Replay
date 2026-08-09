import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../models/note_entry.dart';

class WidgetService {
  WidgetService._();

  static const _androidName = 'DecisionReplayWidgetProvider';
  static const _iosName = 'DecisionReplayWidget';
  static const _timeout = Duration(seconds: 2);

  static Future<void> init() async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId('group.com.decisionreplaymng.decisionreplay').timeout(_timeout);
      }
      await HomeWidget.registerInteractivityCallback(_backgroundCallback).timeout(_timeout);
    } catch (e) {
      debugPrint('WidgetService.init skipped: $e');
    }
  }

  static Future<void> syncPinnedNotes(List<NoteEntry> notes) async {
    try {
      final pinned = notes.where((n) => n.pinned).take(4).toList();
      await HomeWidget.saveWidgetData<String>('pinned_title_1', pinned.isNotEmpty ? pinned[0].displayTitle : '').timeout(_timeout);
      await HomeWidget.saveWidgetData<String>('pinned_title_2', pinned.length > 1 ? pinned[1].displayTitle : '').timeout(_timeout);
      await HomeWidget.saveWidgetData<String>('pinned_title_3', pinned.length > 2 ? pinned[2].displayTitle : '').timeout(_timeout);
      await HomeWidget.saveWidgetData<String>('pinned_title_4', pinned.length > 3 ? pinned[3].displayTitle : '').timeout(_timeout);
      await HomeWidget.updateWidget(androidName: _androidName, iOSName: _iosName).timeout(_timeout);
    } catch (e) {
      debugPrint('WidgetService.sync skipped: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {}
}
