import 'package:flutter/material.dart';

/// A class that contains all theme configurations for the network monitoring application.
class AppTheme {
  AppTheme._();

  // Color Specifications - Monochromatic Professional Palette
  // Light Theme Colors
  static const Color primaryLight = Color(0xFF2D3748); // Deep slate
  static const Color secondaryLight = Color(0xFF4A5568); // Supporting gray
  static const Color accentLight = Color(0xFF3182CE); // Trust-building blue
  static const Color successLight = Color(0xFF38A169); // Clear green
  static const Color warningLight = Color(0xFFD69E2E); // Amber
  static const Color errorLight = Color(0xFFE53E3E); // Decisive red
  static const Color backgroundLight = Color(0xFFF7FAFC); // Clean light background
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white
  static const Color textPrimaryLight = Color(0xFF1A202C); // High contrast dark
  static const Color textSecondaryLight = Color(0xFF718096); // Balanced gray
  static const Color borderLight = Color(0xFFE2E8F0); // Functional borders

  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF4A5568); // Lighter slate for dark mode
  static const Color secondaryDark = Color(0xFF718096); // Lighter supporting gray
  static const Color accentDark = Color(0xFF63B3ED); // Lighter blue for dark mode
  static const Color successDark = Color(0xFF48BB78); // Lighter green
  static const Color warningDark = Color(0xFFECC94B); // Lighter amber
  static const Color errorDark = Color(0xFFFC8181); // Lighter red
  static const Color backgroundDark = Color(0xFF1A202C); // Dark background
  static const Color surfaceDark = Color(0xFF2D3748); // Dark surface
  static const Color textPrimaryDark = Color(0xFFF7FAFC); // Light text
  static const Color textSecondaryDark = Color(0xFFA0AEC0); // Medium gray text
  static const Color borderDark = Color(0xFF4A5568); // Dark borders

  // Shadow colors with 20% opacity as per Visual Standards
  static const Color shadowLight = Color(0x33000000); // 20% opacity
  static const Color shadowDark = Color(0x33000000); // 20% opacity

  // Divider colors
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF4A5568);

  /// Light theme - Technical Minimalism with Focused Clarity
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: surfaceLight,
      primaryContainer: secondaryLight,
      onPrimaryContainer: surfaceLight,
      secondary: accentLight,
      onSecondary: surfaceLight,
      secondaryContainer: accentLight.withValues(alpha: 0.1),
      onSecondaryContainer: primaryLight,
      tertiary: successLight,
      onTertiary: surfaceLight,
      tertiaryContainer: successLight.withValues(alpha: 0.1),
      onTertiaryContainer: primaryLight,
      error: errorLight,
      onError: surfaceLight,
      surface: surfaceLight,
      onSurface: textPrimaryLight,
      onSurfaceVariant: textSecondaryLight,
      outline: borderLight,
      outlineVariant: borderLight.withValues(alpha: 0.5),
      shadow: shadowLight,
      scrim: shadowLight,
      inverseSurface: primaryLight,
      onInverseSurface: surfaceLight,
      inversePrimary: accentLight,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: surfaceLight,
    dividerColor: dividerLight,

    // AppBar Theme - Clean and professional
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceLight,
      foregroundColor: textPrimaryLight,
      elevation: 0,
      shadowColor: shadowLight,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        letterSpacing: 0.15,
      ),
      iconTheme: const IconThemeData(color: textPrimaryLight, size: 24),
    ),

    // Card Theme - Minimal elevation with subtle shadows (2-4dp blur radius)
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 2.0,
      shadowColor: shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: borderLight, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Bottom Navigation Bar Theme - Thumb-reachable primary actions
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: accentLight,
      unselectedItemColor: textSecondaryLight,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentLight,
      foregroundColor: surfaceLight,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: surfaceLight,
        backgroundColor: accentLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 2,
        shadowColor: shadowLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(color: accentLight, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    // Text Theme - Inter for headings/body, JetBrains Mono for technical data
    textTheme: _buildTextTheme(isLight: true),

    // Input Decoration Theme - Focused states with clear visual boundaries
    inputDecorationTheme: InputDecorationThemeData(
      fillColor: surfaceLight,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: accentLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: errorLight, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: errorLight, width: 2),
      ),
      labelStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: textSecondaryLight,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: textSecondaryLight.withValues(alpha: 0.6),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: textSecondaryLight,
      suffixIconColor: textSecondaryLight,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentLight;
        }
        return textSecondaryLight;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentLight.withValues(alpha: 0.5);
        }
        return textSecondaryLight.withValues(alpha: 0.3);
      }),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentLight;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(surfaceLight),
      side: BorderSide(color: borderLight, width: 2),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentLight;
        }
        return textSecondaryLight;
      }),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentLight,
      linearTrackColor: accentLight.withValues(alpha: 0.2),
      circularTrackColor: accentLight.withValues(alpha: 0.2),
    ),

    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: accentLight,
      thumbColor: accentLight,
      overlayColor: accentLight.withValues(alpha: 0.2),
      inactiveTrackColor: accentLight.withValues(alpha: 0.3),
      valueIndicatorColor: accentLight,
      valueIndicatorTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: surfaceLight,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarThemeData(
      labelColor: accentLight,
      unselectedLabelColor: textSecondaryLight,
      indicatorColor: accentLight,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
    ),

    // Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: primaryLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: surfaceLight,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // SnackBar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primaryLight,
      contentTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: surfaceLight,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: accentLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 4,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: surfaceLight,
      deleteIconColor: textSecondaryLight,
      disabledColor: textSecondaryLight.withValues(alpha: 0.3),
      selectedColor: accentLight.withValues(alpha: 0.2),
      secondarySelectedColor: accentLight.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryLight,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryLight,
      ),
      brightness: Brightness.light,
      side: BorderSide(color: borderLight, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),

    // List Tile Theme
    listTileTheme: ListTileThemeData(
      tileColor: surfaceLight,
      selectedTileColor: accentLight.withValues(alpha: 0.1),
      iconColor: textSecondaryLight,
      textColor: textPrimaryLight,
      titleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimaryLight,
        letterSpacing: 0.15,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondaryLight,
        letterSpacing: 0.25,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(color: dividerLight, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(backgroundColor: surfaceLight),
  );

  /// Dark theme - Technical Minimalism with Focused Clarity (Dark Mode)
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: textPrimaryDark,
      primaryContainer: secondaryDark,
      onPrimaryContainer: textPrimaryDark,
      secondary: accentDark,
      onSecondary: backgroundDark,
      secondaryContainer: accentDark.withValues(alpha: 0.2),
      onSecondaryContainer: textPrimaryDark,
      tertiary: successDark,
      onTertiary: backgroundDark,
      tertiaryContainer: successDark.withValues(alpha: 0.2),
      onTertiaryContainer: textPrimaryDark,
      error: errorDark,
      onError: backgroundDark,
      surface: surfaceDark,
      onSurface: textPrimaryDark,
      onSurfaceVariant: textSecondaryDark,
      outline: borderDark,
      outlineVariant: borderDark.withValues(alpha: 0.5),
      shadow: shadowDark,
      scrim: shadowDark,
      inverseSurface: surfaceLight,
      onInverseSurface: textPrimaryLight,
      inversePrimary: accentLight,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: surfaceDark,
    dividerColor: dividerDark,

    // AppBar Theme
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceDark,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      shadowColor: shadowDark,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        letterSpacing: 0.15,
      ),
      iconTheme: const IconThemeData(color: textPrimaryDark, size: 24),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 2.0,
      shadowColor: shadowDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: borderDark, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: accentDark,
      unselectedItemColor: textSecondaryDark,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentDark,
      foregroundColor: backgroundDark,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: backgroundDark,
        backgroundColor: accentDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 2,
        shadowColor: shadowDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(color: accentDark, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),

    // Text Theme
    textTheme: _buildTextTheme(isLight: false),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationThemeData(
      fillColor: surfaceDark,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderDark, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: accentDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: errorDark, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: errorDark, width: 2),
      ),
      labelStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: textSecondaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: textSecondaryDark.withValues(alpha: 0.6),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: textSecondaryDark,
      suffixIconColor: textSecondaryDark,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentDark;
        }
        return textSecondaryDark;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentDark.withValues(alpha: 0.5);
        }
        return textSecondaryDark.withValues(alpha: 0.3);
      }),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentDark;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(backgroundDark),
      side: BorderSide(color: borderDark, width: 2),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentDark;
        }
        return textSecondaryDark;
      }),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentDark,
      linearTrackColor: accentDark.withValues(alpha: 0.2),
      circularTrackColor: accentDark.withValues(alpha: 0.2),
    ),

    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: accentDark,
      thumbColor: accentDark,
      overlayColor: accentDark.withValues(alpha: 0.2),
      inactiveTrackColor: accentDark.withValues(alpha: 0.3),
      valueIndicatorColor: accentDark,
      valueIndicatorTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: backgroundDark,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarThemeData(
      labelColor: accentDark,
      unselectedLabelColor: textSecondaryDark,
      indicatorColor: accentDark,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
    ),

    // Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: primaryDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: textPrimaryDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // SnackBar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primaryDark,
      contentTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: textPrimaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: accentDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 4,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: surfaceDark,
      deleteIconColor: textSecondaryDark,
      disabledColor: textSecondaryDark.withValues(alpha: 0.3),
      selectedColor: accentDark.withValues(alpha: 0.2),
      secondarySelectedColor: accentDark.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
      ),
      brightness: Brightness.dark,
      side: BorderSide(color: borderDark, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),

    // List Tile Theme
    listTileTheme: ListTileThemeData(
      tileColor: surfaceDark,
      selectedTileColor: accentDark.withValues(alpha: 0.2),
      iconColor: textSecondaryDark,
      textColor: textPrimaryDark,
      titleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimaryDark,
        letterSpacing: 0.15,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondaryDark,
        letterSpacing: 0.25,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(color: dividerDark, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(backgroundColor: surfaceDark),
  );

  /// Helper method to build text theme based on brightness
  /// Uses Inter for headings/body and JetBrains Mono for technical data
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textHighEmphasis = isLight ? textPrimaryLight : textPrimaryDark;
    final Color textMediumEmphasis = isLight ? textSecondaryLight : textSecondaryDark;

    return TextTheme(
      // Display styles - Inter with appropriate weights
      displayLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: textHighEmphasis,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),

      // Headline styles - Inter for screen titles and section headers
      headlineLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),

      // Title styles - Inter for component titles
      titleLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.1,
      ),

      // Body styles - Inter for extended reading
      bodyLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textMediumEmphasis,
        letterSpacing: 0.4,
      ),

      // Label styles - Inter for buttons and labels
      labelLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textMediumEmphasis,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Helper method to get JetBrains Mono text style for technical data
  /// Use this for timestamps, URLs, IP addresses, ports, and numerical data
  static TextStyle getMonospaceStyle({
    required bool isLight,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: 'Tajawal',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isLight ? textPrimaryLight : textPrimaryDark,
      letterSpacing: 0,
    );
  }

  /// Helper method to get caption style with JetBrains Mono
  /// Use this for metadata and supporting technical information
  static TextStyle getCaptionMonospaceStyle({
    required bool isLight,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: 'Tajawal',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isLight ? textSecondaryLight : textSecondaryDark,
      letterSpacing: 0,
    );
  }
}
