import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/user_product.dart';
import '../providers/dashboard_provider.dart';

/// Tile de publicación propia en el dashboard
///
/// Mobile-first: Dismissible swipe-to-delete, thumbnail, precio, badge de estado.
class ProductListTile extends ConsumerWidget {
  final UserProduct product;
  const ProductListTile({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key('product_${product.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _delete(context, ref),
      background: _swipeBackground(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showActionsSheet(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Thumbnail
                _buildThumbnail(),
                const SizedBox(width: 12),
                // Info
                Expanded(child: _buildInfo()),
                const SizedBox(width: 8),
                // Badge de estado + días
                _buildStatusBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        height: 72,
        color: AppColors.zinc100,
        child: product.thumbnailUrl != null
            ? Image.network(
                product.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_rounded,
                  color: AppColors.zinc400,
                  size: 28,
                ),
              )
            : const Icon(Icons.image_rounded, color: AppColors.zinc300, size: 32),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleSm.copyWith(color: AppColors.zinc900),
        ),
        const SizedBox(height: 4),
        Text(
          product.categoryName,
          style: AppTextStyles.labelSm.copyWith(color: AppColors.zinc500),
        ),
        const SizedBox(height: 6),
        Text(_formatPrice(product.price), style: AppTextStyles.priceSmall),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final Color color;
    final Color bg;
    final String label;

    if (product.isSold) {
      color = AppColors.info;
      bg    = AppColors.infoSurface;
      label = 'Vendido';
    } else if (product.isExpired) {
      color = AppColors.zinc500;
      bg    = AppColors.zinc100;
      label = 'Vencido';
    } else {
      color = AppColors.success;
      bg    = AppColors.successSurface;
      label = '${product.daysRemaining}d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _swipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 26),
          const SizedBox(height: 4),
          Text(
            'Eliminar',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('¿Eliminar publicación?'),
            content: Text(
              'Se eliminará "${product.title}" de forma permanente.',
              style: AppTextStyles.bodyMd,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(dashboardProvider.notifier)
        .deleteProduct(product.id);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showActionsSheet(BuildContext context, WidgetRef ref) {
    if (product.isSold || product.isExpired) return;
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => _ActionsSheet(product: product),
    );
  }
}

String _formatPrice(int centavos) {
  final soles = centavos / 100;
  return 'S/ ${soles.toStringAsFixed(soles.truncateToDouble() == soles ? 0 : 2)}';
}

/// Bottom Sheet con acciones del producto (móvil-first)
class _ActionsSheet extends ConsumerWidget {
  final UserProduct product;
  const _ActionsSheet({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headlineSm,
            ),
            const SizedBox(height: 4),
            Text(
              _formatPrice(product.price),
              style: AppTextStyles.price,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Botón Editar — PB-08
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.edit_rounded, color: Color(0xFF3B82F6)),
              ),
              title: Text('Editar publicación', style: AppTextStyles.titleSm),
              subtitle: Text(
                'Modifica precio, descripción y campos técnicos.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/dashboard/edit', extra: product);
              },
            ),
            const SizedBox(height: 8),

            // Botón Marcar vendido
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.infoSurface,
                child: Icon(Icons.check_circle_outline_rounded, color: AppColors.info),
              ),
              title: Text('Marcar como vendido', style: AppTextStyles.titleSm),
              subtitle: Text(
                'El producto dejará de aparecer en el catálogo.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500),
              ),
              onTap: () async {
                final failure = await ref
                    .read(dashboardProvider.notifier)
                    .markAsSold(product.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (failure != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(failure.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Producto marcado como vendido! 🎉')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),

            // Botón Eliminar
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.errorSurface,
                child: Icon(Icons.delete_outline_rounded, color: AppColors.error),
              ),
              title: Text(
                'Eliminar publicación',
                style: AppTextStyles.titleSm.copyWith(color: AppColors.error),
              ),
              subtitle: Text(
                'Esta acción no se puede deshacer.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('¿Eliminar publicación?'),
                    content: Text(
                      'Se eliminará "${product.title}" de forma permanente.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  Navigator.pop(context);
                  await ref.read(dashboardProvider.notifier).deleteProduct(product.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
