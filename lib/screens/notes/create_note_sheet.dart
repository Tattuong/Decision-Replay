import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/note_entry.dart';
import '../../providers/notes_provider.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/dr_design.dart';
import '../shop/shop_screen.dart';
import 'note_editor_screen.dart';

class CreateNoteSheet {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateNoteSheet(),
    );
  }
}

class _CreateNoteSheet extends StatelessWidget {
  const _CreateNoteSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrSheetHandle(),
          Text(AppStrings.t(context, 'createNew'), style: AppTypography.titleLarge().copyWith(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            AppStrings.t(context, 'createNewDesc'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          DrCreateTypeTile(
            icon: Icons.edit_outlined,
            color: const Color(0xFF2563EB),
            title: AppStrings.t(context, 'textNote'),
            subtitle: AppStrings.t(context, 'textNoteDesc'),
            onTap: () => _create(context, NoteType.text),
          ),
          const SizedBox(height: 8),
          DrCreateTypeTile(
            icon: Icons.check_box_outlined,
            color: const Color(0xFF16A34A),
            title: AppStrings.t(context, 'checklistNote'),
            subtitle: AppStrings.t(context, 'checklistNoteDesc'),
            onTap: () => _create(context, NoteType.checklist),
          ),
          const SizedBox(height: 8),
          DrCreateTypeTile(
            icon: Icons.photo_camera_outlined,
            color: const Color(0xFFEC4899),
            title: AppStrings.t(context, 'photoNote'),
            subtitle: AppStrings.t(context, 'photoNoteDesc'),
            onTap: () => _create(context, NoteType.photo),
          ),
          const SizedBox(height: 8),
          DrCreateTypeTile(
            icon: Icons.mic_none_outlined,
            color: const Color(0xFFF59E0B),
            title: AppStrings.t(context, 'voiceNote'),
            subtitle: AppStrings.t(context, 'voiceNoteDesc'),
            onTap: () => _create(context, NoteType.voice),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, NoteType type) async {
    final notesProv = context.read<NotesProvider>();
    final shop = context.read<ShopProvider>();
    Navigator.pop(context);

    if (!notesProv.canAddNote(shop.hasUnlimitedNotes)) {
      AppToast.show(context, title: AppStrings.t(context, 'noteLimitReached'));
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen(initialTab: ShopRewardsTab.features)));
      return;
    }

    if (type == NoteType.voice && !shop.hasVoiceMemo) {
      AppToast.show(context, title: AppStrings.t(context, 'voiceLocked'));
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen(initialTab: ShopRewardsTab.features)));
      return;
    }

    final draft = notesProv.createDraft(type);
    if (!context.mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(draft: draft)));
  }
}
