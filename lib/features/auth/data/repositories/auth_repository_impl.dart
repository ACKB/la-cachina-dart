import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación concreta del AuthRepository — capa de Datos
///
/// Conecta el dominio con la infraestructura:
///   - Llama al DataSource
///   - Captura excepciones de infraestructura
///   - Las convierte en Failures del dominio
///   - Nunca expone detalles de la BD o del OAuth a la capa de presentación
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  FutureEither<AuthUser> signIn() async {
    try {
      final model = await _dataSource.signIn();
      return right(model);
    } on AuthException catch (e) {
      // Caso especial: correo no autorizado
      if (e.message.contains('no permitido') || e.message.contains('unfv')) {
        return left(const UnauthorizedEmailFailure());
      }
      return left(AuthFailure(e.message));
    } on Exception catch (e) {
      return left(e.toFailure());
    }
  }

  @override
  FutureEitherVoid signOut() async {
    try {
      await _dataSource.signOut();
      return right(unit);
    } on Exception catch (e) {
      return left(e.toFailure());
    }
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    try {
      return await _dataSource.getCachedUser();
    } catch (_) {
      return null;
    }
  }
}
