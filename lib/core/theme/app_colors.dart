import 'package:flutter/material.dart';

/// Tokens de color del design system K-china FIEI
///
/// Basados en la paleta naranja-zinc del proyecto Next.js original.
/// Úsalos siempre desde aquí; nunca hardcodees colores en los widgets.
abstract final class AppColors {
  // ── Primary (naranja FIEI) ──────────────────────────────────────────────────
  static const Color primary         = Color(0xFFEA580C); // orange-600
  static const Color primaryLight    = Color(0xFFF97316); // orange-500
  static const Color primaryDark     = Color(0xFFC2410C); // orange-700
  static const Color amber           = Color(0xFFF59E0B); // amber-500

  // ── Superficie / Zinc ───────────────────────────────────────────────────────
  static const Color zinc50          = Color(0xFFFAFAFA);
  static const Color zinc100         = Color(0xFFF4F4F5);
  static const Color zinc200         = Color(0xFFE4E4E7);
  static const Color zinc300         = Color(0xFFD4D4D8);
  static const Color zinc400         = Color(0xFFA1A1AA);
  static const Color zinc500         = Color(0xFF71717A);
  static const Color zinc600         = Color(0xFF52525B);
  static const Color zinc700         = Color(0xFF3F3F46);
  static const Color zinc800         = Color(0xFF27272A);
  static const Color zinc900         = Color(0xFF18181B);
  static const Color zinc950         = Color(0xFF09090B);

  // ── Semánticos ──────────────────────────────────────────────────────────────
  static const Color success         = Color(0xFF16A34A); // green-600
  static const Color successSurface  = Color(0xFFF0FDF4); // green-50
  static const Color error           = Color(0xFFDC2626); // red-600
  static const Color errorSurface    = Color(0xFFFEF2F2); // red-50
  static const Color info            = Color(0xFF2563EB); // blue-600
  static const Color infoSurface     = Color(0xFFEFF6FF); // blue-50
  static const Color warning         = Color(0xFFD97706); // amber-600
  static const Color warningSurface  = Color(0xFFFFFBEB); // amber-50

  // ── Gradientes ──────────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEA580C), Color(0xFFF97316), Color(0xFFF59E0B)],
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, amber],
  );
}
