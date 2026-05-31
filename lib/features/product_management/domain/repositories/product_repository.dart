import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_product.dart';

abstract interface class ProductRepository {
  FutureEither<List<UserProduct>> getUserProducts(String userId);

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
    String   type,
    String?  courseLabel,
    List<Map<String, dynamic>> kitItems,
  });

  /// PB-08: Actualizar precio y descripción
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
  });

  FutureEitherVoid markAsSold({required String productId, required String userId});
  FutureEitherVoid deleteProduct({required String productId, required String userId});
}
