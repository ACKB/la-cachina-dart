import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Bottom Navigation Bar principal de la app
///
/// Índices:
///   0 → /          (Catálogo)
///   1 → /favorites (Mis Favoritos)
///   2 → /dashboard (Mis Ventas)
///   3 → /profile   (Perfil)
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  static const _tabs = [
    _NavTab(icon: Icons.grid_view_rounded,       label: 'Catálogo',   path: '/'),
    _NavTab(icon: Icons.favorite_rounded,        label: 'Favoritos',  path: '/favorites'),
    _NavTab(icon: Icons.storefront_rounded,      label: 'Mis Ventas', path: '/dashboard'),
    _NavTab(icon: Icons.person_outline_rounded,  label: 'Perfil',     path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        context.go(_tabs[index].path);
      },
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.zinc900
          : Colors.white,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      shadowColor: Colors.black12,
      elevation: 8,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: _tabs
          .map((t) => NavigationDestination(
                icon: Icon(t.icon, color: AppColors.zinc400),
                selectedIcon: Icon(t.icon, color: AppColors.primary),
                label: t.label,
              ))
          .toList(),
    );
  }

  static int indexForPath(String path) {
    if (path.startsWith('/favorites')) return 1;
    if (path.startsWith('/dashboard')) return 2;
    if (path.startsWith('/profile'))   return 3;
    return 0;
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final String path;
  const _NavTab({required this.icon, required this.label, required this.path});
}
