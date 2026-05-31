import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tema Material 3 — light y dark — para K-china FIEI
abstract final class AppTheme {
  static const _radius = Radius.circular(14);
  static const _shape  = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(_radius),
  );

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.amber,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      scaffoldBackgroundColor: AppColors.zinc50,

      // AppBar transparente con blur — estilo moderno móvil
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.zinc900,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.zinc200,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.zinc900,
        ),
      ),

      // Bottom Navigation Bar — prominente en móvil
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.zinc400,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: _shape.copyWith(
          side: const BorderSide(color: AppColors.zinc200),
        ),
        margin: EdgeInsets.zero,
      ),

      // Inputs — tamaño mínimo 48dp para accesibilidad
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(_radius),
          borderSide: const BorderSide(color: AppColors.zinc300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(_radius),
          borderSide: const BorderSide(color: AppColors.zinc300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(_radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(_radius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(color: AppColors.zinc400, fontSize: 14),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      ),

      // ElevatedButton — CTA principal
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.45),
          minimumSize: const Size(double.infinity, 52), // tap-friendly
          shape: _shape,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          shape: _shape,
          side: const BorderSide(color: AppColors.zinc200),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.zinc200)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: const BorderSide(color: AppColors.zinc200),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.zinc300,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.zinc100,
        thickness: 1,
        space: 0,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: _shape,
        backgroundColor: AppColors.zinc900,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.amber,
        surface: AppColors.zinc900,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      scaffoldBackgroundColor: AppColors.zinc950,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.zinc900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.zinc900,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.zinc500,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.zinc900,
        shape: _shape.copyWith(
          side: const BorderSide(color: AppColors.zinc800),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.zinc900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.zinc700,
      ),
    );
  }
}
