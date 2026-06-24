import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

// ─────────────────────────────────────────────────────────────────────────────
// Providers de infraestructura (Data layer)
// ─────────────────────────────────────────────────────────────────────────────

final _authDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(),
);

final _authRepositoryProvider = Provider<AuthRepositoryImpl>(
  (ref) => AuthRepositoryImpl(ref.watch(_authDataSourceProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Providers de Use Cases
// ─────────────────────────────────────────────────────────────────────────────

final signInUseCaseProvider = Provider(
  (ref) => SignInUseCase(ref.watch(_authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider(
  (ref) => SignOutUseCase(ref.watch(_authRepositoryProvider)),
);

final getCurrentUserUseCaseProvider = Provider(
  (ref) => GetCurrentUserUseCase(ref.watch(_authRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Estado de autenticación — Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Estado inmutable de la sesión
sealed class AuthState {
  const AuthState();
}

/// Verificando si hay sesión guardada (arranque de app)
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Usuario autenticado correctamente
final class AuthAuthenticated extends AuthState {
  final AuthUser user;
  const AuthAuthenticated(this.user);
}

/// No hay sesión activa
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error durante el flujo de auth
final class AuthError extends AuthState {
  final Failure failure;
  const AuthError(this.failure);
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthNotifier — orquesta los use cases
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Escuchar cambios de sesión de Supabase (ej: cuando vuelve del navegador por deep link)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.initialSession) {
        final getCurrentUser = ref.read(getCurrentUserUseCaseProvider);
        final user = await getCurrentUser();
        if (user != null) {
          state = AsyncValue.data(AuthAuthenticated(user));
        } else {
          state = const AsyncValue.data(AuthUnauthenticated());
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        state = const AsyncValue.data(AuthUnauthenticated());
      }
    });

    final getCurrentUser = ref.read(getCurrentUserUseCaseProvider);
    final user = await getCurrentUser();
    return user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
  }

  /// Inicia sesión con Microsoft Entra ID
  Future<void> signIn() async {
    state = const AsyncValue.loading();
    final signIn = ref.read(signInUseCaseProvider);
    final result = await signIn();
    
    // Si la autenticación OAuth fue exitosa en abrir el navegador, 
    // no seteamos estado final todavía. El listener onAuthStateChange se encargará
    // cuando el deep link devuelva el control a la app.
    result.fold(
      (failure) => state = AsyncValue.data(AuthError(failure)),
      (user) {
        // Si por alguna razón devuelve un id vacío (esperando redirect), mantenemos loading
        if (user.id.isEmpty) {
          state = const AsyncValue.loading();
        } else {
          state = AsyncValue.data(AuthAuthenticated(user));
        }
      },
    );
  }

  /// Cierra la sesión
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final signOut = ref.read(signOutUseCaseProvider);
    await signOut();
    // onAuthStateChange se encargará de actualizar a AuthUnauthenticated
  }

  /// Dev-backdoor: Iniciar sesión directamente como administrador de prueba sin Azure OAuth
  Future<void> signInMockAdmin() async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 500));
    const mockUser = AuthUser(
      id: '59ab53d1-c496-4ac7-9dd8-1c3dd0d94205',
      email: '2023020308@unfv.edu.pe',
      name: 'Administrador FIEI',
      role: 'admin',
    );
    state = const AsyncValue.data(AuthAuthenticated(mockUser));
  }
}

/// Provider principal de autenticación — accesible en toda la app
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Conveniencia: usuario actual o null
final currentUserProvider = Provider<AuthUser?>((ref) {
  final state = ref.watch(authProvider).valueOrNull;
  return state is AuthAuthenticated ? state.user : null;
});

/// Conveniencia: ¿está autenticado?
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// PB-14: ¿El usuario actual es administrador?
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == 'admin';
});
