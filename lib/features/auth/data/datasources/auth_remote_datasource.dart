import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/auth_user_model.dart';

/// DataSource de autenticación — capa de Datos
///
/// Integrado con Supabase Auth.
class AuthRemoteDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthRemoteDataSource();

  // ── OAuth: Microsoft Entra ID ───────────────────────────────────────────────

  Future<AuthUserModel> signIn() async {
    try {
      // Inicia el flujo OAuth con Azure (Microsoft)
      // Nota: Requiere configuración en el Dashboard de Supabase
      final success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.azure,
        scopes: 'email profile User.Read',
        redirectTo: kIsWeb ? '${Uri.base.origin}/' : 'io.supabase.kchina://login-callback/',
      );

      if (!success) {
        throw app_exceptions.AuthException('No se pudo abrir el navegador para iniciar sesión.');
      }

      // El navegador se abrirá. Supabase manejará el redirect automáticamente
      // y la sesión cambiará. La UI debe escuchar authStateChanges.
      
      // Retornamos un dummy porque la app se recargará con el nuevo estado
      return const AuthUserModel(id: '', email: '');
      
    } on AuthException {
      rethrow;
    } catch (e) {
      throw app_exceptions.AuthException('Error durante el inicio de sesión: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    debugPrint('[Auth] Sesión cerrada en Supabase');
  }

  Future<AuthUserModel?> getCachedUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final user = session.user;
    
    // Validar que exista en public.users y obtener role
    try {
      final data = await _supabase
          .from('users')
          .select('id, name, email, image, role')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return AuthUserModel.fromMap(data);
      }
    } catch (_) {
      // Ignorar si falla la carga del perfil
    }

    return AuthUserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['full_name'],
      imageUrl: user.userMetadata?['avatar_url'],
    );
  }
}

