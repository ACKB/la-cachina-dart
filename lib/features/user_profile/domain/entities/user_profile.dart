/// Entidad UserProfile — Dominio
class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? imageUrl;
  final String? whatsappNumber;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.imageUrl,
    this.whatsappNumber,
    required this.createdAt,
  });

  String get firstName => name?.trim().split(' ').first ?? email.split('@').first;
  String get initial   => firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

  /// El número de WhatsApp formateado para display (sin código de país)
  String? get displayPhone {
    final n = whatsappNumber;
    if (n == null) return null;
    return n.startsWith('51') ? n.substring(2) : n;
  }

  bool get hasWhatsapp => whatsappNumber != null && whatsappNumber!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
