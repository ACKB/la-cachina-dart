import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource _dataSource;
  const ProductRepositoryImpl(this._dataSource);

  @override
  FutureEither<List<UserProduct>> getUserProducts(String userId) async {
    try {
      return right(await _dataSource.getUserProducts(userId));
    } on DatabaseException catch (e) {
      return left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return left(e.toFailure());
    }
  }

  @override
  FutureEither<String> createProduct({
    required String title,
    required String description,
    required int priceInCentavos,
    required String categoryId,
    required String userId,
    required List<XFile> images,
    String?  model,
    int?     condition,
    String?  datasheetUrl,
    String?  tips,
    String?  githubUrl,
    String   type = 'PRODUCT',
    String?  courseLabel,
    List<Map<String, dynamic>> kitItems = const [],
  }) async {
    try {
      final id = await _dataSource.createProduct(
        title: title, description: description,
        priceInCentavos: priceInCentavos, categoryId: categoryId,
        userId: userId, images: images,
        model: model, condition: condition, datasheetUrl: datasheetUrl,
        tips: tips, githubUrl: githubUrl, type: type,
        courseLabel: courseLabel, kitItems: kitItems,
      );
      return right(id);
    } on DatabaseException catch (e) {
      return left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return left(e.toFailure());
    }
  }

  @override
  FutureEitherVoid updateProduct({
    required String productId,
    required String userId,
    required String title,
    required String description,
    required int    priceInCentavos,
    required String categoryId,
    String?  model,
    int?     condition,
    String?  datasheetUrl,
    String?  tips,
    String?  githubUrl,
    String?  courseLabel,
  }) async {
    try {
      await _dataSource.updateProduct(
        productId: productId, userId: userId,
        title: title, description: description,
        priceInCentavos: priceInCentavos, categoryId: categoryId,
        model: model, condition: condition, datasheetUrl: datasheetUrl,
        tips: tips, githubUrl: githubUrl, courseLabel: courseLabel,
      );
      return right(unit);
    } on DatabaseException catch (e) {
      return left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return left(e.toFailure());
    }
  }

  @override
  FutureEitherVoid markAsSold({required String productId, required String userId}) async {
    try {
      await _dataSource.markAsSold(productId: productId, userId: userId);
      return right(unit);
    } on DatabaseException catch (e) {
      return left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return left(e.toFailure());
    }
  }

  @override
  FutureEitherVoid deleteProduct({required String productId, required String userId}) async {
    try {
      await _dataSource.deleteProduct(productId: productId, userId: userId);
      return right(unit);
    } on DatabaseException catch (e) {
      return left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return left(e.toFailure());
    }
  }
}
