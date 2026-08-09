import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/shop_item.dart';
import '../providers/shop_provider.dart';
import '../screens/shop/shop_screen.dart';
import 'app_toast.dart';
import 'coin_purchase_sheet.dart';

class ShopPurchaseUi {
  ShopPurchaseUi._();

  static void showInsufficientCoins(BuildContext context, ShopProvider shop, ShopItem item) {
    AppToast.show(
      context,
      title: AppStrings.t(context, 'insufficientCoins'),
      message: AppStrings.t(context, 'insufficientCoinsDetail', {
        'price': '${item.price}',
        'balance': '${shop.coins}',
      }),
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
      actionLabel: AppStrings.t(context, 'getMorePoints'),
      onAction: () => _openPointsStore(context, shop),
    );

    _openPointsStore(context, shop);
  }

  static void _openPointsStore(BuildContext context, ShopProvider shop) {
    if (!shop.isBillingDisabled) {
      CoinPurchaseSheet.show(context);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
  }
}
