import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';

class FavoritesDatasource {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// IDs de productos favoritos del usuario
  Future<Set<String>> getFavoriteIds(String userId) async {
    try {
      final data = await _supabase
          .from('favorites')
          .select('product_id')
          .eq('user_id', userId);
      return {for (final row in data as List) row['product_id'].toString()};
    } catch (e) {
      throw DatabaseException('Error cargando favoritos', e);
    }
  }

  Future<void> addFavorite({required String userId, required String productId}) async {
    try {
      await _supabase.from('favorites').insert({'user_id': userId, 'product_id': productId});
    } catch (e) {
      throw DatabaseException('Error agregando favorito', e);
    }
  }

  Future<void> removeFavorite({required String userId, required String productId}) async {
    try {
      await _supabase.from('favorites').delete()
          .eq('user_id', userId).eq('product_id', productId);
    } catch (e) {
      throw DatabaseException('Error eliminando favorito', e);
    }
  }
}
