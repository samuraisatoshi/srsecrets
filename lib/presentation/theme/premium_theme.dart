import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium theme configuration matching Trezor/Ledger standards
class PremiumTheme {
  // Premium color palette inspired by crypto leaders
  static const Color _deepBlack = Color(0xFF0A0E1A);
  static const Color _richDark = Color(0xFF141824);
  static const Color _midnightBlue = Color(0xFF1C2333);
  static const Color _steelGray = Color(0xFF2A3142);
  
  // Accent colors for trust and security
  static const Color _premiumGreen = Color(0xFF00D395);
  static const Color _securityBlue = Color(0xFF4B7BEC);
  static const Color _warningAmber = Color(0xFFFFAA00);
  static const Color _dangerRed = Color(0xFFFF4757);
  
  // Surface colors
  static const Color _surfaceLight = Color(0xFFF8FAFC);
  static const Color _surfaceDark = Color(0xFF1A1F2E);
  
  // Brand gradient colors
  static const Color _gradientStart = Color(0xFF6C5CE7);
  static const Color _gradientEnd = Color(0xFF4B7BEC);
  
  // Text colors
  static const Color _textPrimary = Color(0xFFE8ECF4);
  static const Color _textSecondary = Color(0xFFA8B3C8);
  static const Color _textTertiary = Color(0xFF6B7A90);

  /// Get premium light theme
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: _securityBlue,
        primaryContainer: Color(0xFFE8F0FF),
        secondary: _premiumGreen,
        secondaryContainer: Color(0xFFE6FFF5),
        tertiary: _gradientStart,
        surface: _surfaceLight,
        surfaceContainerHighest: Color(0xFFFFFFFF),
        surfaceContainerHigh: Color(0xFFF8FAFC),
        surfaceContainer: Color(0xFFF1F5F9),
        surfaceContainerLow: Color(0xFFE2E8F0),
        surfaceContainerLowest: Color(0xFFCBD5E1),
        error: _dangerRed,
        errorContainer: Color(0xFFFFE5E7),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1E293B),
        onSurfaceVariant: Color(0xFF64748B),
        outline: Color(0xFFCBD5E1),
        outlineVariant: Color(0xFFE2E8F0),
      ),
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1E293B),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
          letterSpacing: -0.5,
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          backgroundColor: _securityBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.05);
            }
            return null;
          }),
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        color: Colors.white,
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _securityBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _dangerRed,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  /// Get premium dark theme
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: _deepBlack,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: _securityBlue,
        primaryContainer: Color(0xFF1E3A5F),
        secondary: _premiumGreen,
        secondaryContainer: Color(0xFF00664A),
        tertiary: _gradientStart,
        surface: _surfaceDark,
        surfaceContainerHighest: _midnightBlue,
        surfaceContainerHigh: _richDark,
        surfaceContainer: _deepBlack,
        surfaceContainerLow: Color(0xFF0D1117),
        surfaceContainerLowest: Color(0xFF080B11),
        error: _dangerRed,
        errorContainer: Color(0xFF7A1E28),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _textPrimary,
        onSurfaceVariant: _textSecondary,
        outline: Color(0xFF3A4357),
        outlineVariant: Color(0xFF2A3142),
      ),
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          backgroundColor: _securityBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _steelGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.05);
            }
            return null;
          }),
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _steelGray.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        color: _richDark,
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _richDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _steelGray.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _steelGray.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _securityBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _dangerRed,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textSecondary.withValues(alpha: 0.8),
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _textTertiary.withValues(alpha: 0.7),
        ),
      ),
      
      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _richDark,
        indicatorColor: _securityBlue.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _securityBlue,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textSecondary.withValues(alpha: 0.7),
          );
        }),
      ),
    );
  }

  /// Premium gradient shader
  static Shader getPremiumGradient(Rect bounds) {
    return const LinearGradient(
      colors: [_gradientStart, _gradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(bounds);
  }

  /// Get glass morphism decoration
  static BoxDecoration getGlassMorphism({bool isDark = false}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: isDark 
          ? _richDark.withValues(alpha: 0.7)
          : Colors.white.withValues(alpha: 0.9),
      border: Border.all(
        color: isDark
            ? _steelGray.withValues(alpha: 0.3)
            : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Get premium card decoration
  static BoxDecoration getPremiumCard({
    bool isDark = false,
    bool isElevated = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: isDark
          ? LinearGradient(
              colors: [
                _richDark,
                _midnightBlue.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [
                Colors.white,
                Color(0xFFFAFBFC),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      border: Border.all(
        color: isDark
            ? _steelGray.withValues(alpha: 0.3)
            : const Color(0xFFE2E8F0),
        width: 1,
      ),
      boxShadow: isElevated
          ? [
              BoxShadow(
                color: _securityBlue.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }
}