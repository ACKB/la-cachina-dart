import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/product_detail_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/product_management/domain/entities/user_product.dart';
import '../../features/product_management/presentation/screens/dashboard_screen.dart';
import '../../features/product_management/presentation/screens/edit_product_screen.dart';
import '../../features/product_management/presentation/screens/new_product_screen.dart';
import '../../features/user_profile/presentation/screens/profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppRouter — Rutas declarativas de la app
// ─────────────────────────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isAuth    = ref.watch(isAuthenticatedProvider);
  final isAdmin   = ref.watch(isAdminProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Mientras carga la sesión, no redirigir
      if (authState.isLoading) return null;

      final path       = state.matchedLocation;
      final authRoutes = ['/dashboard', '/dashboard/new', '/profile', '/favorites', '/admin'];
      final isAuthRoute = authRoutes.any((r) => path.startsWith(r));

      // Rutas protegidas → login si no está autenticado
      if (isAuthRoute && !isAuth) return '/login';

      // Login → catálogo si ya está autenticado
      if (path == '/login' && isAuth) return '/';

      // /admin → solo admins
      if (path.startsWith('/admin') && !isAdmin) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const CatalogScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/catalog/:id',
        builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/dashboard/new', builder: (_, __) => const NewProductScreen()),
      GoRoute(
        path: '/dashboard/edit',
        builder: (_, state) {
          final product = state.extra as UserProduct;
          return EditProductScreen(product: product);
        },
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/admin',   builder: (_, __) => const AdminScreen()),
    ],
  );
});
