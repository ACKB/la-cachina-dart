/// Entidad de dominio: Perfil público del vendedor con calificación de estrellas.
///
/// Mapeada desde la vista `public.v_seller_profiles` de Supabase.
class SellerProfile {
  final String sellerId;
  final String sellerName;
  final String? whatsappNumber;
  final bool emailVerified;

  /// Promedio de estrellas (0.0 – 5.0). 0.0 = sin calificaciones aún.
  final double avgStars;

  /// Total de calificaciones recibidas.
  final int totalRatings;

  /// Total de productos vendidos (historial completo).
  final int totalSold;

  /// Distribución de estrellas
  final int stars5;
  final int stars4;
  final int stars3;
  final int stars2;
  final int stars1;

  /// Nivel calculado por la BD: 'Nuevo', 'Regular', 'Confiable', 'Top Vendedor ⭐'
  final String sellerLevel;

  const SellerProfile({
    required this.sellerId,
    required this.sellerName,
    this.whatsappNumber,
    required this.emailVerified,
    required this.avgStars,
    required this.totalRatings,
    required this.totalSold,
    required this.stars5,
    required this.stars4,
    required this.stars3,
    required this.stars2,
    required this.stars1,
    required this.sellerLevel,
  });

  /// Verdadero si tiene al menos una calificación.
  bool get hasRatings => totalRatings > 0;

  /// Primer nombre para usar en avatares.
  String get firstName => sellerName.split(' ').first;
}
