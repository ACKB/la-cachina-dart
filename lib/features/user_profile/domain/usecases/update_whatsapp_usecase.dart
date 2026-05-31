import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/user_repository.dart';

/// Use Case: Actualizar número de WhatsApp
///
/// Encapsula la regla de negocio: solo números peruanos de 9 dígitos (9XXXXXXXX).
/// Convierte al formato E.164 antes de persistir: "51987654321"
class UpdateWhatsAppUseCase {
  final UserRepository _repository;
  const UpdateWhatsAppUseCase(this._repository);

  FutureEitherVoid call({
    required String userId,
    required String rawPhone,
  }) {
    final normalized = _normalize(rawPhone);
    if (normalized == null) {
      return Future.value(
        left(const ValidationFailure(
          {'whatsapp': 'Número peruano inválido (ej. 987654321)'},
        )),
      );
    }
    return _repository.updateWhatsApp(userId: userId, phoneE164: normalized);
  }

  /// Normaliza a formato E.164 sin signo +
  /// Acepta: "987654321", "51987654321", "+51987654321"
  String? _normalize(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final local  = digits.startsWith('51') ? digits.substring(2) : digits;
    if (!RegExp(r'^9\d{8}$').hasMatch(local)) return null;
    return '51$local';
  }
}
