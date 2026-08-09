import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/export_service.dart';
import '../../providers/notes_provider.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/dr_design.dart';
import '../privacy_policy_screen.dart';
import '../shop/shop_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>();
    final shop = context.watch<ShopProvider>();

    return DrScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            DrPageHeader(title: AppStrings.t(context, 'settings')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  DrSettingsTile(
                    icon: Icons.storefront_rounded,
                    title: AppStrings.t(context, 'shop'),
                    trailing: '${shop.coins}',
                    iconColor: AppColors.coin,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
                  ),
                  DrSettingsTile(
                    icon: Icons.palette_rounded,
                    title: AppStrings.t(context, 'appearance'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopScreen(initialTab: ShopRewardsTab.themes)),
                    ),
                  ),
                  DrSettingsTile(
                    icon: Icons.ios_share_rounded,
                    title: AppStrings.t(context, 'exportNotes'),
                    onTap: () => _export(context, shop, notes),
                  ),
                  DrSettingsTile(
                    icon: Icons.backup_rounded,
                    title: AppStrings.t(context, 'backupFile'),
                    onTap: () => _backup(context, shop, notes),
                  ),
                  if (shop.hasBackup)
                    DrSettingsTile(
                      icon: Icons.restore_rounded,
                      title: AppStrings.t(context, 'restoreFile'),
                      onTap: () => _restore(context, notes),
                    ),
                  if (shop.hasWidget)
                    DrSettingsTile(
                      icon: Icons.widgets_rounded,
                      title: AppStrings.t(context, 'homeWidget'),
                      subtitle: AppStrings.t(context, 'homeWidgetDesc'),
                      onTap: () => AppToast.show(context, title: AppStrings.t(context, 'widgetEnabled')),
                    ),
                  DrSettingsTile(
                    icon: Icons.privacy_tip_rounded,
                    title: AppStrings.t(context, 'privacyPolicy'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.t(context, 'version', {'version': '1.0.0'}),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, ShopProvider shop, NotesProvider notes) async {
    if (!shop.hasExport) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen(initialTab: ShopRewardsTab.features)));
      return;
    }
    await ExportService.exportNotes(notes.notes);
  }

  Future<void> _backup(BuildContext context, ShopProvider shop, NotesProvider notes) async {
    if (!shop.hasBackup) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen(initialTab: ShopRewardsTab.features)));
      return;
    }
    await ExportService.backupData(notes.backupJson());
  }

  Future<void> _restore(BuildContext context, NotesProvider notes) async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(context, 'restoreFile')),
        content: TextField(
          controller: controller,
          maxLines: 6,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: AppStrings.t(context, 'pasteBackupJson')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.t(context, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(AppStrings.t(context, 'save'))),
        ],
      ),
    );
    if (raw == null || raw.isEmpty || !context.mounted) return;
    try {
      await notes.restoreFromJson(raw);
      AppToast.show(context, title: AppStrings.t(context, 'restoreSuccess'));
    } catch (_) {
      AppToast.show(context, title: AppStrings.t(context, 'restoreFailed'));
    }
  }
}
