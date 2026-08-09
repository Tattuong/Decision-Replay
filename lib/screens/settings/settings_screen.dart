import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/export_service.dart';
import '../../providers/notes_provider.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/coin_balance_chip.dart';
import '../../widgets/coin_purchase_sheet.dart';
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t(context, 'settings'),
                          style: AppTypography.playfair(size: 30, weight: FontWeight.w700, height: 1.05),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.t(context, 'settingsSubtitle'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  CoinBalanceChip(
                    variant: CoinChipVariant.header,
                    onTap: () => CoinPurchaseSheet.show(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SettingsShopCard(
                coins: shop.coins,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  DrSettingsSection(
                    label: AppStrings.t(context, 'settingsPersonalize'),
                    children: [
                      DrSettingsRow(
                        icon: Icons.palette_rounded,
                        title: AppStrings.t(context, 'appearance'),
                        showDivider: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShopScreen(initialTab: ShopRewardsTab.themes)),
                        ),
                      ),
                    ],
                  ),
                  DrSettingsSection(
                    label: AppStrings.t(context, 'settingsYourData'),
                    children: [
                      DrSettingsRow(
                        icon: Icons.ios_share_rounded,
                        title: AppStrings.t(context, 'exportNotes'),
                        locked: !shop.hasExport,
                        onTap: () => _export(context, shop, notes),
                      ),
                      DrSettingsRow(
                        icon: Icons.backup_rounded,
                        title: AppStrings.t(context, 'backupFile'),
                        locked: !shop.hasBackup,
                        showDivider: shop.hasBackup,
                        onTap: () => _backup(context, shop, notes),
                      ),
                      if (shop.hasBackup)
                        DrSettingsRow(
                          icon: Icons.restore_rounded,
                          title: AppStrings.t(context, 'restoreFile'),
                          showDivider: false,
                          onTap: () => _restore(context, notes),
                        ),
                    ],
                  ),
                  DrSettingsSection(
                    label: AppStrings.t(context, 'settingsMore'),
                    children: [
                      if (shop.hasWidget)
                        DrSettingsRow(
                          icon: Icons.widgets_rounded,
                          title: AppStrings.t(context, 'homeWidget'),
                          subtitle: AppStrings.t(context, 'homeWidgetDesc'),
                          onTap: () => AppToast.show(context, title: AppStrings.t(context, 'widgetEnabled')),
                        ),
                      DrSettingsRow(
                        icon: Icons.privacy_tip_rounded,
                        title: AppStrings.t(context, 'privacyPolicy'),
                        showDivider: false,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      AppStrings.t(context, 'version', {'version': '1.0.0'}),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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

class _SettingsShopCard extends StatelessWidget {
  final int coins;
  final VoidCallback onTap;

  const _SettingsShopCard({required this.coins, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(context, 'shop'),
                        style: AppTypography.playfair(size: 20, weight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.t(context, 'shopTagline'),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12, height: 1.25),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, color: AppColors.coin, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$coins',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.t(context, 'settingsOpenShop'),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
