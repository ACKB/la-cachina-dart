import 'package:fpdart/fpdart.dart';
import 'package:fuzzy/fuzzy.dart';
import '../../../../core/error/failures.dart';
import '../entities/catalog_product.dart';
import '../repositories/catalog_repository.dart';

/// Use Case: Obtener productos disponibles para el catálogo
class GetAvailableProductsUseCase {
  final CatalogRepository _repository;
  const GetAvailableProductsUseCase(this._repository);

  FutureEither<List<CatalogProduct>> call() =>
      _repository.getAvailableProducts();
}

/// Use Case: Búsqueda fuzzy local de productos
///
/// Equivalente al Web Worker con Fuse.js del proyecto Next.js.
/// La búsqueda es 100% client-side: sin roundtrips al servidor.
class SearchProductsUseCase {
  const SearchProductsUseCase();

  /// Filtra [products] usando búsqueda fuzzy sobre título y categoría.
  /// [query] vacío retorna todos los productos.
  List<CatalogProduct> call({
    required List<CatalogProduct> products,
    required String query,
  }) {
    if (query.trim().isEmpty) return products;

    final fuse = Fuzzy<CatalogProduct>(
      products,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'title',
            getter: (p) => p.title,
            weight: 0.7,
          ),
          WeightedKey(
            name: 'categoryName',
            getter: (p) => p.categoryName,
            weight: 0.3,
          ),
        ],
        threshold: 0.4,
        shouldNormalize: true,
      ),
    );

    return fuse.search(query.trim())
        .take(50)
        .map((r) => r.item)
        .toList();
  }
}

/// Use Case: Filtrar productos por categoría (client-side)
class FilterByCategoryUseCase {
  const FilterByCategoryUseCase();

  List<CatalogProduct> call({
    required List<CatalogProduct> products,
    required String? categoryName,
  }) {
    if (categoryName == null) return products;
    return products
        .where((p) =>
            p.categoryName.toLowerCase().contains(categoryName.toLowerCase()))
        .toList();
  }
}
