import 'package:fpdart/fpdart.dart';
import 'exceptions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Failures — representan errores en el dominio (capa independiente de la UI)
//
// Un Failure es lo que el Use Case le entrega a la capa de Presentación
// cuando algo salió mal. No expone detalles de infraestructura.
// La Presentación los mapea a mensajes amigables para el usuario.
// ─────────────────────────────────────────────────────────────────────────────

sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// No se pudo conectar a la base de datos SQL Server.
final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Error de base de datos.']);
}

/// El usuario no está autenticado o la sesión expiró.
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sesión inválida. Por favor inicia sesión.']);
}

/// El correo no pertenece al dominio @unfv.edu.pe.
final class UnauthorizedEmailFailure extends Failure {
  const UnauthorizedEmailFailure()
      : super('Acceso restringido. Solo correos @unfv.edu.pe son permitidos.');
}

/// El recurso solicitado no existe.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso no encontrado.']);
}

/// Los datos enviados no pasaron la validación del dominio.
final class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;
  const ValidationFailure(this.fieldErrors, [super.message = 'Datos inválidos.']);
}

/// Error genérico de red o conexión.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Error de conexión. Verifica tu red.']);
}

/// Error inesperado del servidor o de la aplicación.
final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error interno. Intenta de nuevo.']);
}

// ─────────────────────────────────────────────────────────────────────────────
// Extension helper: convertir Exception → Failure
// ─────────────────────────────────────────────────────────────────────────────

extension ExceptionToFailure on Exception {
  Failure toFailure() {
    return switch (this) {
      DatabaseException e => DatabaseFailure(e.message),
      AuthException e     => AuthFailure(e.message),
      NotFoundException e => NotFoundFailure(e.message),
      _                   => ServerFailure(toString()),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Type alias de conveniencia para los Use Cases
// ─────────────────────────────────────────────────────────────────────────────

typedef FutureEither<T> = Future<Either<Failure, T>>;
typedef FutureEitherVoid  = Future<Either<Failure, Unit>>;
