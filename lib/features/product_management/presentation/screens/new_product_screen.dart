import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/new_product_provider.dart';

/// Pantalla de publicación de nuevo producto
///
/// Mobile-first: scroll natural, validación en tiempo real,
/// selector de imágenes nativo, contadores de caracteres.
class NewProductScreen extends ConsumerStatefulWidget {
  const NewProductScreen({super.key});

  @override
  ConsumerState<NewProductScreen> createState() => _NewProductScreenState();
}

class _NewProductScreenState extends ConsumerState<NewProductScreen> {
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();

  // Categorías hardcoded (las mismas del schema SQL)
  // En producción cargar desde CatalogRepository.getCategories()
  static const _categories = [
    ('cat-micro', 'Microcontroladores'),
    ('cat-boards', 'Placas de Desarrollo'),
    ('cat-sensors', 'Sensores'),
    ('cat-cameras', 'Cámaras'),
    ('cat-mics', 'Micrófonos'),
    ('cat-batteries', 'Baterías'),
    ('cat-rf', 'RF / Wireless'),
    ('cat-tools', 'Herramientas'),
    ('cat-cables', 'Cables y Conectores'),
    ('cat-other', 'Otros'),
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() => ref.read(newProductProvider.notifier).setTitle(_titleCtrl.text));
    _descCtrl.addListener(() => ref.read(newProductProvider.notifier).setDescription(_descCtrl.text));
    _priceCtrl.addListener(() => ref.read(newProductProvider.notifier).setPrice(_priceCtrl.text));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(newProductProvider);
    final notifier  = ref.read(newProductProvider.notifier);

    // Navegar al dashboard cuando el submit fue exitoso
    ref.listen(newProductProvider, (_, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Producto publicado! Aparecerá en el catálogo en breve.')),
        );
        context.go('/dashboard');
      }
    });

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    Widget formContent = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 700 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop) ...[
                // Enlace nativo web para retroceder
                TextButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text('Volver a mis publicaciones', style: AppTextStyles.labelMd),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.zinc600,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Info de vigencia
              _InfoBanner(),
              const SizedBox(height: 20),

              // Error global
              if (formState.errors['global'] != null) ...[
                _ErrorBanner(message: formState.errors['global']!),
                const SizedBox(height: 16),
              ],

              // Fotos
              _buildSectionLabel('Fotos del producto', required: true),
              const SizedBox(height: 8),
              _ImagePicker(
                images: formState.images,
                error: formState.errors['images'],
                onAdd:    notifier.pickImages,
                onRemove: notifier.removeImage,
              ),
              const SizedBox(height: 20),

              // Título
              _buildSectionLabel('Título', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _titleCtrl,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ej. Arduino Uno R3 con cable USB',
                  counterText: '${formState.title.length}/80',
                  errorText: formState.errors['title'],
                ),
              ),
              const SizedBox(height: 16),

              // Categoría
              _buildSectionLabel('Categoría', required: true),
              const SizedBox(height: 6),
              _CategoryDropdown(
                categories: _categories,
                selectedId: formState.categoryId,
                error: formState.errors['category'],
                onChanged: (id, name) => notifier.setCategory(id, name),
              ),
              const SizedBox(height: 16),

              // Precio
              _buildSectionLabel('Precio (S/)', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: 'S/  ',
                  hintText: '0.00',
                  errorText: formState.errors['price'],
                ),
              ),
              const SizedBox(height: 16),

              // Descripción
              _buildSectionLabel('Descripción', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _descCtrl,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Estado del producto, accesorios incluidos, motivo de venta…',
                  counterText: '${formState.descriptionLength}/500',
                  errorText: formState.errors['description'],
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // ── PB-09/10/11: Tipo — PRODUCTO / KIT ──────────────────────
              _buildSectionLabel('Tipo de publicación'),
              const SizedBox(height: 8),
              _TypeSelector(
                value: formState.type,
                onChanged: notifier.setType,
              ),
              const SizedBox(height: 16),

              // Curso (solo kits)
              if (formState.isKit) ...[
                _buildSectionLabel('Curso / Ciclo', required: true),
                const SizedBox(height: 6),
                TextField(
                  onChanged: notifier.setCourseLabel,
                  decoration: InputDecoration(
                    hintText: 'Ej. Electrónica Digital - 4to Ciclo',
                    errorText: formState.errors['courseLabel'],
                  ),
                ),
                const SizedBox(height: 16),

                // Componentes del kit
                _buildSectionLabel('Componentes del kit', required: true),
                const SizedBox(height: 6),
                ...formState.kitItems.asMap().entries.map((e) => _KitItemRow(
                      index: e.key,
                      item: e.value,
                      onNameChanged: (n) => notifier.updateKitItem(e.key, name: n),
                      onQtyChanged:  (q) => notifier.updateKitItem(e.key, qty: q),
                      onRemove:      () => notifier.removeKitItem(e.key),
                    )),
                if (formState.errors['kitItems'] != null)
                  Text(formState.errors['kitItems']!,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: notifier.addKitItem,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Agregar componente'),
                ),
                const SizedBox(height: 16),
              ],

              // ── PB-03: Ficha Técnica ─────────────────────────────────────
              _buildSectionLabel('🔧 Ficha Técnica (opcional)'),
              const SizedBox(height: 4),
              Text('Agrega más detalles para atraer compradores técnicos.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500)),
              const SizedBox(height: 12),

              TextField(
                onChanged: notifier.setModel,
                decoration: const InputDecoration(
                  labelText: 'Modelo / Referencia',
                  hintText: 'Ej. ESP32-WROOM-32, STM32F103',
                ),
              ),
              const SizedBox(height: 12),

              // Slider de condición
              Text('Estado del componente: ${formState.conditionValue}/10',
                  style: AppTextStyles.labelMd),
              Slider(
                value: formState.conditionValue.toDouble(),
                min: 1, max: 10, divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (v) => notifier.setCondition(v.round().toString()),
              ),
              const SizedBox(height: 8),

              TextField(
                onChanged: notifier.setDatasheetUrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Enlace Datasheet (PDF, Drive…)',
                  hintText: 'https://...',
                  errorText: formState.errors['datasheetUrl'],
                ),
              ),
              const SizedBox(height: 24),

              // ── PB-12/13: Tips y librería ─────────────────────────────────
              _buildSectionLabel('💡 Tips y Recursos (opcional)'),
              const SizedBox(height: 12),

              TextField(
                onChanged: notifier.setTips,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Consejos del Vendedor',
                  hintText: 'Cómo usar, errores comunes, configuración recomendada…',
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                onChanged: notifier.setGithubUrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Enlace GitHub / Librería',
                  hintText: 'https://github.com/...',
                  errorText: formState.errors['githubUrl'],
                ),
              ),
              const SizedBox(height: 28),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: formState.isSubmitting
                      ? null
                      : () {
                          final userId = ref.read(currentUserProvider)?.id;
                          if (userId != null) notifier.submit(userId);
                        },
                  child: formState.isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Publicar producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isDesktop) {
      return ResponsiveLayout(
        currentIndex: 2,
        showBottomNav: false,
        body: formContent,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar producto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: formContent,
    );
  }

  Widget _buildSectionLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.titleSm.copyWith(color: AppColors.zinc700),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

// ── Subwidgets ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tu publicación estará visible 14 días en el catálogo.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Text(
        '⚠️ $message',
        style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final List<XFile> images;
  final String? error;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _ImagePicker({
    required this.images,
    this.error,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 106,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Miniaturas seleccionadas
              ...images.asMap().entries.map((e) => _ImagePreview(
                    file: e.value,
                    onRemove: () => onRemove(e.key),
                  )),
              // Botón agregar
              if (images.length < 3)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 106,
                    height: 106,
                    margin: EdgeInsets.only(left: images.isEmpty ? 0 : 8),
                    decoration: BoxDecoration(
                      color: AppColors.zinc50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: error != null ? AppColors.error : AppColors.zinc300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 28,
                          color: error != null ? AppColors.error : AppColors.zinc400,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${images.length}/3',
                          style: AppTextStyles.labelSm.copyWith(
                            color: error != null ? AppColors.error : AppColors.zinc400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const _ImagePreview({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 106,
          height: 106,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: kIsWeb
                  ? NetworkImage(file.path) as ImageProvider
                  : FileImage(File(file.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 14,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<(String, String)> categories;
  final String selectedId;
  final String? error;
  final void Function(String id, String name) onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selectedId,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedId.isEmpty ? null : selectedId,
      hint: const Text('Selecciona una categoría…'),
      decoration: InputDecoration(errorText: error),
      items: categories
          .map((cat) => DropdownMenuItem(
                value: cat.$1,
                child: Text(cat.$2),
              ))
          .toList(),
      onChanged: (id) {
        if (id == null) return;
        final name = categories.firstWhere((c) => c.$1 == id).$2;
        onChanged(id, name);
      },
    );
  }
}

// ── PB-09: Selector de tipo ──────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _TypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _TypeOption(label: '📦 Producto', type: 'PRODUCT', selected: value == 'PRODUCT', onTap: () => onChanged('PRODUCT'))),
      const SizedBox(width: 10),
      Expanded(child: _TypeOption(label: '🧰 Kit',     type: 'KIT',     selected: value == 'KIT',     onTap: () => onChanged('KIT'))),
    ]);
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final String type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeOption({required this.label, required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.zinc50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.zinc200, width: selected ? 2 : 1),
        ),
        child: Center(
          child: Text(label, style: AppTextStyles.titleSm.copyWith(
            color: selected ? AppColors.primary : AppColors.zinc600,
          )),
        ),
      ),
    );
  }
}

// ── PB-10: Fila de componente del kit ────────────────────────────────────────

class _KitItemRow extends StatelessWidget {
  final int index;
  final KitItemForm item;
  final void Function(String) onNameChanged;
  final void Function(int) onQtyChanged;
  final VoidCallback onRemove;

  const _KitItemRow({
    required this.index,
    required this.item,
    required this.onNameChanged,
    required this.onQtyChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
          flex: 4,
          child: TextField(
            onChanged: onNameChanged,
            decoration: InputDecoration(
              hintText: 'Componente ${index + 1} (Ej. Arduino Nano)',
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: TextField(
            keyboardType: TextInputType.number,
            onChanged: (v) => onQtyChanged(int.tryParse(v) ?? 1),
            decoration: const InputDecoration(hintText: 'Cant.', isDense: true),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.zinc400),
          onPressed: onRemove,
        ),
      ]),
    );
  }
}
