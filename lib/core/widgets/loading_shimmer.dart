import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Shimmer skeleton genérico para estados de carga
///
/// Úsalo en cualquier pantalla mientras los datos cargan.
/// Imita la forma del contenido real para reducir el CLS (layout shift).
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.zinc100,
      highlightColor: AppColors.zinc50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.zinc100,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Skeleton de card de producto para el catálogo
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.zinc200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          LoadingShimmer(
            height: 170,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          const SizedBox(height: 12),
          // Título
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(height: 14, width: double.infinity),
                SizedBox(height: 8),
                LoadingShimmer(height: 12, width: 120),
                SizedBox(height: 12),
                LoadingShimmer(height: 22, width: 80),
                SizedBox(height: 14),
              ],
            ),
          ),
          // Botón
          LoadingShimmer(
            height: 46,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ],
      ),
    );
  }
}

/// Skeleton de fila de publicación en el dashboard
class ProductTileSkeleton extends StatelessWidget {
  const ProductTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.zinc200),
      ),
      child: const Row(
        children: [
          LoadingShimmer(
            width: 72, height: 72,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(height: 14),
                SizedBox(height: 8),
                LoadingShimmer(height: 12, width: 100),
                SizedBox(height: 8),
                LoadingShimmer(height: 20, width: 70),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid de skeletons de productos
class CatalogLoadingGrid extends StatelessWidget {
  const CatalogLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Grid columns and aspect ratio calculated dynamically for responsive loading skeletons
    int crossAxisCount = 2;
    double childAspectRatio = 0.52;

    if (width >= 1200) {
      crossAxisCount = 5;
      childAspectRatio = 0.72;
    } else if (width >= 900) {
      crossAxisCount = 4;
      childAspectRatio = 0.70;
    } else if (width >= 600) {
      crossAxisCount = 3;
      childAspectRatio = 0.65;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}
