import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/catalog_product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_local_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogLocalDataSource _dataSource;
  const CatalogRepositoryImpl(this._dataSource);

  @override
  FutureEither<List<CatalogProduct>> getAvailableProducts() async {
    try {
      final models = await _dataSource.getAvailableProducts();
      return right(models);
    } on DatabaseException catch (e) {
      return left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return left(e.toFailure());
    }
  }

  @override
  FutureEither<List<CatalogProduct>> getProductsForSearch() =>
      getAvailableProducts(); // Mismo dataset; el use case filtra en memoria
}
