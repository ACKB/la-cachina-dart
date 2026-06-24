import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/seller_rating_provider.dart';
import 'seller_rating_widget.dart';

/// Bottom sheet modal para que el comprador califique al vendedor.
///
/// Se abre desde la pantalla de detalle del producto.
/// Lanza la validación de negocio en el trigger de la BD:
///   - No puede calificarse a sí mismo.
///   - Solo si el producto está en estado SOLD.
class RateSellerBottomSheet extends ConsumerStatefulWidget {
  final String sellerId;
  final String buyerId;
  final String productId;
  final String sellerName;

  const RateSellerBottomSheet({
    super.key,
    required this.sellerId,
    required this.buyerId,
    required this.productId,
    required this.sellerName,
  });

  static Future<void> show({
    required BuildContext context,
    required String sellerId,
    required String buyerId,
    required String productId,
    required String sellerName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RateSellerBottomSheet(
        sellerId:   sellerId,
        buyerId:    buyerId,
        productId:  productId,
        sellerName: sellerName,
      ),
    );
  }

  @override
  ConsumerState<RateSellerBottomSheet> createState() =>
      _RateSellerBottomSheetState();
}

class _RateSellerBottomSheetState
    extends ConsumerState<RateSellerBottomSheet> {
  int _selectedStars = 0;
  final _commentCtrl = TextEditingController();

  static const _labels = [
    '', 'Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente',
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerRatingNotifierProvider);

    // Cierra automáticamente al completar con éxito
    ref.listen(sellerRatingNotifierProvider, (_, next) {
      if (next is RatingSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⭐ ¡Calificación enviada! Gracias por tu reseña.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    });

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.zinc200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text(
              'Calificar al vendedor',
              style: AppTextStyles.headlineSm,
            ),
            const SizedBox(height: 4),
            Text(
              widget.sellerName,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500),
            ),
            const SizedBox(height: 24),

            // Estrellas interactivas
            InteractiveStarRow(
              size: 44,
              onChanged: (v) => setState(() => _selectedStars = v),
            ),
            const SizedBox(height: 8),

            // Etiqueta de la calificación seleccionada
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _selectedStars > 0
                    ? _labels[_selectedStars]
                    : 'Toca para calificar',
                key: ValueKey(_selectedStars),
                style: AppTextStyles.bodyMd.copyWith(
                  color: _selectedStars > 0
                      ? AppColors.amber
                      : AppColors.zinc400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Campo de comentario opcional
            TextField(
              controller: _commentCtrl,
              maxLength:  300,
              maxLines:   3,
              decoration: InputDecoration(
                hintText: 'Escribe un comentario opcional...',
                hintStyle: AppTextStyles.bodySm
                    .copyWith(color: AppColors.zinc400),
                filled:      true,
                fillColor:   AppColors.zinc50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   BorderSide(color: AppColors.zinc200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   BorderSide(color: AppColors.zinc200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),

            // Mensaje de error
            if (state is RatingError) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(state.message,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.error)),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            // Botón de enviar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state is RatingLoading || _selectedStars == 0
                    ? null
                    : () => ref
                        .read(sellerRatingNotifierProvider.notifier)
                        .submit(
                          sellerId:  widget.sellerId,
                          buyerId:   widget.buyerId,
                          productId: widget.productId,
                          stars:     _selectedStars,
                          comment:   _commentCtrl.text.trim().isEmpty
                              ? null
                              : _commentCtrl.text.trim(),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.zinc200,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: state is RatingLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enviar calificación',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
