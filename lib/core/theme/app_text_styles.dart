import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Estilos de texto del design system K-china FIEI
abstract final class AppTextStyles {
  // ── Display ─────────────────────────────────────────────────────────────────
  static TextStyle get displayLg => GoogleFonts.outfit(
        fontSize: 42, fontWeight: FontWeight.w800,
        letterSpacing: -1.5, height: 1.1,
      );

  static TextStyle get displayMd => GoogleFonts.outfit(
        fontSize: 32, fontWeight: FontWeight.w800,
        letterSpacing: -1.0, height: 1.15,
      );

  // ── Headlines ───────────────────────────────────────────────────────────────
  static TextStyle get headlineLg => GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMd => GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle get headlineSm => GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w700,
      );

  // ── Títulos de sección ──────────────────────────────────────────────────────
  static TextStyle get titleMd => GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w600,
      );

  static TextStyle get titleSm => GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w600,
      );

  // ── Body ────────────────────────────────────────────────────────────────────
  static TextStyle get bodyLg => GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w400, height: 1.6,
      );

  static TextStyle get bodyMd => GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
      );

  static TextStyle get bodySm => GoogleFonts.outfit(
        fontSize: 12, fontWeight: FontWeight.w400, height: 1.5,
      );

  // ── Labels ─────────────────────────────────────────────────────────────────
  static TextStyle get labelLg => GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w500,
      );

  static TextStyle get labelMd => GoogleFonts.outfit(
        fontSize: 12, fontWeight: FontWeight.w500,
      );

  static TextStyle get labelSm => GoogleFonts.outfit(
        fontSize: 10, fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      );

  // ── Precio (display especial) ───────────────────────────────────────────────
  static TextStyle get price => GoogleFonts.outfit(
        fontSize: 22, fontWeight: FontWeight.w900,
        color: AppColors.primary, letterSpacing: -0.5,
      );

  static TextStyle get priceSmall => GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w900,
        color: AppColors.primary,
      );
}
