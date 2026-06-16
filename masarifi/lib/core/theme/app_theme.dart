import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const darkBlue = Color(0xFF0A1628);
  static const navyBlue = Color(0xFF132238);
  static const cardBlue = Color(0xFF1A3050);
  static const neonBlue = Color(0xFF00E5FF);
  static const neonBlueDim = Color(0xFF00B4D8);
  static const accentPurple = Color(0xFF7B61FF);
  /// زوج ألوان مسطح متوازن — نفس الإضاءة بدون تدرج
  static const incomeGreen = Color(0xFF8FBDB2);
  static const expenseRed = Color(0xFFBDACAC);
  static const warningOrange = Color(0xFFE8B86D);
  static const textPrimary = Color(0xFFF0F4F8);
  static const textSecondary = Color(0xFF94A3B8);
  static const divider = Color(0xFF2A4060);

  static const _surfaceBlend = 0.14;
  static const _iconBlend = 0.22;
  static const _borderAlpha = 0.45;

  /// خلفية بطاقة بلون واحد مسطح
  static Color cardSurface(Color accent) => Color.alphaBlend(
        accent.withValues(alpha: _surfaceBlend),
        cardBlue,
      );

  static Color iconBackground(Color accent) => Color.alphaBlend(
        accent.withValues(alpha: _iconBlend),
        cardBlue,
      );

  static Color cardBorder(Color accent) =>
      accent.withValues(alpha: _borderAlpha);

  static Color softFill(Color accent) =>
      accent.withValues(alpha: 0.12);
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.cairoTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.cairo().fontFamily,
      scaffoldBackgroundColor: AppColors.darkBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonBlue,
        secondary: AppColors.neonBlueDim,
        surface: AppColors.navyBlue,
        error: AppColors.expenseRed,
        onPrimary: AppColors.darkBlue,
        onSecondary: AppColors.darkBlue,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navyBlue,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardBlue,
        elevation: 4,
        shadowColor: AppColors.neonBlue.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.neonBlue.withValues(alpha: 0.2)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.neonBlue,
        foregroundColor: AppColors.darkBlue,
        elevation: 6,
        extendedTextStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.navyBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.neonBlue.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neonBlue, width: 2),
        ),
        labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.navyBlue,
        selectedItemColor: AppColors.neonBlue,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11),
      ),
      tabBarTheme: TabBarTheme(
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.navyBlue,
        selectedColor: AppColors.neonBlue.withValues(alpha: 0.3),
        labelStyle: GoogleFonts.cairo(color: AppColors.textPrimary),
        side: BorderSide(color: AppColors.neonBlue.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardBlue,
        contentTextStyle: GoogleFonts.cairo(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: GoogleFonts.cairo(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}
