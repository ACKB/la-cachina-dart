/// Estado del producto — Dominio
///
/// Enum puro de Dart, sin dependencias externas.
enum ProductStatus {
  available,
  reserved,
  sold,
  expired;

  static ProductStatus fromString(String value) => switch (value.toUpperCase()) {
        'AVAILABLE' => ProductStatus.available,
        'RESERVED'  => ProductStatus.reserved,
        'SOLD'      => ProductStatus.sold,
        'EXPIRED'   => ProductStatus.expired,
        _           => ProductStatus.available,
      };

  String toDbString() => switch (this) {
        ProductStatus.available => 'AVAILABLE',
        ProductStatus.reserved  => 'RESERVED',
        ProductStatus.sold      => 'SOLD',
        ProductStatus.expired   => 'EXPIRED',
      };

  String get label => switch (this) {
        ProductStatus.available => 'Disponible',
        ProductStatus.reserved  => 'Reservado',
        ProductStatus.sold      => 'Vendido',
        ProductStatus.expired   => 'Vencido',
      };
}
