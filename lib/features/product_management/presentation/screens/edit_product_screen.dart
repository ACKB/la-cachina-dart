import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_product.dart';
import '../../domain/usecases/product_usecases.dart';
import '../providers/dashboard_provider.dart';

/// PB-08: Pantalla de edición de publicación
class EditProductScreen extends ConsumerStatefulWidget {
  final UserProduct product;
  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey    = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _datasheetCtrl;
  late TextEditingController _tipsCtrl;
  late TextEditingController _githubCtrl;
  late TextEditingController _courseLabelCtrl;
  late double _condition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleCtrl       = TextEditingController(text: p.title);
    _descCtrl        = TextEditingController(text: p.description);
    _priceCtrl       = TextEditingController(text: (p.price / 100).toStringAsFixed(0));
    _modelCtrl       = TextEditingController(text: p.model ?? '');
    _datasheetCtrl   = TextEditingController(text: p.datasheetUrl ?? '');
    _tipsCtrl        = TextEditingController(text: p.tips ?? '');
    _githubCtrl      = TextEditingController(text: p.githubUrl ?? '');
    _courseLabelCtrl = TextEditingController(text: p.courseLabel ?? '');
    _condition       = (p.condition ?? 7).toDouble();
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _modelCtrl.dispose(); _datasheetCtrl.dispose(); _tipsCtrl.dispose();
    _githubCtrl.dispose(); _courseLabelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    Widget formContent = Form(
      key: _formKey,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 700 : double.infinity,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isDesktop) ...[
                // Enlace nativo web para retroceder
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text('Volver a mis publicaciones', style: AppTextStyles.labelMd),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.zinc600,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // ── Datos principales ──────────────────────────────────────
              _buildSectionTitle('Información básica'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Título *'),
                validator: (v) => (v?.trim().length ?? 0) < 3 ? 'Mínimo 3 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descripción *'),
                validator: (v) => (v?.trim().length ?? 0) < 10 ? 'Mínimo 10 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                decoration: const InputDecoration(labelText: 'Precio (S/) *', prefixText: 'S/ '),
                validator: (v) {
                  final p = double.tryParse(v?.trim() ?? '');
                  if (p == null || p <= 0) return 'Precio inválido';
                  if (p > 9999) return 'Máximo S/ 9,999';
                  return null;
                },
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('🔧 Ficha técnica'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(labelText: 'Modelo / Referencia'),
              ),
              const SizedBox(height: 12),
              Text('Estado del componente: ${_condition.round()}/10',
                  style: AppTextStyles.labelMd),
              Slider(
                value: _condition,
                min: 1, max: 10, divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _condition = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _datasheetCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Enlace Datasheet (opcional)',
                  hintText: 'https://...',
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('💡 Tips y recursos'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tipsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Consejos del Vendedor'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _githubCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Enlace GitHub / Librería (opcional)',
                  hintText: 'https://github.com/...',
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: const Text('Guardar cambios'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                ),
              ),
              const SizedBox(height: 24),
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
      backgroundColor: AppColors.zinc50,
      appBar: AppBar(
        title: const Text('Editar publicación'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: formContent,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.headlineSm.copyWith(color: AppColors.zinc700));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final priceInCentavos = (double.parse(_priceCtrl.text.trim()) * 100).round();

    final failure = await ref.read(dashboardProvider.notifier).updateProduct(
      UpdateProductParams(
        productId:       widget.product.id,
        userId:          userId,
        title:           _titleCtrl.text.trim(),
        description:     _descCtrl.text.trim(),
        priceInCentavos: priceInCentavos,
        categoryId:      widget.product.categoryName,  // se usa el nombre como ID de fallback
        model:           _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
        condition:       _condition.round(),
        datasheetUrl:    _datasheetCtrl.text.trim().isEmpty ? null : _datasheetCtrl.text.trim(),
        tips:            _tipsCtrl.text.trim().isEmpty ? null : _tipsCtrl.text.trim(),
        githubUrl:       _githubCtrl.text.trim().isEmpty ? null : _githubCtrl.text.trim(),
        courseLabel:     _courseLabelCtrl.text.trim().isEmpty ? null : _courseLabelCtrl.text.trim(),
      ),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Publicación actualizada')),
      );
      context.pop();
    }
  }
}
