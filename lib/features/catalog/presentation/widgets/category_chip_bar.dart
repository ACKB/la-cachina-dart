import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/catalog_provider.dart';

/// Barra de chips de categoría — scrollable horizontal
///
/// Equivalente a CategoryBar.tsx del proyecto Next.js original.
class CategoryChipBar extends ConsumerWidget {
  const CategoryChipBar({super.key});

  static const _categories = [
    ('Microcontroladores', '⚡'),
    ('Placas de Desarrollo', '🔧'),
    ('Sensores', '🌡️'),
    ('Cámaras', '📷'),
    ('Micrófonos', '🎙️'),
    ('Baterías', '🔋'),
    ('RF / Wireless', '📡'),
    ('Herramientas', '🔨'),
    ('Cables y Conectores', '🔌'),
    ('Otros', '📦'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCategory = ref.watch(activeCategoryProvider);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'Todas',
            emoji: '🏷️',
            isActive: activeCategory == null,
            onTap: () {
              ref.read(activeCategoryProvider.notifier).state = null;
              ref.read(searchQueryProvider.notifier).state   = '';
            },
          ),
          ..._categories.map((cat) {
            final (label, emoji) = cat;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _Chip(
                label: label,
                emoji: emoji,
                isActive: activeCategory == label,
                onTap: () {
                  final current =
                      ref.read(activeCategoryProvider.notifier).state;
                  ref.read(activeCategoryProvider.notifier).state =
                      current == label ? null : label;
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isActive;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.emoji,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.zinc200,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          '$emoji  $label',
          style: AppTextStyles.labelMd.copyWith(
            color: isActive ? Colors.white : AppColors.zinc600,
          ),
        ),
      ),
    );
  }
}
