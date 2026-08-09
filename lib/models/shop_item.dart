import 'package:flutter/material.dart';

enum ShopItemType {
  theme,
  background,
  skin,
  feature,
  removeAds,
}

enum ShopItemCategory {
  themes,
  backgrounds,
  skins,
  features,
  premium,
}

class ShopItem {
  final String id;
  final String nameKey;
  final String descKey;
  final int price;
  final ShopItemType type;
  final ShopItemCategory category;
  final IconData icon;
  final bool oneTime;

  const ShopItem({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.price,
    required this.type,
    required this.category,
    required this.icon,
    this.oneTime = true,
  });
}

class ShopCatalog {
  ShopCatalog._();

  static const String defaultThemeId = 'theme_default';
  static const String defaultBackgroundId = 'bg_default';
  static const String defaultSkinId = 'skin_default';

  static const List<ShopItem> items = [
    ShopItem(
      id: 'remove_ads',
      nameKey: 'shopRemoveAds',
      descKey: 'shopRemoveAdsDesc',
      price: 500,
      type: ShopItemType.removeAds,
      category: ShopItemCategory.premium,
      icon: Icons.block_outlined,
    ),
    ShopItem(
      id: 'theme_ocean',
      nameKey: 'shopThemeOcean',
      descKey: 'shopThemeOceanDesc',
      price: 200,
      type: ShopItemType.theme,
      category: ShopItemCategory.themes,
      icon: Icons.water_outlined,
    ),
    ShopItem(
      id: 'theme_rose',
      nameKey: 'shopThemeRose',
      descKey: 'shopThemeRoseDesc',
      price: 200,
      type: ShopItemType.theme,
      category: ShopItemCategory.themes,
      icon: Icons.local_florist_outlined,
    ),
    ShopItem(
      id: 'theme_midnight',
      nameKey: 'shopThemeMidnight',
      descKey: 'shopThemeMidnightDesc',
      price: 250,
      type: ShopItemType.theme,
      category: ShopItemCategory.themes,
      icon: Icons.nightlight_outlined,
    ),
    ShopItem(
      id: 'bg_linen',
      nameKey: 'shopBgLinen',
      descKey: 'shopBgLinenDesc',
      price: 150,
      type: ShopItemType.background,
      category: ShopItemCategory.backgrounds,
      icon: Icons.texture_outlined,
    ),
    ShopItem(
      id: 'bg_sky',
      nameKey: 'shopBgSky',
      descKey: 'shopBgSkyDesc',
      price: 150,
      type: ShopItemType.background,
      category: ShopItemCategory.backgrounds,
      icon: Icons.wb_cloudy_outlined,
    ),
    ShopItem(
      id: 'bg_bloom',
      nameKey: 'shopBgBloom',
      descKey: 'shopBgBloomDesc',
      price: 180,
      type: ShopItemType.background,
      category: ShopItemCategory.backgrounds,
      icon: Icons.auto_awesome_outlined,
    ),
    ShopItem(
      id: 'skin_soft',
      nameKey: 'shopSkinSoft',
      descKey: 'shopSkinSoftDesc',
      price: 150,
      type: ShopItemType.skin,
      category: ShopItemCategory.skins,
      icon: Icons.rounded_corner,
    ),
    ShopItem(
      id: 'skin_bold',
      nameKey: 'shopSkinBold',
      descKey: 'shopSkinBoldDesc',
      price: 180,
      type: ShopItemType.skin,
      category: ShopItemCategory.skins,
      icon: Icons.crop_square_outlined,
    ),
    ShopItem(
      id: 'feat_unlimited_notes',
      nameKey: 'shopFeatUnlimitedNotes',
      descKey: 'shopFeatUnlimitedNotesDesc',
      price: 300,
      type: ShopItemType.feature,
      category: ShopItemCategory.features,
      icon: Icons.all_inclusive,
    ),
    ShopItem(
      id: 'feat_voice_memo',
      nameKey: 'shopFeatVoiceMemo',
      descKey: 'shopFeatVoiceMemoDesc',
      price: 250,
      type: ShopItemType.feature,
      category: ShopItemCategory.features,
      icon: Icons.mic_outlined,
    ),
    ShopItem(
      id: 'feat_export',
      nameKey: 'shopFeatExport',
      descKey: 'shopFeatExportDesc',
      price: 200,
      type: ShopItemType.feature,
      category: ShopItemCategory.features,
      icon: Icons.ios_share_outlined,
    ),
    ShopItem(
      id: 'feat_backup',
      nameKey: 'shopFeatBackup',
      descKey: 'shopFeatBackupDesc',
      price: 250,
      type: ShopItemType.feature,
      category: ShopItemCategory.features,
      icon: Icons.backup_outlined,
    ),
    ShopItem(
      id: 'feat_widget',
      nameKey: 'shopFeatWidget',
      descKey: 'shopFeatWidgetDesc',
      price: 300,
      type: ShopItemType.feature,
      category: ShopItemCategory.features,
      icon: Icons.widgets_outlined,
    ),
    ShopItem(
      id: 'feat_unlimited_labels',
      nameKey: 'shopFeatUnlimitedLabels',
      descKey: 'shopFeatUnlimitedLabelsDesc',
      price: 200,
      type: ShopItemType.feature,
      category: ShopItemCategory.features,
      icon: Icons.label_outline,
    ),
    ShopItem(
      id: 'feat_pin_unlimited',
      nameKey: 'shopFeatPinUnlimited',
      descKey: 'shopFeatPinUnlimitedDesc',
      price: 180,
      type: ShopItemType.feature,
      category: ShopItemCategory.features,
      icon: Icons.push_pin_outlined,
    ),
  ];

  static ShopItem? find(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
