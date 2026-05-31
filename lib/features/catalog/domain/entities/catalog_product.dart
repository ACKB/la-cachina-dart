/// Componente individual de un Kit
class KitItem {
  final String componentName;
  final int quantity;
  const KitItem({required this.componentName, required this.quantity});
}

/// Entidad CatalogProduct — Dominio del Catálogo
///
/// Representa un producto visible en el catálogo público.
/// Clase Dart pura: sin Flutter, sin SQL Server, sin JSON.
class CatalogProduct {
  final String id;
  final String title;
  final String description;

  /// Precio en centavos. Ej: 1500 = S/ 15.00
  final int price;

  final List<String> imageUrls;

  /// Tags de subcategoría (ej: ['esp32', 'wifi'])
  final List<String> tags;

  final String categoryId;
  final String categoryName;
  final String userId;
  final String? sellerName;
  final String? sellerWhatsapp;

  // PB-03: Campos técnicos
  final String? model;
  final int? condition;          // 1-10
  final String? datasheetUrl;
  final String? tips;
  final String? githubUrl;

  // PB-09/10/11: Kits
  final String type;             // 'PRODUCT' | 'KIT'
  final String? courseLabel;
  final List<KitItem> kitItems;

  const CatalogProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.tags,
    required this.categoryId,
    required this.categoryName,
    required this.userId,
    this.sellerName,
    this.sellerWhatsapp,
    this.model,
    this.condition,
    this.datasheetUrl,
    this.tips,
    this.githubUrl,
    this.type = 'PRODUCT',
    this.courseLabel,
    this.kitItems = const [],
  });

  bool get isKit => type == 'KIT';

  /// Primer nombre del vendedor para mostrar en la card
  String get sellerFirstName =>
      sellerName?.split(' ').first ?? 'Usuario';

  /// ¿Tiene número de WhatsApp para contactar?
  bool get isContactable => sellerWhatsapp != null && sellerWhatsapp!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogProduct && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

