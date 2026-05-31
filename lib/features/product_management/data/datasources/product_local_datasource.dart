import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_product_model.dart';

/// DataSource de gestión de productos — capa de Datos
///
/// Integrado con Supabase. Convierte imágenes locales a Base64.
class ProductLocalDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  ProductLocalDataSource();

  // ── Leer publicaciones del usuario ─────────────────────────────────────────

  Future<List<UserProductModel>> getUserProducts(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('products')
          .select('''
            id, title, description, price, status, created_at, expires_at, images_base64,
            model, condition, datasheet_url, tips, github_url, type, course_label,
            categories ( name )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((row) => UserProductModel.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DatabaseException('Error cargando publicaciones', e);
    }
  }

  // ── Crear producto ─────────────────────────────────────────────────────────

  Future<String> createProduct({
    required String title,
    required String description,
    required int    priceInCentavos,
    required String categoryId,
    required String userId,
    required List<XFile> images,
    String?  model,
    int?     condition,
    String?  datasheetUrl,
    String?  tips,
    String?  githubUrl,
    String   type = 'PRODUCT',
    String?  courseLabel,
    List<Map<String, dynamic>> kitItems = const [],
  }) async {
    try {
      final expiresAt = DateTime.now().toUtc().add(const Duration(days: 14)).toIso8601String();

      // Convertir imágenes a Base64 (las imágenes ya vienen comprimidas de image_picker)
      final base64Images = <String>[];
      for (final xFile in images.take(3)) {
        final bytes = await xFile.readAsBytes();
        base64Images.add(base64Encode(bytes));
      }

      // Mapear el ID de categoría hardcodeado al nombre real para buscar el UUID en la base de datos
      String categoryName = 'Otros';
      switch (categoryId) {
        case 'cat-micro': categoryName = 'Microcontroladores'; break;
        case 'cat-boards': categoryName = 'Placas de Desarrollo'; break;
        case 'cat-sensors': categoryName = 'Sensores'; break;
        case 'cat-cameras': categoryName = 'Cámaras'; break;
        case 'cat-mics': categoryName = 'Micrófonos'; break;
        case 'cat-batteries': categoryName = 'Baterías'; break;
        case 'cat-rf': categoryName = 'RF / Wireless'; break;
        case 'cat-tools': categoryName = 'Herramientas'; break;
        case 'cat-cables': categoryName = 'Cables y Conectores'; break;
        case 'cat-other': categoryName = 'Otros'; break;
      }

      // Obtener el UUID real de la categoría
      final catData = await _supabase.from('categories').select('id').eq('name', categoryName).single();
      final realCategoryId = catData['id'] as String;

      final data = await _supabase.from('products').insert({
        'title':        title,
        'description':  description,
        'price':        priceInCentavos,
        'category_id':  realCategoryId,
        'user_id':      userId,
        'expires_at':   expiresAt,
        'images_base64': base64Images,
        'model':         model,
        'condition':     condition,
        'datasheet_url': datasheetUrl,
        'tips':          tips,
        'github_url':    githubUrl,
        'type':          type,
        'course_label':  courseLabel,
      }).select('id').single();

      final productId = data['id'].toString();

      // Insertar componentes del kit si aplica
      if (type == 'KIT' && kitItems.isNotEmpty) {
        await _supabase.from('kit_items').insert(
          kitItems.map((item) => {
            'kit_id':         productId,
            'component_name': item['component_name'],
            'quantity':       item['quantity'],
          }).toList(),
        );
      }

      return productId;
    } catch (e) {
      throw DatabaseException('Error creando producto', e);
    }
  }

  // ── Actualizar producto (PB-08) ────────────────────────────────────────────

  Future<void> updateProduct({
    required String productId,
    required String userId,
    required String title,
    required String description,
    required int    priceInCentavos,
    required String categoryId,
    String?  model,
    int?     condition,
    String?  datasheetUrl,
    String?  tips,
    String?  githubUrl,
    String?  courseLabel,
  }) async {
    try {
      String categoryName = 'Otros';
      switch (categoryId) {
        case 'cat-micro': categoryName = 'Microcontroladores'; break;
        case 'cat-boards': categoryName = 'Placas de Desarrollo'; break;
        case 'cat-sensors': categoryName = 'Sensores'; break;
        case 'cat-cameras': categoryName = 'Cámaras'; break;
        case 'cat-mics': categoryName = 'Micrófonos'; break;
        case 'cat-batteries': categoryName = 'Baterías'; break;
        case 'cat-rf': categoryName = 'RF / Wireless'; break;
        case 'cat-tools': categoryName = 'Herramientas'; break;
        case 'cat-cables': categoryName = 'Cables y Conectores'; break;
        case 'cat-other': categoryName = 'Otros'; break;
      }

      final catData = await _supabase.from('categories').select('id').eq('name', categoryName).single();
      final realCategoryId = catData['id'] as String;

      await _supabase
          .from('products')
          .update({
            'title':         title,
            'description':   description,
            'price':         priceInCentavos,
            'category_id':   realCategoryId,
            'model':         model,
            'condition':     condition,
            'datasheet_url': datasheetUrl,
            'tips':          tips,
            'github_url':    githubUrl,
            'course_label':  courseLabel,
            'updated_at':    DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', productId)
          .eq('user_id', userId);
    } catch (e) {
      throw DatabaseException('Error actualizando producto', e);
    }
  }

  // ── Marcar vendido ─────────────────────────────────────────────────────────

  Future<void> markAsSold({required String productId, required String userId}) async {
    try {
      await _supabase
          .from('products')
          .update({'status': 'SOLD'})
          .eq('id', productId)
          .eq('user_id', userId)
          .eq('status', 'AVAILABLE');
    } catch (e) {
      throw DatabaseException('Error marcando como vendido', e);
    }
  }

  // ── Eliminar ───────────────────────────────────────────────────────────────

  Future<void> deleteProduct({required String productId, required String userId}) async {
    try {
      await _supabase
          .from('products')
          .delete()
          .eq('id', productId)
          .eq('user_id', userId);
    } catch (e) {
      throw DatabaseException('Error eliminando producto', e);
    }
  }
}
