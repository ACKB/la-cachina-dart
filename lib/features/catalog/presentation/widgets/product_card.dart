import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../domain/entities/catalog_product.dart';

String _formatPrice(int centavos) {
  return NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 0)
      .format(centavos / 100);
}

/// Card de producto para el catálogo
///
/// PB-05: Tappable → navega a ProductDetailScreen
/// PB-06: Ícono ❤️ para agregar/quitar favoritos
class ProductCard extends ConsumerStatefulWidget {
  final CatalogProduct product;
  const ProductCard({super.key, required this.product});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p           = widget.product;
    final user        = ref.watch(currentUserProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
    final isFavorite  = favoriteIds.contains(p.id);

    return GestureDetector(
      onTap: () => context.push('/catalog/${p.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen / Carrusel ─────────────────────────────────────────
            _buildImageSection(p, user != null, isFavorite),

            // ── Info ──────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo badge si es Kit
                    if (p.isKit)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('🧰 Kit', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                      ),
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSm.copyWith(color: AppColors.zinc900, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.zinc400),
                      const SizedBox(width: 3),
                      Text(p.sellerFirstName,
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500)),
                    ]),
                    const Spacer(),
                    Text(_formatPrice(p.price), style: AppTextStyles.price),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // ── CTA WhatsApp ──────────────────────────────────────────────
            _buildWhatsAppCta(p),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(CatalogProduct p, bool isLoggedIn, bool isFavorite) {
    return Stack(
      children: [
        SizedBox(
          height: 168,
          width: double.infinity,
          child: p.imageUrls.isNotEmpty
              ? PageView.builder(
                  controller: _pageController,
                  itemCount: p.imageUrls.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) {
                    final raw = p.imageUrls[i];
                    final isBase64 = !raw.startsWith('http');
                    if (isBase64) {
                      try {
                        return Image.memory(
                          Uri.parse('data:image/jpeg;base64,$raw').data!.contentAsBytes(),
                          fit: BoxFit.cover,
                        );
                      } catch (_) {}
                    }
                    return CachedNetworkImage(
                      imageUrl: raw, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.zinc100),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.zinc100,
                        child: const Icon(Icons.image_not_supported_rounded,
                            color: AppColors.zinc400, size: 32),
                      ),
                    );
                  },
                )
              : Container(
                  color: AppColors.zinc100,
                  child: const Center(
                    child: Icon(Icons.image_rounded, size: 40, color: AppColors.zinc300),
                  ),
                ),
        ),

        // Badge categoría
        Positioned(
          top: 10, left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6)],
            ),
            child: Text(p.categoryName,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.zinc800)),
          ),
        ),

        // PB-06: Botón de favorito ─────────────────────────────────────
        if (isLoggedIn)
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: () => ref.read(favoriteIdsProvider.notifier).toggle(p.id),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                ),
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                  color: isFavorite ? AppColors.error : AppColors.zinc400,
                ),
              ),
            ),
          ),

        // Dots del carrusel
        if (p.imageUrls.length > 1)
          Positioned(
            bottom: 8, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(p.imageUrls.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _currentPage ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == _currentPage ? Colors.white : Colors.white.withValues(alpha: 0.5),
                ),
              )),
            ),
          ),
      ],
    );
  }

  Widget _buildWhatsAppCta(CatalogProduct p) {
    if (!p.isContactable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        color: AppColors.zinc100,
        child: Text('Sin contacto', textAlign: TextAlign.center,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.zinc400)),
      );
    }
    return InkWell(
      onTap: () => _launchWhatsApp(p),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        color: const Color(0xFF25D366),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text('Contactar — WhatsApp',
              style: AppTextStyles.labelMd.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Future<void> _launchWhatsApp(CatalogProduct p) async {
    final price   = _formatPrice(p.price);
    final message = 'Hola, vi tu publicación en La Cachina de FIEI: "${p.title}" a $price. ¿Sigue disponible?';
    final url = Uri.parse('https://wa.me/${p.sellerWhatsapp}?text=${Uri.encodeComponent(message)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
