/// Entidad AuthUser — capa de Dominio
///
/// Representa al usuario autenticado.
/// Es una clase Dart pura: sin dependencias de Flutter, SQL Server ni JSON.
/// El dominio no sabe CÓMO se autentica ni CÓMO se persiste.
class AuthUser {
  final String id;
  final String email;
  final String? name;
  final String? imageUrl;
  final String role; // 'user' | 'admin'

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.imageUrl,
    this.role = 'user',
  });

  /// El nombre abreviado para mostrar en la UI (primer nombre)
  String get firstName => name?.trim().split(' ').first ?? email.split('@').first;

  /// Inicial para el avatar flotante
  String get initial {
    if (firstName.isNotEmpty) return firstName[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  @override
  String toString() => 'AuthUser(id: $id, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
