import '../../domain/entities/auth_user.dart';

/// DTO de AuthUser — capa de Datos (Supabase)
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    super.name,
    super.imageUrl,
    super.role,
  });

  factory AuthUserModel.fromMap(Map<String, dynamic> map) {
    return AuthUserModel(
      id:       map['id']?.toString()    ?? '',
      email:    map['email']   as String? ?? '',
      name:     map['name']    as String?,
      imageUrl: map['image']   as String?,
      role:     map['role']    as String? ?? 'user',
    );
  }

  factory AuthUserModel.fromMicrosoftGraph(Map<String, dynamic> json) {
    return AuthUserModel(
      id:       json['id'] as String,
      email:    json['mail'] as String? ?? json['userPrincipalName'] as String,
      name:     json['displayName'] as String?,
    );
  }
}
