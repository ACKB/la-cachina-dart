import 'product_status.dart';

/// Entidad UserProduct — Dominio de gestión de publicaciones
class UserProduct {
  final String id;
  final String title;
  final String description;
  final int price;             // centavos
  final ProductStatus status;
  final List<String> imageUrls;
  final String categoryName;
  final DateTime createdAt;
  final DateTime expiresAt;

  // PB-03: Campos técnicos
  final String? model;
  final int?    condition;     // 1-10
  final String? datasheetUrl;
  final String? tips;
  final String? githubUrl;

  // PB-09/10/11: Kits
  final String  type;          // 'PRODUCT' | 'KIT'
  final String? courseLabel;

  static const int expiryDays = 14;

  const UserProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.status,
    required this.imageUrls,
    required this.categoryName,
    required this.createdAt,
    required this.expiresAt,
    this.model,
    this.condition,
    this.datasheetUrl,
    this.tips,
    this.githubUrl,
    this.type = 'PRODUCT',
    this.courseLabel,
  });

  bool get isExpired =>
      status == ProductStatus.expired ||
      expiresAt.isBefore(DateTime.now().toUtc());

  int get daysRemaining =>
      expiresAt.difference(DateTime.now().toUtc()).inDays.clamp(0, expiryDays);

  bool get isActive => !isExpired && status == ProductStatus.available;
  bool get isSold   => status == ProductStatus.sold;
  bool get isKit    => type == 'KIT';

  String? get thumbnailUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProduct && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
