// ─────────────────────────────────────────────────────────────────────────────
// Exceptions — errores de la capa de infraestructura (Data Layer)
//
// Las excepciones NO llegan a la UI. Los repositorios las capturan y
// las convierten a Failures antes de retornar al Use Case.
// ─────────────────────────────────────────────────────────────────────────────

/// Error de conexión o query contra SQL Server.
class DatabaseException implements Exception {
  final String message;
  final Object? cause;
  const DatabaseException(this.message, [this.cause]);

  @override
  String toString() => 'DatabaseException: $message${cause != null ? ' — $cause' : ''}';
}

/// Error durante el flujo OAuth / Microsoft Entra ID.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// El recurso consultado no existe en la base de datos.
class NotFoundException implements Exception {
  final String message;
  const NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Los datos del request no son válidos (fallo antes de llegar a la BD).
class InvalidDataException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;
  const InvalidDataException(this.message, {this.fieldErrors});

  @override
  String toString() => 'InvalidDataException: $message';
}
