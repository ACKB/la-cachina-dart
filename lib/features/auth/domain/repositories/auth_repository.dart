import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';

/// Contrato del repositorio de autenticación — Dominio
///
/// Define QUÉ puede hacer la autenticación, sin importar CÓMO.
/// La implementación concreta está en data/repositories/.
abstract interface class AuthRepository {
  /// Inicia el flujo OAuth con Microsoft Entra ID.
  /// Retorna [AuthFailure] si el correo no es @unfv.edu.pe.
  FutureEither<AuthUser> signIn();

  /// Cierra la sesión actual y limpia los tokens.
  FutureEitherVoid signOut();

  /// Retorna el usuario autenticado actual, o null si no hay sesión.
  Future<AuthUser?> getCurrentUser();
}
