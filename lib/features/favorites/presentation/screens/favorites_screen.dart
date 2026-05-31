import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../catalog/domain/entities/catalog_product.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../providers/favorites_provider.dart';

/// Pantalla de Favoritos — PB-06
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesListProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

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

    return ResponsiveLayout(
      currentIndex: 1,
      body: CustomScrollView(
        slivers: [
          if (!isDesktop)
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.primary,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Mis Favoritos',
                  style: AppTextStyles.headlineSm.copyWith(color: Colors.white),
                ),
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                ),
              ),
            ),
          if (isDesktop) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Mis Favoritos',
                  style: AppTextStyles.displayMd.copyWith(
                    color: AppColors.zinc800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          if (favorites.isEmpty)
            SliverFillRemaining(
              child: _EmptyFavorites(onGoToCatalog: () => context.go('/')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(product: favorites[i]),
                  childCount: favorites.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final VoidCallback onGoToCatalog;
  const _EmptyFavorites({required this.onGoToCatalog});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border_rounded,
                size: 72, color: AppColors.zinc300),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes favoritos',
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.zinc700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el ❤️ en cualquier producto del catálogo para guardarlo aquí.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onGoToCatalog,
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('Ir al catálogo'),
            ),
          ],
        ),
      ),
    );
  }
}
