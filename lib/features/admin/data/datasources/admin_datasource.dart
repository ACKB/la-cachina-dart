import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';

class AdminDatasource {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene todas las publicaciones activas (para moderar)
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select('id, title, status, created_at, users!products_user_id_fkey(email, name)')
          .order('created_at', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      throw DatabaseException('Error cargando productos para moderación', e);
    }
  }

  /// Oculta una publicación (cambia status a EXPIRED)
  Future<void> hideProduct(String productId) async {
    try {
      await _supabase.from('products').update({'status': 'EXPIRED'}).eq('id', productId);
    } catch (e) {
      throw DatabaseException('Error ocultando producto', e);
    }
  }

  /// Elimina una publicación definitivamente
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);
    } catch (e) {
      throw DatabaseException('Error eliminando producto', e);
    }
  }

  /// Suspende un usuario (actualiza campo email_verified a false como proxy)
  Future<void> suspendUser(String userId) async {
    try {
      await _supabase.from('users').update({'email_verified': false}).eq('id', userId);
    } catch (e) {
      throw DatabaseException('Error suspendiendo usuario', e);
    }
  }

  /// Obtiene reportes pendientes
  Future<List<Map<String, dynamic>>> getReports() async {
    try {
      final data = await _supabase
          .from('reports')
          .select('id, reason, created_at, resolved, products(id, title), users!reports_reporter_id_fkey(name, email)')
          .eq('resolved', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      throw DatabaseException('Error cargando reportes', e);
    }
  }

  /// Marca un reporte como resuelto
  Future<void> resolveReport(String reportId) async {
    try {
      await _supabase.from('reports').update({'resolved': true}).eq('id', reportId);
    } catch (e) {
      throw DatabaseException('Error resolviendo reporte', e);
    }
  }

  /// Obtiene estadísticas agregadas de la base de datos (GROUP BY / HAVING / Aggregations)
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _supabase.rpc('get_admin_stats');
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw DatabaseException('Error obteniendo estadísticas de administrador', e);
    }
  }

  /// Ejecuta el mantenimiento de expiración de publicaciones antiguas en lote
  Future<int> runExpireMaintenance() async {
    try {
      final response = await _supabase.rpc('run_expire_maintenance');
      return response as int;
    } catch (e) {
      throw DatabaseException('Error ejecutando mantenimiento de expiración', e);
    }
  }
}
