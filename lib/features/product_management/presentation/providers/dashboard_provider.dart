import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/user_product.dart';
import '../../domain/usecases/product_usecases.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers de infraestructura
// ─────────────────────────────────────────────────────────────────────────────

final _productDataSourceProvider = Provider(
  (_) => ProductLocalDataSource(),
);

final _productRepositoryProvider = Provider(
  (ref) => ProductRepositoryImpl(ref.watch(_productDataSourceProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Providers de Use Cases
// ─────────────────────────────────────────────────────────────────────────────

final _getUserProductsUseCaseProvider = Provider(
  (ref) => GetUserProductsUseCase(ref.watch(_productRepositoryProvider)),
);

final _markAsSoldUseCaseProvider = Provider(
  (ref) => MarkAsSoldUseCase(ref.watch(_productRepositoryProvider)),
);

final _deleteProductUseCaseProvider = Provider(
  (ref) => DeleteProductUseCase(ref.watch(_productRepositoryProvider)),
);

final createProductUseCaseProvider = Provider(
  (ref) => CreateProductUseCase(ref.watch(_productRepositoryProvider)),
);

final updateProductUseCaseProvider = Provider(
  (ref) => UpdateProductUseCase(ref.watch(_productRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Estado del Dashboard — publicaciones del usuario autenticado
// ─────────────────────────────────────────────────────────────────────────────

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, List<UserProduct>>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<List<UserProduct>> {
  @override
  Future<List<UserProduct>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final result = await ref.read(_getUserProductsUseCaseProvider)(user.id);
    return result.getOrElse((_) => []);
  }

  /// Pull-to-refresh tras crear/marcar/eliminar
  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncValue.loading();
    final result = await ref.read(_getUserProductsUseCaseProvider)(user.id);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      AsyncValue.data,
    );
  }

  /// Marca un producto como vendido y refresca
  Future<Failure?> markAsSold(String productId) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return const AuthFailure();

    final result = await ref
        .read(_markAsSoldUseCaseProvider)
        .call(productId: productId, userId: userId);

    return result.fold(
      (failure) => failure,
      (_) {
        refresh();
        return null;
      },
    );
  }

  /// Elimina un producto y refresca
  Future<Failure?> deleteProduct(String productId) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return const AuthFailure();

    final result = await ref
        .read(_deleteProductUseCaseProvider)
        .call(productId: productId, userId: userId);

    return result.fold(
      (failure) => failure,
      (_) {
        refresh();
        return null;
      },
    );
  }

  /// PB-08: Actualiza precio, descripción y campos técnicos
  Future<Failure?> updateProduct(UpdateProductParams params) async {
    final result = await ref.read(updateProductUseCaseProvider).call(params);
    return result.fold(
      (failure) => failure,
      (_) {
        refresh();
        return null;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats derivados (reactivos, sin query extra)
// ─────────────────────────────────────────────────────────────────────────────

class DashboardStats {
  final int active;
  final int expired;
  final int sold;
  const DashboardStats({
    required this.active,
    required this.expired,
    required this.sold,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final products = ref.watch(dashboardProvider).valueOrNull ?? [];
  return DashboardStats(
    active:  products.where((p) => p.isActive).length,
    expired: products.where((p) => p.isExpired && !p.isSold).length,
    sold:    products.where((p) => p.isSold).length,
  );
});
