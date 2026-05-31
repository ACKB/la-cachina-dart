import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../data/datasources/favorites_datasource.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

final _favoritesDsProvider = Provider((_) => FavoritesDatasource());

// ── Provider de IDs favoritos del usuario ──────────────────────────────────

final favoriteIdsProvider =
    AsyncNotifierProvider<FavoriteIdsNotifier, Set<String>>(FavoriteIdsNotifier.new);

class FavoriteIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return {};
    return ref.read(_favoritesDsProvider).getFavoriteIds(user.id);
  }

  Future<void> toggle(String productId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final ids  = state.valueOrNull ?? {};
    final ds   = ref.read(_favoritesDsProvider);
    final newIds = Set<String>.from(ids);

    if (ids.contains(productId)) {
      await ds.removeFavorite(userId: user.id, productId: productId);
      newIds.remove(productId);
    } else {
      await ds.addFavorite(userId: user.id, productId: productId);
      newIds.add(productId);
    }
    state = AsyncValue.data(newIds);
  }
}

// ── Productos favoritos (derivado del catálogo) ─────────────────────────────

final favoritesListProvider = Provider((ref) {
  final ids      = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
  final catalog  = ref.watch(catalogProvider).valueOrNull ?? [];
  return catalog.where((p) => ids.contains(p.id)).toList();
});
