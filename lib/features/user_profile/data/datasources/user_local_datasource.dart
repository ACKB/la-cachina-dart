import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_profile_model.dart';

class UserLocalDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserLocalDataSource();

  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('id, name, email, image, whatsapp_number, created_at')
          .eq('id', userId)
          .maybeSingle();
          
      if (data == null) throw NotFoundException('Usuario no encontrado: $userId');
      return UserProfileModel.fromMap(data);
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw DatabaseException('Error cargando perfil', e);
    }
  }

  Future<void> updateWhatsApp(String userId, String phoneE164) async {
    try {
      await _supabase
          .from('users')
          .update({'whatsapp_number': phoneE164})
          .eq('id', userId);
    } catch (e) {
      throw DatabaseException('Error actualizando WhatsApp', e);
    }
  }
}
