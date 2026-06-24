import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/admin_datasource.dart';

final _adminDsProvider = Provider((_) => AdminDatasource());

// ── Reportes pendientes ──────────────────────────────────────────────────────

final reportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(_adminDsProvider).getReports();
});

// ── Todos los productos (para moderación) ────────────────────────────────────

final allProductsAdminProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(_adminDsProvider).getAllProducts();
});

// ── Estadísticas analíticas del administrador ──────────────────────────────

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(_adminDsProvider).getAdminStats();
});

// ── Notifier de acciones admin ───────────────────────────────────────────────

final adminActionsProvider = Provider<AdminActions>((ref) => AdminActions(ref));

class AdminActions {
  final Ref _ref;
  AdminActions(this._ref);

  AdminDatasource get _ds => _ref.read(_adminDsProvider);

  Future<void> hideProduct(String productId) async {
    await _ds.hideProduct(productId);
    _ref.invalidate(allProductsAdminProvider);
    _ref.invalidate(adminStatsProvider);
  }

  Future<void> deleteProduct(String productId) async {
    await _ds.deleteProduct(productId);
    _ref.invalidate(allProductsAdminProvider);
    _ref.invalidate(adminStatsProvider);
  }

  Future<void> suspendUser(String userId) async {
    await _ds.suspendUser(userId);
  }

  Future<void> resolveReport(String reportId) async {
    await _ds.resolveReport(reportId);
    _ref.invalidate(reportsProvider);
  }

  Future<int> runMaintenance() async {
    final count = await _ds.runExpireMaintenance();
    _ref.invalidate(allProductsAdminProvider);
    _ref.invalidate(adminStatsProvider);
    return count;
  }
}
