import 'package:decision_replay/providers/shop_provider.dart';
import 'package:decision_replay/widgets/coin_purchase_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('coin pack sheet stays under 72% of the screen', (tester) async {
    final shop = ShopProvider();
    shop.billing.isAvailable = true;
    shop.billing.coinProducts = List.generate(
      8,
      (i) => ProductDetails(
        id: 'dr_pack_${i + 1}',
        title: 'Pack ${i + 1}',
        description: 'Coins',
        price: '\$${i + 1}.99',
        rawPrice: (i + 1).toDouble(),
        currencyCode: 'USD',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: shop,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => CoinPurchaseSheet.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Processing purchase…'), findsNothing);
    expect(find.text('\$1.99'), findsOneWidget);
    expect(find.text('Earn coins by creating notes, daily login & spin wheel'), findsOneWidget);

    final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final sheetTop = tester.getTopLeft(find.text('Buy Coins')).dy;
    expect(sheetTop, greaterThan(screen * 0.2));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Buy Coins'), findsNothing);
  });

  testWidgets('empty billing sheet hugs content instead of filling the screen', (tester) async {
    final shop = ShopProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: shop,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => CoinPurchaseSheet.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final sheetTop = tester.getTopLeft(find.text('Buy Coins')).dy;
    final sheetBottom = tester.getBottomLeft(find.text('Earn coins by creating notes, daily login & spin wheel')).dy;
    expect(sheetBottom - sheetTop, lessThan(screen * 0.72));
    expect(find.text('Billing unavailable on this device'), findsOneWidget);
    expect(find.text('Processing purchase…'), findsNothing);
  });
}
