import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/catalog_local_datasource.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/entities/catalog_product.dart';
import '../../domain/usecases/catalog_usecases.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Infraestructura
// ─────────────────────────────────────────────────────────────────────────────

final _catalogDataSourceProvider = Provider((_) => CatalogLocalDataSource());
final _catalogRepositoryProvider = Provider(
  (ref) => CatalogRepositoryImpl(ref.watch(_catalogDataSourceProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Use Cases
// ─────────────────────────────────────────────────────────────────────────────

final _getAvailableProductsProvider = Provider(
  (ref) => GetAvailableProductsUseCase(ref.watch(_catalogRepositoryProvider)),
);
final _searchProductsUseCaseProvider  = Provider((_) => const SearchProductsUseCase());
final _filterByCategoryUseCaseProvider = Provider((_) => const FilterByCategoryUseCase());

// ─────────────────────────────────────────────────────────────────────────────
// Estado de UI
// ─────────────────────────────────────────────────────────────────────────────

/// Categoría activa
final activeCategoryProvider = StateProvider<String?>((ref) => null);

/// Query de búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');

/// PB-04: Orden de resultados: 'date' | 'price_asc' | 'price_desc' | 'kits_first'
final sortOrderProvider = StateProvider<String>((ref) => 'date');

// ─────────────────────────────────────────────────────────────────────────────
// Catálogo principal
// ─────────────────────────────────────────────────────────────────────────────

final catalogProvider =
    AsyncNotifierProvider<CatalogNotifier, List<CatalogProduct>>(CatalogNotifier.new);

class CatalogNotifier extends AsyncNotifier<List<CatalogProduct>> {
  @override
  Future<List<CatalogProduct>> build() async {
    final useCase = ref.read(_getAvailableProductsProvider);
    final result  = await useCase();
    return result.getOrElse((_) => []);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final result = await ref.read(_getAvailableProductsProvider)();
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      AsyncValue.data,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Catálogo filtrado (derivado reactivo)
// ─────────────────────────────────────────────────────────────────────────────

final filteredCatalogProvider = Provider<List<CatalogProduct>>((ref) {
  final allProducts = ref.watch(catalogProvider).valueOrNull ?? [];
  final query       = ref.watch(searchQueryProvider);
  final category    = ref.watch(activeCategoryProvider);
  final sortOrder   = ref.watch(sortOrderProvider);

  final searchUseCase  = ref.read(_searchProductsUseCaseProvider);
  final filterUseCase  = ref.read(_filterByCategoryUseCaseProvider);

  List<CatalogProduct> result;

  // 1. Búsqueda tiene prioridad
  if (query.trim().isNotEmpty) {
    result = searchUseCase(products: allProducts, query: query);
  } else {
    result = filterUseCase(products: allProducts, categoryName: category);
  }

  // PB-04: Ordenar
  final sorted = List<CatalogProduct>.from(result);
  switch (sortOrder) {
    case 'price_asc':
      sorted.sort((a, b) => a.price.compareTo(b.price));
    case 'price_desc':
      sorted.sort((a, b) => b.price.compareTo(a.price));
    case 'kits_first':
      sorted.sort((a, b) {
        if (a.isKit && !b.isKit) return -1;
        if (!a.isKit && b.isKit) return 1;
        return 0;
      });
    default:
      break; // 'date' — ya viene ordenado por Supabase
  }
  return sorted;
});

// PB-09/11: Solo kits — para la sección destacada del catálogo
final kitsProvider = Provider<List<CatalogProduct>>((ref) {
  final allProducts = ref.watch(catalogProvider).valueOrNull ?? [];
  return allProducts.where((p) => p.isKit).toList();
});

// Proveedor por ID — para la pantalla de detalle
final productByIdProvider = Provider.family<CatalogProduct?, String>((ref, id) {
  final allProducts = ref.watch(catalogProvider).valueOrNull ?? [];
  try {
    return allProducts.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});
