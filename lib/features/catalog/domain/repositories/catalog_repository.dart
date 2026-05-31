import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/catalog_product.dart';

abstract interface class CatalogRepository {
  /// Productos disponibles y no vencidos (máx 50, más recientes primero).
  FutureEither<List<CatalogProduct>> getAvailableProducts();

  /// Subconjunto mínimo para el índice de búsqueda local.
  FutureEither<List<CatalogProduct>> getProductsForSearch();
}
