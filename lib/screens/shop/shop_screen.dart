import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/app_theme_preset.dart';
import '../../models/shop_item.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/coin_balance_chip.dart';
import '../../widgets/coin_engagement_cards.dart';
import '../../widgets/coin_promo_banner.dart';
import '../../widgets/coin_purchase_sheet.dart';
import '../../widgets/dr_design.dart';

enum ShopRewardsTab { all, premium, themes, backgrounds, skins, features }

class ShopScreen extends StatefulWidget {
  final ShopRewardsTab? initialTab;

  const ShopScreen({super.key, this.initialTab});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late ShopRewardsTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab ?? ShopRewardsTab.all;
  }

  List<ShopItem> get _items {
    return switch (_tab) {
      ShopRewardsTab.premium => ShopCatalog.items.where((i) => i.category == ShopItemCategory.premium).toList(),
      ShopRewardsTab.themes => ShopCatalog.items.where((i) => i.category == ShopItemCategory.themes).toList(),
      ShopRewardsTab.backgrounds => ShopCatalog.items.where((i) => i.category == ShopItemCategory.backgrounds).toList(),
      ShopRewardsTab.skins => ShopCatalog.items.where((i) => i.category == ShopItemCategory.skins).toList(),
      ShopRewardsTab.features => ShopCatalog.items.where((i) => i.category == ShopItemCategory.features).toList(),
      ShopRewardsTab.all => ShopCatalog.items,
    };
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();

    return DrScaffold(
      extendBody: false,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _ShopVipHeader(onCoinsTap: () => CoinPurchaseSheet.show(context))),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CoinPromoBanner(hideShopButton: true, vipStyle: true),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: CoinEngagementCards(),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    Text(
                      AppStrings.t(context, 'shopCatalog'),
                      style: AppTypography.titleLarge().copyWith(fontSize: 16, letterSpacing: 0.4),
                    ),
                    const Spacer(),
                    Text(
                      '${_items.length}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ShopRewardsTab.values.map((t) {
                      final key = switch (t) {
                        ShopRewardsTab.all => 'shopMenuAll',
                        ShopRewardsTab.premium => 'shopMenuPremium',
                        ShopRewardsTab.themes => 'shopMenuThemes',
                        ShopRewardsTab.backgrounds => 'shopMenuBackgrounds',
                        ShopRewardsTab.skins => 'shopMenuSkins',
                        ShopRewardsTab.features => 'shopMenuFeatures',
                      };
                      return DrFilterChip(
                        label: AppStrings.t(context, key),
                        selected: _tab == t,
                        vipStyle: true,
                        onTap: () => setState(() => _tab = t),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ShopItemCard(item: _items[i], shop: shop),
              ),
            ),
            if (!shop.isBillingDisabled)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: TextButton.icon(
                    onPressed: shop.restorePurchases,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: Text(AppStrings.t(context, 'restorePurchases')),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final ShopProvider shop;

  const _ShopItemCard({required this.item, required this.shop});

  @override
  Widget build(BuildContext context) {
    final owned = shop.ownsItem(item.id);
    final isActive = _isActive(item);
    final isCosmetic = _canApply(item);

    final isPremium = item.category == ShopItemCategory.premium;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: owned && isCosmetic && !isActive ? () => _apply(context, item) : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : isPremium
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                      : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: (isPremium ? const Color(0xFFF59E0B) : AppColors.textPrimary).withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isPremium)
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: AppColors.vipGoldGradient,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Preview(item: item, shop: shop, premium: isPremium),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.t(context, item.nameKey),
                                style: AppTypography.titleLarge().copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppStrings.t(context, item.descKey),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Trailing(
                          item: item,
                          shop: shop,
                          owned: owned,
                          isActive: isActive,
                          onBuy: () => _buy(context),
                          onApply: () => _apply(context, item),
                          onReset: () => _reset(context, item),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isActive(ShopItem item) {
    return switch (item.type) {
      ShopItemType.theme => shop.activeThemeId == item.id,
      ShopItemType.background => shop.activeBackgroundId == item.id,
      ShopItemType.skin => shop.activeSkinId == item.id,
      _ => false,
    };
  }

  bool _canApply(ShopItem item) =>
      item.type == ShopItemType.theme || item.type == ShopItemType.background || item.type == ShopItemType.skin;

  Future<void> _apply(BuildContext context, ShopItem item) async {
    switch (item.type) {
      case ShopItemType.theme:
        await shop.selectTheme(item.id);
      case ShopItemType.background:
        await shop.selectBackground(item.id);
      case ShopItemType.skin:
        await shop.selectSkin(item.id);
      default:
        break;
    }
    if (context.mounted) AppToast.show(context, title: AppStrings.t(context, 'applied'));
  }

  Future<void> _reset(BuildContext context, ShopItem item) async {
    switch (item.type) {
      case ShopItemType.theme:
        await shop.resetThemeToDefault();
      case ShopItemType.background:
        await shop.resetBackgroundToDefault();
      case ShopItemType.skin:
        await shop.resetSkinToDefault();
      default:
        break;
    }
  }

  void _buy(BuildContext context) {
    final result = shop.buyWithCoins(item.id);
    switch (result) {
      case ShopPurchaseResult.success:
        AppToast.show(context, title: AppStrings.t(context, 'purchaseSuccess'));
      case ShopPurchaseResult.insufficientCoins:
        AppToast.show(context, title: AppStrings.t(context, 'insufficientCoins'));
        CoinPurchaseSheet.show(context);
      case ShopPurchaseResult.alreadyOwned:
        AppToast.show(context, title: AppStrings.t(context, 'alreadyOwned'));
      default:
        AppToast.show(context, title: AppStrings.t(context, 'purchaseFailed'));
    }
  }
}

class _Preview extends StatelessWidget {
  final ShopItem item;
  final ShopProvider shop;
  final bool premium;

  const _Preview({required this.item, required this.shop, this.premium = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: switch (item.type) {
        ShopItemType.theme => _gradientBox(AppThemePresets.get(item.id).headerGradient),
        ShopItemType.background => _gradientBox(AppBackground.get(item.id).gradient),
        ShopItemType.skin => _skinPreview(item.id),
        _ => _iconPreview(item.icon, AppColors.primary),
      },
    );
  }

  Widget _gradientBox(LinearGradient gradient) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: premium ? const Color(0xFFF59E0B).withValues(alpha: 0.35) : AppColors.border),
        boxShadow: premium
            ? [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
    );
  }

  Widget _skinPreview(String id) {
    final style = CardStyle.get(id);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(style.borderRadius * 0.55),
        border: Border.all(color: style.borderWidth > 0 ? style.borderColor : AppColors.border, width: style.borderWidth > 0 ? style.borderWidth : 1),
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _iconPreview(IconData icon, Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _Trailing extends StatelessWidget {
  final ShopItem item;
  final ShopProvider shop;
  final bool owned;
  final bool isActive;
  final VoidCallback onBuy;
  final VoidCallback onApply;
  final VoidCallback onReset;

  const _Trailing({
    required this.item,
    required this.shop,
    required this.owned,
    required this.isActive,
    required this.onBuy,
    required this.onApply,
    required this.onReset,
  });

  bool get _isCosmetic =>
      item.type == ShopItemType.theme || item.type == ShopItemType.background || item.type == ShopItemType.skin;

  @override
  Widget build(BuildContext context) {
    if (!owned) return _PriceButton(price: item.price, loading: shop.isPurchasing, onTap: onBuy);

    if (_isCosmetic) {
      if (isActive) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Badge(text: AppStrings.t(context, 'active'), color: AppColors.primary),
            if (item.id != _defaultId(item))
              TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text(AppStrings.t(context, 'useDefault'), style: const TextStyle(fontSize: 10)),
              ),
          ],
        );
      }
      return FilledButton(
        onPressed: onApply,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(AppStrings.t(context, 'apply'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      );
    }

    return _Badge(text: AppStrings.t(context, 'unlocked'), color: AppColors.success);
  }

  String _defaultId(ShopItem item) => switch (item.type) {
        ShopItemType.theme => ShopCatalog.defaultThemeId,
        ShopItemType.background => ShopCatalog.defaultBackgroundId,
        ShopItemType.skin => ShopCatalog.defaultSkinId,
        _ => '',
      };
}

class _PriceButton extends StatelessWidget {
  final int price;
  final bool loading;
  final VoidCallback onTap;

  const _PriceButton({required this.price, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.vipGoldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, size: 15, color: AppColors.trueBlack),
                const SizedBox(width: 4),
                Text(
                  '$price',
                  style: const TextStyle(color: AppColors.trueBlack, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopVipHeader extends StatelessWidget {
  final VoidCallback onCoinsTap;

  const _ShopVipHeader({required this.onCoinsTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.vipGoldGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, size: 13, color: AppColors.trueBlack),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.t(context, 'shopVipBadge'),
                          style: const TextStyle(color: AppColors.trueBlack, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.t(context, 'shop'),
                  style: AppTypography.playfair(size: 30, weight: FontWeight.w700, height: 1.05),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.t(context, 'shopTagline'),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          CoinBalanceChip(variant: CoinChipVariant.header, vipStyle: true, onTap: onCoinsTap),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
