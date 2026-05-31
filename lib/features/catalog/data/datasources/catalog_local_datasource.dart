import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/catalog_product_model.dart';

/// DataSource del Catálogo — capa de Datos
///
/// Integrado con Supabase PostgreSQL. Incluye kit_items para kits.
class CatalogLocalDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  CatalogLocalDataSource();

  /// Productos disponibles, no vencidos, más recientes primero (máx 50).
  Future<List<CatalogProductModel>> getAvailableProducts() async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();

      final List<dynamic> data = await _supabase
          .from('products')
          .select('''
            id, title, description, price, status, created_at, expires_at,
            images_base64, category_id, user_id,
            model, condition, datasheet_url, tips, github_url, type, course_label,
            categories ( id, name ),
            users!products_user_id_fkey ( id, name, whatsapp_number ),
            kit_items ( component_name, quantity )
          ''')
          .eq('status', 'AVAILABLE')
          .gt('expires_at', nowUtc)
          .order('created_at', ascending: false)
          .limit(100);

      if (data.isEmpty) return [];
      return data.map((row) => CatalogProductModel.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DatabaseException('Error cargando catálogo de Supabase', e);
    }
  }
}
