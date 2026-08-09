import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/app_theme_preset.dart';
import '../models/shop_item.dart';
import '../providers/shop_provider.dart';

/// Shared layout spacing for screens.
class AppSpacing {
  AppSpacing._();

  static const double screenH = 12;
  static const double screenBottom = 88;
}

class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final onSurface = brightness == Brightness.dark ? const Color(0xFFF5F5F5) : AppColors.textPrimary;
    final onVariant = brightness == Brightness.dark ? const Color(0xFFD6D3D1) : AppColors.textSecondary;
    final base = GoogleFonts.interTextTheme();
    return base.apply(bodyColor: onSurface, displayColor: onSurface).copyWith(
          bodyLarge: base.bodyLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w400),
          bodyMedium: base.bodyMedium?.copyWith(color: onSurface),
          bodySmall: base.bodySmall?.copyWith(color: onVariant),
          titleLarge: base.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
          titleMedium: base.titleMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
          labelMedium: base.labelMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w500),
        );
  }

  static TextStyle playfair({
    double size = 24,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: height,
      );

  static TextStyle journalTitle({Color? color}) =>
      GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: color ?? AppColors.onSurface);

  static TextStyle displayLarge({Color? color}) =>
      GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: color);

  static TextStyle titleLarge({Color? color}) =>
      GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle labelBold({Color? color, double size = 12}) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextStyle body({Color? color, double size = 15}) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: FontWeight.w400, height: 1.65, color: color ?? AppColors.onSurface);
}

class AppDecorations {
  static BoxDecoration journalCard({required bool isDark, CardStyle? skin, double? radius}) {
    final style = skin ?? CardStyle.defaultStyle;
    final r = radius ?? style.borderRadius;
    if (style.glassEffect) {
      return glassCard(isDark: isDark, radius: r);
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(r),
      color: isDark ? AppColors.darkSurface : Colors.white,
      border: Border.all(
        color: style.borderWidth > 0
            ? style.borderColor
            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04)),
        width: style.borderWidth > 0 ? style.borderWidth : 1,
      ),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: style.accentColor.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static BoxDecoration glassCard({required bool isDark, double radius = 24}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.94),
        border: Border.all(color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static Widget cleanBackground({required bool isDark, required Widget child}) {
    return ColoredBox(
      color: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F5),
      child: child,
    );
  }

  static Widget meshBackground({
    required bool isDark,
    required Widget child,
    LinearGradient? accentGradient,
    bool lite = false,
  }) {
    if (lite) {
      return ColoredBox(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        child: child,
      );
    }

    final gradient = accentGradient;
    final useCustom = gradient != null && gradient.colors.length >= 2;

    return ColoredBox(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (useCustom)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient.colors.map((c) => c.withValues(alpha: isDark ? 0.1 : 0.06)).toList(),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const GlowOrb({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class AppPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Widget> children;
  final Widget? floatingActionButton;
  final bool embedded;

  const AppPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.children,
    this.floatingActionButton,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleLarge()),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 8, AppSpacing.screenH, AppSpacing.screenBottom),
              children: children,
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return content;
    }

    final shop = context.watch<ShopProvider>();
    final preset = shop.activeTheme;

    return Scaffold(
      backgroundColor: isDark ? preset.darkBackground : preset.background,
      floatingActionButton: floatingActionButton,
      body: AppDecorations.meshBackground(
        isDark: isDark,
        accentGradient: shop.activeBackground.id == ShopCatalog.defaultBackgroundId
            ? null
            : shop.activeBackground.gradient,
        child: content,
      ),
    );
  }
}

class AppScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;

  const AppScreenHeader({super.key, required this.title, required this.subtitle, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 0, compact ? 0 : 0, 16, compact ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleLarge()),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13, height: 1.35)),
          ],
        ],
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String label;
  final IconData? icon;

  const AppSectionHeader(this.label, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8, left: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
          ],
          Text(label, style: AppTypography.labelBold(color: AppColors.onSurfaceVariant, size: 13)),
        ],
      ),
    );
  }
}

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double? radius;
  final CardStyle? cardStyle;
  final bool? isDark;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius,
    this.cardStyle,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final style = cardStyle ?? context.read<ShopProvider>().activeCardStyle;
    final r = radius ?? style.borderRadius;
    final decoration = style.glassEffect
        ? AppDecorations.glassCard(isDark: dark, radius: r)
        : BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            color: dark ? AppColors.darkSurface.withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.94),
            border: Border.all(
              color: style.borderWidth > 0 ? style.borderColor : (dark ? Colors.white : AppColors.primary).withValues(alpha: 0.1),
              width: style.borderWidth > 0 ? style.borderWidth : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: style.accentColor.withValues(alpha: dark ? 0.14 : 0.07),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          );
    final box = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(r), child: box),
    );
  }
}

class AppSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const AppSettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppGlassCard(
        padding: EdgeInsets.zero,
        radius: 18,
        onTap: onTap,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: AppTypography.labelBold(size: 14)),
          subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)) : null,
          trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)) : null),
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 44, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.primary : AppColors.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? selectedColor : AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

