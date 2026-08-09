import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/iap_constants.dart';
import '../providers/shop_provider.dart';
import '../screens/shop/shop_screen.dart';
import 'app_ui.dart';
import 'coin_purchase_sheet.dart';

/// Promo block — use [compact] on Home, full layout in Shop.
class CoinPromoBanner extends StatefulWidget {
  final bool compact;
  final bool hideShopButton;
  final bool vipStyle;

  const CoinPromoBanner({
    super.key,
    this.compact = false,
    this.hideShopButton = false,
    this.vipStyle = false,
  });

  @override
  State<CoinPromoBanner> createState() => _CoinPromoBannerState();
}

class _CoinPromoBannerState extends State<CoinPromoBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _CompactPromoBanner(
        expanded: _expanded,
        hideShopButton: widget.hideShopButton,
        onToggle: () => setState(() => _expanded = !_expanded),
      );
    }
    return _FullPromoBanner(hideShopButton: widget.hideShopButton, vipStyle: widget.vipStyle);
  }
}

class _CompactPromoBanner extends StatelessWidget {
  final bool expanded;
  final bool hideShopButton;
  final VoidCallback onToggle;

  const _CompactPromoBanner({
    required this.expanded,
    required this.hideShopButton,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hotCoins = shop.effectiveCoinsForPackIndex(shop.weeklyHotDealPackIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggle,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A2744), const Color(0xFF252040)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFFFF7ED)],
              ),
              border: Border.all(color: AppColors.coin.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.coin, AppColors.coin.withValues(alpha: 0.7)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.t(context, 'promoCompactTitle'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelBold(size: 13, color: isDark ? Colors.white : AppColors.onSurface),
                            ),
                            Text(
                              AppStrings.t(context, 'promoHotDealDesc', {
                                'pack': shop.weeklyHotDealPackNumber.toString(),
                                'coins': hotCoins.toString(),
                              }),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (shop.firstPurchaseBonusAvailable)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppStrings.t(context, 'firstPurchaseBadge'),
                              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      if (!shop.isBillingDisabled)
                        Material(
                          color: AppColors.coin,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => CoinPurchaseSheet.show(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              child: Text(
                                AppStrings.t(context, 'promoBuyShort'),
                                style: const TextStyle(color: AppColors.trueBlack, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.coin, size: 20),
                    ],
                  ),
                ),
                  if (expanded && !hideShopButton) ...[
                    Divider(height: 1, color: AppColors.coin.withValues(alpha: 0.15)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: _UnlockProgress(shop: shop, dense: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
                              icon: const Icon(Icons.storefront_outlined, size: 16),
                              label: Text(AppStrings.t(context, 'navShop'), style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (expanded) ...[
                    Divider(height: 1, color: AppColors.coin.withValues(alpha: 0.15)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: _UnlockProgress(shop: shop, dense: true),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullPromoBanner extends StatelessWidget {
  final bool hideShopButton;
  final bool vipStyle;

  const _FullPromoBanner({this.hideShopButton = false, this.vipStyle = false});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final premium = vipStyle || hideShopButton;
    final hotCoins = shop.effectiveCoinsForPackIndex(shop.weeklyHotDealPackIndex);

    return Padding(
      padding: EdgeInsets.fromLTRB(premium ? 0 : 16, premium ? 0 : 12, premium ? 0 : 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: premium
              ? AppColors.shopVipHeroGradient
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEFF6FF), Color(0xFFFFF7ED)],
                ),
          border: Border.all(
            color: premium ? const Color(0xFFF59E0B).withValues(alpha: 0.45) : AppColors.coin.withValues(alpha: 0.3),
          ),
          boxShadow: premium
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: premium ? AppColors.vipGoldGradient : null,
                    color: premium ? null : AppColors.coin.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: premium ? AppColors.trueBlack : AppColors.coin,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.t(context, 'promoHotDeal'),
                        style: TextStyle(
                          color: premium ? AppColors.trueBlack : AppColors.coin,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (shop.firstPurchaseBonusAvailable) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: premium ? 0.2 : 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppStrings.t(context, 'firstPurchaseBadge'),
                      style: TextStyle(
                        color: premium ? const Color(0xFFFF8A80) : const Color(0xFFFF6B6B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.t(context, 'promoHotDealDesc', {
                'pack': shop.weeklyHotDealPackNumber.toString(),
                'coins': hotCoins.toString(),
              }),
              style: TextStyle(
                color: premium ? Colors.white : AppColors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            _UnlockProgress(shop: shop, light: premium),
            const SizedBox(height: 12),
            if (!shop.isBillingDisabled)
              if (hideShopButton)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.vipGoldGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => CoinPurchaseSheet.show(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            AppStrings.t(context, 'promoBuyNow'),
                            style: const TextStyle(color: AppColors.trueBlack, fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => CoinPurchaseSheet.show(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coin,
                          foregroundColor: AppColors.trueBlack,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(AppStrings.t(context, 'promoBuyNow'), style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
                        child: Text(AppStrings.t(context, 'navShop'), style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

class _UnlockProgress extends StatelessWidget {
  final ShopProvider shop;
  final bool dense;
  final bool light;

  const _UnlockProgress({required this.shop, this.dense = false, this.light = false});

  @override
  Widget build(BuildContext context) {
    final next = shop.nextUnlockItem;
    if (next == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: dense ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(context, 'promoUnlockRemaining', {'count': shop.coinsToNextUnlock.toString()}),
            style: TextStyle(
              color: light ? Colors.white.withValues(alpha: 0.65) : AppColors.onSurfaceVariant,
              fontSize: dense ? 10 : 11,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: shop.unlockProgress,
              minHeight: dense ? 5 : 7,
              backgroundColor: light ? Colors.white.withValues(alpha: 0.12) : Colors.white,
              color: light ? const Color(0xFFFBBF24) : AppColors.coin,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact promo header inside the coin purchase bottom sheet.
class CoinPurchasePromoHeader extends StatelessWidget {
  const CoinPurchasePromoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final hotIndex = shop.weeklyHotDealPackIndex;
    final total = shop.effectiveCoinsForPackIndex(hotIndex);
    final bonus = total - IapConstants.coinPackAmounts[hotIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.coin.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.coin.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.coin, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.t(context, 'purchasePromoDesc', {
                'pack': shop.weeklyHotDealPackNumber.toString(),
                'coins': total.toString(),
                'bonus': bonus.toString(),
              }),
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
          if (shop.firstPurchaseBonusAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                AppStrings.t(context, 'firstPurchaseBadge'),
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}
