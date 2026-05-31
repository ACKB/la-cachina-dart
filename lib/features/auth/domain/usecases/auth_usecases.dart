import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use Case: SignIn
///
/// Encapsula la regla de negocio de inicio de sesión.
/// La pantalla llama a este use case; no sabe nada del OAuth ni de la BD.
class SignInUseCase {
  final AuthRepository _repository;
  const SignInUseCase(this._repository);

  /// Lanza el flujo OAuth y retorna el usuario autenticado.
  FutureEither<AuthUser> call() => _repository.signIn();
}

/// Use Case: SignOut
class SignOutUseCase {
  final AuthRepository _repository;
  const SignOutUseCase(this._repository);

  FutureEitherVoid call() => _repository.signOut();
}

/// Use Case: GetCurrentUser
///
/// Usado en el arranque de la app para restaurar sesión.
class GetCurrentUserUseCase {
  final AuthRepository _repository;
  const GetCurrentUserUseCase(this._repository);

  Future<AuthUser?> call() => _repository.getCurrentUser();
}
