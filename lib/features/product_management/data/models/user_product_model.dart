import '../../domain/entities/product_status.dart';
import '../../domain/entities/user_product.dart';

class UserProductModel extends UserProduct {
  const UserProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.status,
    required super.imageUrls,
    required super.categoryName,
    required super.createdAt,
    required super.expiresAt,
    super.model,
    super.condition,
    super.datasheetUrl,
    super.tips,
    super.githubUrl,
    super.type,
    super.courseLabel,
  });

  factory UserProductModel.fromMap(Map<String, dynamic> map) {
    final category  = map['categories'] as Map<String, dynamic>? ?? {};
    final rawImages = map['images_base64'] as List<dynamic>? ?? [];
    final imageUrls = rawImages.map((e) => e.toString()).toList();

    return UserProductModel(
      id:           map['id'].toString(),
      title:        map['title']       as String,
      description:  map['description'] as String,
      price:        (map['price']      as int?) ?? 0,
      status:       ProductStatus.fromString((map['status'] ?? 'AVAILABLE') as String),
      imageUrls:    imageUrls,
      categoryName: category['name']   as String? ?? '',
      createdAt:    DateTime.parse(map['created_at'].toString()),
      expiresAt:    DateTime.parse(map['expires_at'].toString()),
      // PB-03
      model:        map['model']         as String?,
      condition:    map['condition']     as int?,
      datasheetUrl: map['datasheet_url'] as String?,
      tips:         map['tips']          as String?,
      githubUrl:    map['github_url']    as String?,
      // PB-09
      type:         (map['type'] as String?) ?? 'PRODUCT',
      courseLabel:  map['course_label']  as String?,
    );
  }
}
