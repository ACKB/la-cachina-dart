import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/seller_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Fila de estrellas (solo lectura)
// ─────────────────────────────────────────────────────────────────────────────

/// Muestra estrellas rellenas/medias/vacías según [rating] (0.0–5.0).
class StarRow extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;
  final bool showCount;

  const StarRow({
    super.key,
    required this.rating,
    this.totalRatings = 0,
    this.size = 18,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.floor();
          final half   = !filled && (i < rating);
          return Icon(
            filled
                ? Icons.star_rounded
                : half
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size:  size,
            color: rating > 0 ? AppColors.amber : AppColors.zinc300,
          );
        }),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            totalRatings == 0
                ? 'Sin calificaciones'
                : '$rating · $totalRatings ${totalRatings == 1 ? 'calificación' : 'calificaciones'}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.zinc500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Estrellas interactivas (para calificar)
// ─────────────────────────────────────────────────────────────────────────────

class InteractiveStarRow extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;
  final double size;

  const InteractiveStarRow({
    super.key,
    this.initialValue = 0,
    required this.onChanged,
    this.size = 40,
  });

  @override
  State<InteractiveStarRow> createState() => _InteractiveStarRowState();
}

class _InteractiveStarRowState extends State<InteractiveStarRow> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _selected = starValue);
            widget.onChanged(starValue);
          },
          child: AnimatedScale(
            scale: _selected >= starValue ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Icon(
              _selected >= starValue
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size:  widget.size,
              color: _selected >= starValue ? AppColors.amber : AppColors.zinc300,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Card completa del perfil del vendedor con estrellas
// ─────────────────────────────────────────────────────────────────────────────

class SellerProfileCard extends StatelessWidget {
  final SellerProfile profile;

  const SellerProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.zinc100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título sección
          Text('👤 Vendedor', style: AppTextStyles.headlineSm),
          const SizedBox(height: 12),

          // Fila: Avatar + Nombre + Nivel
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight.withOpacity(0.15),
                child: Text(
                  profile.firstName.isNotEmpty
                      ? profile.firstName[0].toUpperCase()
                      : 'V',
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.sellerName,
                            style: AppTextStyles.bodyMd
                                .copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.emailVerified) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Correo @unfv.edu.pe verificado',
                            child: Icon(Icons.verified_rounded,
                                size: 16, color: AppColors.info),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    _LevelBadge(profile.sellerLevel),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Promedio de estrellas
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (profile.hasRatings)
                Text(
                  profile.avgStars.toStringAsFixed(1),
                  style: AppTextStyles.headlineSm.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.zinc800,
                  ),
                ),
              if (profile.hasRatings) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StarRow(
                      rating:       profile.avgStars,
                      totalRatings: profile.totalRatings,
                      size:         20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.totalSold} ${profile.totalSold == 1 ? 'venta completada' : 'ventas completadas'}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Distribución de estrellas (barra de progreso por estrella)
          if (profile.hasRatings) ...[
            const SizedBox(height: 12),
            ...List.generate(5, (i) {
              final star  = 5 - i;
              final count = [
                profile.stars5, profile.stars4, profile.stars3,
                profile.stars2, profile.stars1,
              ][i];
              final fraction = profile.totalRatings > 0
                  ? count / profile.totalRatings
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('$star', style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.zinc500)),
                    const SizedBox(width: 4),
                    Icon(Icons.star_rounded, size: 12, color: AppColors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value:           fraction,
                          backgroundColor: AppColors.zinc100,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.amber),
                          minHeight: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$count',
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.zinc500),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget: Badge de nivel del vendedor
// ─────────────────────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge(this.level);

  Color get _bg {
    if (level.contains('Top'))      return const Color(0xFFFEF9C3);
    if (level == 'Confiable')       return AppColors.successSurface;
    if (level == 'Regular')         return AppColors.infoSurface;
    if (level == 'En observación')  return AppColors.errorSurface;
    return AppColors.zinc100;
  }

  Color get _fg {
    if (level.contains('Top'))      return const Color(0xFF713F12);
    if (level == 'Confiable')       return AppColors.success;
    if (level == 'Regular')         return AppColors.info;
    if (level == 'En observación')  return AppColors.error;
    return AppColors.zinc500;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(level,
          style: AppTextStyles.labelSm.copyWith(
              color: _fg, fontWeight: FontWeight.w600)),
    );
  }
}
