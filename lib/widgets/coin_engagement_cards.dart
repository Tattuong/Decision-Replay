import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_ui.dart';
import 'coin_purchase_sheet.dart';

class CoinEngagementCards extends StatefulWidget {
  const CoinEngagementCards({super.key});

  @override
  State<CoinEngagementCards> createState() => _CoinEngagementCardsState();
}

class _CoinEngagementCardsState extends State<CoinEngagementCards> {
  bool _dailyClaimed = false;
  bool _spinUsed = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final shop = context.read<ShopProvider>();
    final daily = await shop.hasClaimedDailyToday();
    final spin = await shop.hasSpunToday();
    if (mounted) setState(() { _dailyClaimed = daily; _spinUsed = spin; });
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.t(context, 'earnCoins'), style: AppTypography.titleLarge().copyWith(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          AppStrings.t(context, 'earnCoinsDesc'),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3),
        ),
        const SizedBox(height: 10),
        _EngagementCard(
          icon: Icons.calendar_today_outlined,
          title: AppStrings.t(context, 'dailyReward'),
          subtitle: AppStrings.t(context, 'loginStreak', {'days': shop.loginStreak.toString()}),
          buttonLabel: _dailyClaimed ? AppStrings.t(context, 'dailyClaimed') : AppStrings.t(context, 'claimDaily'),
          enabled: !_dailyClaimed,
          color: AppColors.success,
          onTap: () async {
            await shop.claimDailyReward();
            if (context.mounted) _refresh();
          },
        ),
        const SizedBox(height: 8),
        _EngagementCard(
          icon: Icons.casino_outlined,
          title: AppStrings.t(context, 'spinWheel'),
          subtitle: AppStrings.t(context, 'spinNow'),
          buttonLabel: _spinUsed ? AppStrings.t(context, 'spinUsed') : AppStrings.t(context, 'spinNow'),
          enabled: !_spinUsed,
          color: AppColors.coin,
          onTap: () async {
            await shop.spinDailyWheel();
            if (context.mounted) _refresh();
          },
        ),
        if (!shop.isBillingDisabled) ...[
          const SizedBox(height: 8),
          _EngagementCard(
            icon: Icons.shopping_bag_outlined,
            title: AppStrings.t(context, 'buyCoins'),
            subtitle: AppStrings.t(context, 'buyCoinsDesc'),
            buttonLabel: AppStrings.t(context, 'promoBuyShort'),
            enabled: true,
            color: AppColors.primary,
            onTap: () => CoinPurchaseSheet.show(context),
          ),
        ],
      ],
    );
  }
}

class _EngagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _EngagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelBold(size: 13),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: enabled ? onTap : null,
                style: FilledButton.styleFrom(
                  backgroundColor: enabled ? AppColors.primary : AppColors.surfaceVariant,
                  foregroundColor: enabled ? Colors.white : AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(buttonLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
