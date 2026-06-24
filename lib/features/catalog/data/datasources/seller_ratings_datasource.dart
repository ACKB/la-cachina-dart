import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/seller_profile.dart';

/// DataSource para calificaciones de vendedores.
///
/// Lee desde `public.v_seller_profiles` y escribe en `public.seller_ratings`.
class SellerRatingsDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene el perfil con estrellas de un vendedor por su ID.
  Future<SellerProfile?> getSellerProfile(String sellerId) async {
    try {
      final data = await _supabase
          .from('v_seller_profiles')
          .select()
          .eq('seller_id', sellerId)
          .maybeSingle();

      if (data == null) return null;
      return _mapToEntity(data);
    } catch (e) {
      throw DatabaseException('Error cargando perfil del vendedor', e);
    }
  }

  /// Envía una calificación de estrellas al vendedor.
  ///
  /// [stars] debe ser 1–5. [comment] es opcional (máx 300 chars).
  /// Lanza [DatabaseException] si ya calificó esta transacción o si
  /// el producto no está en estado SOLD.
  Future<void> rateSeller({
    required String sellerId,
    required String buyerId,
    required String productId,
    required int stars,
    String? comment,
  }) async {
    try {
      await _supabase.from('seller_ratings').insert({
        'seller_id':  sellerId,
        'buyer_id':   buyerId,
        'product_id': productId,
        'stars':      stars,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      });
    } on PostgrestException catch (e) {
      // Código 23505 = unique_violation (ya calificó esta transacción)
      if (e.code == '23505') {
        throw DatabaseException('Ya calificaste esta transacción anteriormente.', e);
      }
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw DatabaseException('Error al enviar la calificación', e);
    }
  }

  SellerProfile _mapToEntity(Map<String, dynamic> map) {
    return SellerProfile(
      sellerId:      map['seller_id'].toString(),
      sellerName:    map['seller_name']   as String? ?? 'Vendedor',
      whatsappNumber: map['whatsapp_number'] as String?,
      emailVerified: map['email_verified'] as bool? ?? false,
      avgStars:      (map['avg_stars'] as num?)?.toDouble() ?? 0.0,
      totalRatings:  (map['total_ratings'] as int?) ?? 0,
      totalSold:     (map['total_sold']    as int?) ?? 0,
      stars5:        (map['stars_5'] as int?) ?? 0,
      stars4:        (map['stars_4'] as int?) ?? 0,
      stars3:        (map['stars_3'] as int?) ?? 0,
      stars2:        (map['stars_2'] as int?) ?? 0,
      stars1:        (map['stars_1'] as int?) ?? 0,
      sellerLevel:   map['seller_level']  as String? ?? 'Nuevo',
    );
  }
}
