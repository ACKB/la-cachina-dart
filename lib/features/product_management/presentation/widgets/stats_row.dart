import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Fila de estadísticas del dashboard (Activas / Vencidas / Vendidas)
class StatsRow extends StatelessWidget {
  final int active;
  final int expired;
  final int sold;

  const StatsRow({
    super.key,
    required this.active,
    required this.expired,
    required this.sold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: active,  label: 'Activas',  color: AppColors.success,  bg: AppColors.successSurface),
        const SizedBox(width: 10),
        _StatCard(value: expired, label: 'Vencidas', color: AppColors.zinc500,  bg: AppColors.zinc100),
        const SizedBox(width: 10),
        _StatCard(value: sold,    label: 'Vendidas', color: AppColors.info,     bg: AppColors.infoSurface),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: AppTextStyles.displayMd.copyWith(
                color: color,
                fontSize: 34,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.labelSm.copyWith(color: color.withOpacity(0.75)),
            ),
          ],
        ),
      ),
    );
  }
}
