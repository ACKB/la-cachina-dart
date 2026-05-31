import '../../domain/entities/catalog_product.dart';

/// DTO de CatalogProduct — capa de Datos
///
/// Maneja la conversión desde filas de Supabase (JOIN products + categories + users + kit_items)
class CatalogProductModel extends CatalogProduct {
  const CatalogProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.imageUrls,
    required super.tags,
    required super.categoryId,
    required super.categoryName,
    required super.userId,
    super.sellerName,
    super.sellerWhatsapp,
    super.model,
    super.condition,
    super.datasheetUrl,
    super.tips,
    super.githubUrl,
    super.type,
    super.courseLabel,
    super.kitItems,
  });

  factory CatalogProductModel.fromMap(Map<String, dynamic> map) {
    final category = map['categories'] as Map<String, dynamic>? ?? {};
    final user     = map['users']      as Map<String, dynamic>? ?? {};

    // images_base64 viene como array nativo de Supabase
    final rawImages = map['images_base64'] as List<dynamic>? ?? [];
    final imageUrls = rawImages.map((e) => e.toString()).toList();

    // kit_items viene como lista de objetos anidados
    final rawKitItems = map['kit_items'] as List<dynamic>? ?? [];
    final kitItems = rawKitItems.map((e) {
      final item = e as Map<String, dynamic>;
      return KitItem(
        componentName: item['component_name'] as String? ?? '',
        quantity:      (item['quantity'] as int?) ?? 1,
      );
    }).toList();

    return CatalogProductModel(
      id:             map['id'].toString(),
      title:          map['title']       as String,
      description:    map['description'] as String,
      price:          (map['price']      as int?) ?? 0,
      imageUrls:      imageUrls,
      tags:           const [],
      categoryId:     map['category_id']?.toString() ?? '',
      categoryName:   category['name']  as String? ?? '',
      userId:         map['user_id']?.toString() ?? '',
      sellerName:     user['name']                as String?,
      sellerWhatsapp: user['whatsapp_number']     as String?,
      // PB-03: Campos técnicos
      model:          map['model']        as String?,
      condition:      map['condition']    as int?,
      datasheetUrl:   map['datasheet_url'] as String?,
      tips:           map['tips']          as String?,
      githubUrl:      map['github_url']    as String?,
      // PB-09/10/11: Kits
      type:           (map['type'] as String?) ?? 'PRODUCT',
      courseLabel:    map['course_label']  as String?,
      kitItems:       kitItems,
    );
  }
}
