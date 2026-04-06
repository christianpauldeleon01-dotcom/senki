import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trak_design_system.dart';

/// ========================================
/// TRAK THEME - BLACK & WHITE EDITION
/// ========================================
/// Supports both Light and Dark modes with strict B&W aesthetic

class TrakTheme {
  /// Dark theme - Pure black background, white foreground
  static CupertinoThemeData get darkTheme {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      // Primary - White
      primaryColor: NeonColors.primary,
      primaryContrastingColor: NeonColors.background,
      // Scaffold & Background
      scaffoldBackgroundColor: NeonColors.background,
      // Bar & Navigation
      barBackgroundColor: NeonColors.backgroundSecondary,
      // Text
      textTheme: CupertinoTextThemeData(
        primaryColor: NeonColors.textPrimary,
        textStyle: TextStyle(
          color: NeonColors.textPrimary,
          fontFamily: NeonTypography.fontFamily,
        ),
        navTitleTextStyle: TextStyle(
          color: NeonColors.textPrimary,
          fontFamily: NeonTypography.fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        navLargeTitleTextStyle: TextStyle(
          color: NeonColors.textPrimary,
          fontFamily: NeonTypography.fontFamily,
          fontSize: 34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Light theme - Pure white background, black foreground
  static CupertinoThemeData get lightTheme {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      // Primary - Black
      primaryColor: LightModeColors.primary,
      primaryContrastingColor: LightModeColors.secondary,
      // Scaffold & Background
      scaffoldBackgroundColor: LightModeColors.background,
      // Bar & Navigation
      barBackgroundColor: LightModeColors.backgroundSecondary,
      // Text
      textTheme: CupertinoTextThemeData(
        primaryColor: LightModeColors.textPrimary,
        textStyle: TextStyle(
          color: LightModeColors.textPrimary,
          fontFamily: NeonTypography.fontFamily,
        ),
        navTitleTextStyle: TextStyle(
          color: LightModeColors.textPrimary,
          fontFamily: NeonTypography.fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        navLargeTitleTextStyle: TextStyle(
          color: LightModeColors.textPrimary,
          fontFamily: NeonTypography.fontFamily,
          fontSize: 34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Get theme based on mode
  static CupertinoThemeData getTheme(TrakThemeMode mode) {
    return mode == TrakThemeMode.dark ? darkTheme : lightTheme;
  }

  /// Current theme based on mode
  static CupertinoThemeData get current => getTheme(currentThemeMode);
}

/// Theme Mode Provider for Riverpod
class ThemeModeNotifier extends StateNotifier<TrakThemeMode> {
  ThemeModeNotifier() : super(TrakThemeMode.dark);

  void toggle() {
    state = state == TrakThemeMode.dark ? TrakThemeMode.light : TrakThemeMode.dark;
    currentThemeMode = state;
    themeChangeNotifier.value = state;
  }

  void setDark() {
    state = TrakThemeMode.dark;
    currentThemeMode = state;
    themeChangeNotifier.value = state;
  }

  void setLight() {
    state = TrakThemeMode.light;
    currentThemeMode = state;
    themeChangeNotifier.value = state;
  }
}

/// Extension for easy access to B&W colors
extension TrakThemeExtension on BuildContext {
  /// Convenience getters for current theme colors
  TrakThemeMode get themeMode => currentThemeMode;
  bool get isDarkMode => currentThemeMode == TrakThemeMode.dark;
  bool get isLightMode => currentThemeMode == TrakThemeMode.light;
  
  /// Background colors
  Color get backgroundColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.background : LightModeColors.background;
  }
  
  Color get surfaceColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.surface : LightModeColors.surface;
  }
  
  Color get elevatedColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.surfaceElevated : LightModeColors.surfaceElevated;
  }
  
  /// Text colors
  Color get textPrimaryColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.textPrimary : LightModeColors.textPrimary;
  }
  
  Color get textSecondaryColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.textSecondary : LightModeColors.textSecondary;
  }
  
  Color get textTertiaryColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.textTertiary : LightModeColors.textTertiary;
  }
  
  /// Brand colors
  Color get primaryColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.primary : LightModeColors.primary;
  }
  
  Color get secondaryColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.secondary : LightModeColors.secondary;
  }
  
  /// Semantic colors
  Color get successColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.success : LightModeColors.success;
  }
  
  Color get warningColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.warning : LightModeColors.warning;
  }
  
  Color get errorColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.error : LightModeColors.error;
  }
  
  /// Borders
  Color get borderColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.border : LightModeColors.border;
  }
  
  Color get dividerColor {
    final isDark = currentThemeMode == TrakThemeMode.dark;
    return isDark ? NeonColors.divider : LightModeColors.divider;
  }
}
