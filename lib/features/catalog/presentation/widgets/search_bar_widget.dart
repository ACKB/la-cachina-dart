import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/catalog_provider.dart';

/// Barra de búsqueda del catálogo
///
/// Escribe en [searchQueryProvider] — el filtrado ocurre en [filteredCatalogProvider].
class CatalogSearchBar extends ConsumerStatefulWidget {
  const CatalogSearchBar({super.key});

  @override
  ConsumerState<CatalogSearchBar> createState() => _CatalogSearchBarState();
}

class _CatalogSearchBarState extends ConsumerState<CatalogSearchBar> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _controller.text;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);

    // Sincronizar si se limpia desde fuera (ej. seleccionar categoría)
    if (query.isEmpty && _controller.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.clear();
      });
    }

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar componentes, marcas…',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.zinc400,
          size: 20,
        ),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.zinc400,
                onPressed: () {
                  _controller.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
