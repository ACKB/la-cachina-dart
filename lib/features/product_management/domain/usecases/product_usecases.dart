import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_product.dart';
import '../repositories/product_repository.dart';

/// Use Case: Obtener publicaciones del usuario
class GetUserProductsUseCase {
  final ProductRepository _repository;
  const GetUserProductsUseCase(this._repository);

  FutureEither<List<UserProduct>> call(String userId) =>
      _repository.getUserProducts(userId);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Use Case: Crear publicación
class CreateProductUseCase {
  final ProductRepository _repository;
  const CreateProductUseCase(this._repository);

  FutureEither<String> call(CreateProductParams params) =>
      _repository.createProduct(
        title:           params.title,
        description:     params.description,
        priceInCentavos: params.priceInCentavos,
        categoryId:      params.categoryId,
        userId:          params.userId,
        images:          params.images,
        model:           params.model,
        condition:       params.condition,
        datasheetUrl:    params.datasheetUrl,
        tips:            params.tips,
        githubUrl:       params.githubUrl,
        type:            params.type,
        courseLabel:     params.courseLabel,
        kitItems:        params.kitItems,
      );
}

class CreateProductParams {
  final String title;
  final String description;
  final int    priceInCentavos;
  final String categoryId;
  final String userId;
  final List<XFile> images;
  // PB-03
  final String?  model;
  final int?     condition;
  final String?  datasheetUrl;
  final String?  tips;
  final String?  githubUrl;
  // PB-09
  final String   type;
  final String?  courseLabel;
  final List<Map<String, dynamic>> kitItems;

  const CreateProductParams({
    required this.title,
    required this.description,
    required this.priceInCentavos,
    required this.categoryId,
    required this.userId,
    required this.images,
    this.model,
    this.condition,
    this.datasheetUrl,
    this.tips,
    this.githubUrl,
    this.type = 'PRODUCT',
    this.courseLabel,
    this.kitItems = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// Use Case: Actualizar publicación (PB-08)
class UpdateProductUseCase {
  final ProductRepository _repository;
  const UpdateProductUseCase(this._repository);

  FutureEitherVoid call(UpdateProductParams params) =>
      _repository.updateProduct(
        productId:       params.productId,
        userId:          params.userId,
        title:           params.title,
        description:     params.description,
        priceInCentavos: params.priceInCentavos,
        categoryId:      params.categoryId,
        model:           params.model,
        condition:       params.condition,
        datasheetUrl:    params.datasheetUrl,
        tips:            params.tips,
        githubUrl:       params.githubUrl,
        courseLabel:     params.courseLabel,
      );
}

class UpdateProductParams {
  final String productId;
  final String userId;
  final String title;
  final String description;
  final int    priceInCentavos;
  final String categoryId;
  final String?  model;
  final int?     condition;
  final String?  datasheetUrl;
  final String?  tips;
  final String?  githubUrl;
  final String?  courseLabel;

  const UpdateProductParams({
    required this.productId,
    required this.userId,
    required this.title,
    required this.description,
    required this.priceInCentavos,
    required this.categoryId,
    this.model,
    this.condition,
    this.datasheetUrl,
    this.tips,
    this.githubUrl,
    this.courseLabel,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// Use Case: Marcar como vendido
class MarkAsSoldUseCase {
  final ProductRepository _repository;
  const MarkAsSoldUseCase(this._repository);

  FutureEitherVoid call({required String productId, required String userId}) =>
      _repository.markAsSold(productId: productId, userId: userId);
}

/// Use Case: Eliminar publicación
class DeleteProductUseCase {
  final ProductRepository _repository;
  const DeleteProductUseCase(this._repository);

  FutureEitherVoid call({required String productId, required String userId}) =>
      _repository.deleteProduct(productId: productId, userId: userId);
}
