import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/app_ui.dart';

class AppThemePreset {
  final String id;
  final Color primary;
  final Color primaryLight;
  final Color background;
  final Color surface;
  final Color darkBackground;
  final Color darkSurface;
  final LinearGradient headerGradient;
  final LinearGradient balanceGradient;

  const AppThemePreset({
    required this.id,
    required this.primary,
    required this.primaryLight,
    required this.background,
    required this.surface,
    required this.darkBackground,
    required this.darkSurface,
    required this.headerGradient,
    required this.balanceGradient,
  });

  ThemeData lightTheme() => _buildTheme(
        brightness: Brightness.light,
        scaffold: background,
        surfaceColor: surface,
        onSurface: AppColors.textPrimary,
      );

  ThemeData darkTheme() => _buildTheme(
        brightness: Brightness.dark,
        scaffold: darkBackground,
        surfaceColor: darkSurface,
        onSurface: const Color(0xFFF5F5F5),
      );

  ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color surfaceColor,
    required Color onSurface,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primaryLight,
              secondary: primary,
              surface: surfaceColor,
              onSurface: onSurface,
              onSurfaceVariant: AppColors.textSecondary,
            )
          : ColorScheme.light(
              primary: primary,
              secondary: primaryLight,
              surface: surfaceColor,
              onSurface: onSurface,
              onSurfaceVariant: AppColors.textSecondary,
            ),
      textTheme: AppTypography.textTheme(brightness),
      iconTheme: IconThemeData(color: onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: isDark ? const Color(0xFFA8A29E) : AppColors.textMuted),
        border: InputBorder.none,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primary,
        disabledColor: surfaceColor,
        labelStyle: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        side: BorderSide(color: isDark ? Colors.white24 : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: onSurface,
        titleTextStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
        subtitleTextStyle: TextStyle(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? Colors.white12 : AppColors.border),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: AppColors.onPrimary,
      ),
    );
  }
}

class AppThemePresets {
  AppThemePresets._();

  static const defaultPreset = AppThemePreset(
    id: 'theme_default',
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    background: AppColors.background,
    surface: AppColors.surface,
    darkBackground: AppColors.darkBackground,
    darkSurface: AppColors.darkSurface,
    headerGradient: LinearGradient(colors: [Color(0xFFF5F3EE), Color(0xFFEFF6FF)]),
    balanceGradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
  );

  static const ocean = AppThemePreset(
    id: 'theme_ocean',
    primary: Color(0xFF0284C7),
    primaryLight: Color(0xFF38BDF8),
    background: Color(0xFFF0F9FF),
    surface: Colors.white,
    darkBackground: Color(0xFF0C4A6E),
    darkSurface: Color(0xFF075985),
    headerGradient: LinearGradient(colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)]),
    balanceGradient: LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)]),
  );

  static const rose = AppThemePreset(
    id: 'theme_rose',
    primary: Color(0xFFE11D48),
    primaryLight: Color(0xFFFB7185),
    background: Color(0xFFFFF1F2),
    surface: Colors.white,
    darkBackground: Color(0xFF4C0519),
    darkSurface: Color(0xFF881337),
    headerGradient: LinearGradient(colors: [Color(0xFFFFE4E6), Color(0xFFFECDD3)]),
    balanceGradient: LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFE11D48)]),
  );

  static const midnight = AppThemePreset(
    id: 'theme_midnight',
    primary: Color(0xFF6366F1),
    primaryLight: Color(0xFF818CF8),
    background: Color(0xFFEEF2FF),
    surface: Colors.white,
    darkBackground: Color(0xFF1E1B4B),
    darkSurface: Color(0xFF312E81),
    headerGradient: LinearGradient(colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)]),
    balanceGradient: LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF6366F1)]),
  );

  static const Map<String, AppThemePreset> byId = {
    'theme_default': defaultPreset,
    'theme_ocean': ocean,
    'theme_rose': rose,
    'theme_midnight': midnight,
  };

  static AppThemePreset get(String? id) => byId[id] ?? defaultPreset;
}

class AppBackground {
  final String id;
  final LinearGradient gradient;

  const AppBackground({required this.id, required this.gradient});

  static const defaultBg = AppBackground(
    id: 'bg_default',
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
    ),
  );

  static const linen = AppBackground(
    id: 'bg_linen',
    gradient: LinearGradient(colors: [Color(0xFFF5F0E8), Color(0xFFEDE4D8)]),
  );

  static const sky = AppBackground(
    id: 'bg_sky',
    gradient: LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
  );

  static const bloom = AppBackground(
    id: 'bg_bloom',
    gradient: LinearGradient(colors: [Color(0xFFFFF1F2), Color(0xFFFCE7F3), Color(0xFFEDE9FE)]),
  );

  static const Map<String, AppBackground> byId = {
    'bg_default': defaultBg,
    'bg_linen': linen,
    'bg_sky': sky,
    'bg_bloom': bloom,
  };

  static AppBackground get(String? id) => byId[id] ?? defaultBg;
}

class CardStyle {
  final String id;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color accentColor;
  final bool glassEffect;

  const CardStyle({
    required this.id,
    this.borderRadius = 18,
    this.borderWidth = 0,
    this.borderColor = Colors.transparent,
    this.accentColor = AppColors.primary,
    this.glassEffect = false,
  });

  static const defaultStyle = CardStyle(id: 'skin_default');

  static const soft = CardStyle(id: 'skin_soft', borderRadius: 24);

  static const bold = CardStyle(
    id: 'skin_bold',
    borderRadius: 14,
    borderWidth: 2,
    borderColor: AppColors.primary,
  );

  static const Map<String, CardStyle> byId = {
    'skin_default': defaultStyle,
    'skin_soft': soft,
    'skin_bold': bold,
  };

  static CardStyle get(String? id) => byId[id] ?? defaultStyle;
}
