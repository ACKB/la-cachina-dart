import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../providers/catalog_provider.dart';
import '../widgets/category_chip_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar_widget.dart';

/// Pantalla del Catálogo público — feature principal de la app
///
/// Mobile-first: grid 2 columnas, SliverAppBar colapsable con hero gradient,
/// shimmer en carga, empty state, pull-to-refresh.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogProvider);
    final filtered     = ref.watch(filteredCatalogProvider);
    final query        = ref.watch(searchQueryProvider);
    final category     = ref.watch(activeCategoryProvider);

    final width = MediaQuery.of(context).size.width;

    // Grid columns and aspect ratio calculated dynamically for responsive design
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

    final isDesktop = width >= 900;

    Widget content = CustomScrollView(
      slivers: [
        // ── SliverAppBar con gradiente hero (solo móvil) ───────────────
        if (!isDesktop) _buildSliverAppBar(context),
        if (isDesktop) const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── Barra de búsqueda ──────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: CatalogSearchBar(),
          ),
        ),

        // ── Chips de categoría ─────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: CategoryChipBar(),
          ),
        ),

        // ── Contador de resultados ─────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildResultCount(filtered.length, query, category),
        ),

        // ── Contenido principal ────────────────────────────────────────
        catalogAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: CatalogLoadingGrid(),
          ),
          error: (e, _) => SliverFillRemaining(
            child: ErrorView(
              title: 'Error cargando el catálogo',
              message: e.toString(),
              onRetry: () =>
                  ref.read(catalogProvider.notifier).refresh(),
            ),
          ),
          data: (_) => filtered.isEmpty
              ? SliverFillRemaining(
                  child: _buildEmptyState(context, ref, query, category),
                )
              : _buildGrid(filtered, crossAxisCount, childAspectRatio),
        ),
      ],
    );

    return ResponsiveLayout(
      currentIndex: 0,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(catalogProvider.notifier).refresh(),
        child: content,
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'K-china FIEI',
                    style: AppTextStyles.displayMd.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Marketplace de hardware · FIEI UNFV',
                    style: AppTextStyles.bodySm.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.zero,
        child: Container(),
      ),
    );
  }

  Widget _buildResultCount(
    int count,
    String query,
    String? category,
  ) {
    final label = query.isNotEmpty
        ? '$count resultado${count != 1 ? 's' : ''} para "$query"'
        : category != null
            ? '$count en "$category"'
            : '$count productos disponibles';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500),
      ),
    );
  }

  SliverPadding _buildGrid(list, int crossAxisCount, double childAspectRatio) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => ProductCard(product: list[i]),
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    String query,
    String? category,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? 'Sin resultados para "$query"'
                  : (category != null ? 'Sin productos en "$category"' : 'Aún no hay productos disponibles'),
              style: AppTextStyles.headlineSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otras palabras o explora todas las categorías.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.zinc500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state   = '';
                ref.read(activeCategoryProvider.notifier).state = null;
              },
              child: Text(
                'Ver todo el catálogo',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
