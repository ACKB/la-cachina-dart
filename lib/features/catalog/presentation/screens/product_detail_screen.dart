import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../domain/entities/catalog_product.dart';
import '../providers/catalog_provider.dart';

/// PB-05: Pantalla de detalle del producto con galería fullscreen,
/// descripción completa, ficha técnica, tips técnicos y contacto WhatsApp.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product    = ref.watch(productByIdProvider(widget.productId));
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
    final isFavorite = favoriteIds.contains(widget.productId);
    final user       = ref.watch(currentUserProvider);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producto')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    Widget detailContent;

    if (isDesktop) {
      detailContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna izquierda: Galería de fotos
            Expanded(
              flex: 5,
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.zinc200),
                ),
                elevation: 0,
                child: Container(
                  height: 520,
                  color: Colors.white,
                  child: _buildGallery(product),
                ),
              ),
            ),
            const SizedBox(width: 32),
            // Columna derecha: Detalles
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enlace nativo web para retroceder
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text('Volver al catálogo', style: AppTextStyles.labelMd),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.zinc600,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHeader(product),
                    if (product.model != null || product.condition != null || product.datasheetUrl != null)
                      _buildTechSpec(product),
                    _buildSellerInfo(product),
                    _buildSection('📋 Descripción', product.description),
                    if (product.isKit && product.kitItems.isNotEmpty)
                      _buildKitItems(product),
                    if (product.tips != null && product.tips!.isNotEmpty)
                      _buildTips(product),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: _buildWhatsAppButton(product),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      detailContent = CustomScrollView(
        slivers: [
          // ── AppBar con galería fullscreen ──────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.zinc900,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (user != null)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? AppColors.error : Colors.white,
                  ),
                  onPressed: () => ref.read(favoriteIdsProvider.notifier).toggle(product.id),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildGallery(product),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: título, precio, categoría ─────────────────────
                _buildHeader(product),

                // ── Ficha técnica PB-03 ────────────────────────────────────
                if (product.model != null || product.condition != null || product.datasheetUrl != null)
                  _buildTechSpec(product),

                // ── Info del vendedor ──────────────────────────────────────
                _buildSellerInfo(product),

                // ── Descripción completa ───────────────────────────────────
                _buildSection('📋 Descripción', product.description),

                // ── Kit items PB-10 ────────────────────────────────────────
                if (product.isKit && product.kitItems.isNotEmpty)
                  _buildKitItems(product),

                // ── Tips técnicos PB-13 ────────────────────────────────────
                if (product.tips != null && product.tips!.isNotEmpty)
                  _buildTips(product),

                // ── Botón WhatsApp ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: _buildWhatsAppButton(product),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ResponsiveLayout(
      currentIndex: 0,
      showBottomNav: false,
      body: detailContent,
    );
  }

  // ── Galería ────────────────────────────────────────────────────────────────

  Widget _buildGallery(CatalogProduct p) {
    if (p.imageUrls.isEmpty) {
      return Container(
        color: AppColors.zinc100,
        child: const Center(
          child: Icon(Icons.image_rounded, size: 64, color: AppColors.zinc300),
        ),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: p.imageUrls.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, i) {
            final raw = p.imageUrls[i];
            // Las imágenes vienen en Base64 desde la BD
            final isBase64 = !raw.startsWith('http');
            return GestureDetector(
              onTap: () => _openFullscreen(context, p.imageUrls, i),
              child: isBase64
                  ? Image.memory(
                      Uri.parse('data:image/jpeg;base64,$raw').data!.contentAsBytes(),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Image.network(raw, fit: BoxFit.cover, width: double.infinity),
            );
          },
        ),
        // Dots
        if (p.imageUrls.length > 1)
          Positioned(
            bottom: 12, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(p.imageUrls.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _currentPage ? 20 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i == _currentPage ? Colors.white : Colors.white38,
                ),
              )),
            ),
          ),
        // Badge tipo
        if (p.isKit)
          Positioned(
            top: 60, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('🧰 Kit', style: AppTextStyles.labelMd.copyWith(color: Colors.white)),
            ),
          ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(CatalogProduct p) {
    final price = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 0)
        .format(p.price / 100);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categoría + curso
          Row(children: [
            _Badge(p.categoryName, color: AppColors.zinc100, textColor: AppColors.zinc600),
            if (p.isKit && p.courseLabel != null) ...[
              const SizedBox(width: 6),
              _Badge(p.courseLabel!, color: AppColors.primaryLight, textColor: AppColors.primary),
            ],
          ]),
          const SizedBox(height: 10),
          Text(p.title, style: AppTextStyles.headlineSm),
          const SizedBox(height: 8),
          Text(price, style: AppTextStyles.price),
        ],
      ),
    );
  }

  // ── Ficha técnica ──────────────────────────────────────────────────────────

  Widget _buildTechSpec(CatalogProduct p) {
    return _Card(
      title: '🔧 Ficha técnica',
      child: Column(
        children: [
          if (p.model != null)
            _SpecRow('Modelo / Referencia', p.model!),
          if (p.condition != null)
            _ConditionRow(p.condition!),
          if (p.datasheetUrl != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openUrl(p.datasheetUrl!),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('Ver Datasheet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Vendedor ───────────────────────────────────────────────────────────────

  Widget _buildSellerInfo(CatalogProduct p) {
    return _Card(
      title: '👤 Vendedor',
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(
              p.sellerFirstName.isNotEmpty ? p.sellerFirstName[0].toUpperCase() : 'U',
              style: AppTextStyles.titleSm.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              p.sellerName ?? 'Usuario FIEI',
              style: AppTextStyles.bodyMd,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sección genérica ───────────────────────────────────────────────────────

  Widget _buildSection(String title, String text) {
    return _Card(
      title: title,
      child: Text(text, style: AppTextStyles.bodyMd.copyWith(height: 1.6)),
    );
  }

  // ── Kit items PB-10 ────────────────────────────────────────────────────────

  Widget _buildKitItems(CatalogProduct p) {
    return _Card(
      title: '📦 Contenido del kit',
      subtitle: 'Todos los componentes incluidos',
      child: Column(
        children: p.kitItems.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${item.quantity}x',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Text(item.componentName, style: AppTextStyles.bodyMd),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // ── Tips técnicos PB-13 ────────────────────────────────────────────────────

  Widget _buildTips(CatalogProduct p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB), // Amber-50
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💡 Tips Técnicos', style: AppTextStyles.headlineSm.copyWith(color: const Color(0xFF92400E))),
            const SizedBox(height: 8),
            Text(p.tips!, style: AppTextStyles.bodyMd.copyWith(height: 1.6, color: const Color(0xFF78350F))),
            if (p.githubUrl != null && p.githubUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Text(p.githubUrl!,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                  tooltip: 'Copiar enlace',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: p.githubUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📋 Enlace copiado al portapapeles')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary),
                  tooltip: 'Abrir enlace',
                  onPressed: () => _openUrl(p.githubUrl!),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  // ── WhatsApp CTA ───────────────────────────────────────────────────────────

  Widget _buildWhatsAppButton(CatalogProduct p) {
    if (!p.isContactable) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _launchWhatsApp(p),
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Contactar por WhatsApp'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          textStyle: AppTextStyles.titleSm.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _launchWhatsApp(CatalogProduct p) async {
    final price   = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 0)
        .format(p.price / 100);
    final message = 'Hola, vi tu publicación en La Cachina de FIEI: "${p.title}" a $price. ¿Sigue disponible?';
    final url = Uri.parse('https://wa.me/${p.sellerWhatsapp}?text=${Uri.encodeComponent(message)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openFullscreen(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullscreenGallery(images: images, initialIndex: initialIndex),
    ));
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Card({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.zinc100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineSm),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500)),
          Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final int condition;
  const _ConditionRow(this.condition);

  @override
  Widget build(BuildContext context) {
    final color = condition >= 8
        ? AppColors.success
        : condition >= 5
            ? AppColors.warning
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Estado del componente', style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500)),
          Row(children: [
            ...List.generate(10, (i) => Container(
              width: 18, height: 8,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: i < condition ? color : AppColors.zinc200,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(width: 6),
            Text('$condition/10', style: AppTextStyles.labelSm.copyWith(
                color: color, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _Badge(this.text, {required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: AppTextStyles.labelSm.copyWith(color: textColor)),
    );
  }
}

// ── Galería fullscreen ────────────────────────────────────────────────────────

class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _FullscreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl    = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) {
          final raw = widget.images[i];
          final isBase64 = !raw.startsWith('http');
          return InteractiveViewer(
            child: Center(
              child: isBase64
                  ? Image.memory(
                      Uri.parse('data:image/jpeg;base64,$raw').data!.contentAsBytes(),
                      fit: BoxFit.contain,
                    )
                  : Image.network(raw, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
