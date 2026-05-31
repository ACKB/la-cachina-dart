import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/product_list_tile.dart';
import '../widgets/stats_row.dart';

/// Pantalla del Dashboard — publicaciones propias del usuario autenticado
///
/// Mobile-first: SliverAppBar con avatar, stats cards, lista con swipe-to-delete,
/// FAB de nueva publicación, pull-to-refresh.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user         = ref.watch(currentUserProvider);
    final productsAsync = ref.watch(dashboardProvider);
    final stats        = ref.watch(dashboardStatsProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return ResponsiveLayout(
      currentIndex: 2,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/dashboard/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Publicar', style: AppTextStyles.labelLg),
        elevation: 4,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            if (!isDesktop)
              _buildSliverAppBar(context, ref, user.firstName, user.initial),
            if (isDesktop) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis publicaciones',
                        style: AppTextStyles.displayMd.copyWith(
                          color: AppColors.zinc800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hola, ${user.firstName} 👋',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.zinc500),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // ── Stats ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: StatsRow(
                  active:  stats.active,
                  expired: stats.expired,
                  sold:    stats.sold,
                ),
              ),
            ),

            // ── Lista de publicaciones ────────────────────────────────────
            productsAsync.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: 4,
                  itemBuilder: (_, __) => const ProductTileSkeleton(),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                  title: 'Error cargando tus publicaciones',
                  message: e.toString(),
                  onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
                ),
              ),
              data: (products) => products.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyView(
                        emoji: '🛒',
                        title: 'Sin publicaciones',
                        subtitle:
                            'Aún no has publicado ningún producto. '
                            '¡Empieza ahora y llega a toda la comunidad FIEI!',
                        action: ElevatedButton.icon(
                          onPressed: () => context.go('/dashboard/new'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Publicar mi primer producto'),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList.builder(
                        itemCount: products.length,
                        itemBuilder: (_, i) =>
                            ProductListTile(product: products[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    WidgetRef ref,
    String firstName,
    String initial,
  ) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Text(
            'Mis publicaciones',
            style: AppTextStyles.headlineSm,
          ),
        ],
      ),
      actions: [
        // Avatar del usuario con menú
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _showUserMenu(context, ref),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: AppTextStyles.titleSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Hola, $firstName 👋',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.zinc500),
          ),
        ),
      ),
    );
  }

  void _showUserMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(
                'Cerrar sesión',
                style: AppTextStyles.titleSm.copyWith(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
