import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/seller_ratings_datasource.dart';
import '../../domain/entities/seller_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Infraestructura
// ─────────────────────────────────────────────────────────────────────────────

final _sellerRatingsDataSourceProvider =
    Provider((_) => SellerRatingsDataSource());

// ─────────────────────────────────────────────────────────────────────────────
// Proveedor: perfil de vendedor con estrellas (por sellerId)
// ─────────────────────────────────────────────────────────────────────────────

final sellerProfileProvider =
    FutureProvider.family<SellerProfile?, String>((ref, sellerId) async {
  final ds = ref.read(_sellerRatingsDataSourceProvider);
  return ds.getSellerProfile(sellerId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifier: enviar calificación
// ─────────────────────────────────────────────────────────────────────────────

/// Estado del envío de calificación.
sealed class RatingSubmitState {
  const RatingSubmitState();
}

class RatingIdle    extends RatingSubmitState { const RatingIdle(); }
class RatingLoading extends RatingSubmitState { const RatingLoading(); }
class RatingSuccess extends RatingSubmitState { const RatingSuccess(); }
class RatingError   extends RatingSubmitState {
  final String message;
  const RatingError(this.message);
}

class SellerRatingNotifier extends Notifier<RatingSubmitState> {
  @override
  RatingSubmitState build() => const RatingIdle();

  Future<void> submit({
    required String sellerId,
    required String buyerId,
    required String productId,
    required int stars,
    String? comment,
  }) async {
    state = const RatingLoading();
    try {
      await ref
          .read(_sellerRatingsDataSourceProvider)
          .rateSeller(
            sellerId:  sellerId,
            buyerId:   buyerId,
            productId: productId,
            stars:     stars,
            comment:   comment,
          );
      state = const RatingSuccess();
      // Invalida el perfil del vendedor para que se refresque con el nuevo promedio
      ref.invalidate(sellerProfileProvider(sellerId));
    } catch (e) {
      state = RatingError(e.toString().replaceAll('DatabaseException: ', ''));
    }
  }

  void reset() => state = const RatingIdle();
}

final sellerRatingNotifierProvider =
    NotifierProvider<SellerRatingNotifier, RatingSubmitState>(
        SellerRatingNotifier.new);
