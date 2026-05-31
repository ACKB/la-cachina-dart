import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/user_local_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/update_whatsapp_usecase.dart';

// ── Providers de infraestructura ─────────────────────────────────────────────

final _userDataSourceProvider = Provider(
  (_) => UserLocalDataSource(),
);

final _userRepositoryProvider = Provider(
  (ref) => UserRepositoryImpl(ref.watch(_userDataSourceProvider)),
);

final _updateWhatsAppUseCaseProvider = Provider(
  (ref) => UpdateWhatsAppUseCase(ref.watch(_userRepositoryProvider)),
);

// ── Estado del perfil ─────────────────────────────────────────────────────────

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return null;

    final repo   = ref.read(_userRepositoryProvider);
    final result = await repo.getUserProfile(userId);
    return result.fold((_) => null, (profile) => profile);
  }

  Future<String?> updateWhatsApp(String rawPhone) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return 'No autenticado.';

    final useCase = ref.read(_updateWhatsAppUseCaseProvider);
    final result  = await useCase(userId: userId, rawPhone: rawPhone);

    return result.fold(
      (failure) => failure.message,
      (_) {
        // Invalidar para que recargue el perfil
        ref.invalidateSelf();
        return null; // null = sin error
      },
    );
  }
}
