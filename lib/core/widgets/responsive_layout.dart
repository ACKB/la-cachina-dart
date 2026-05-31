import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_bottom_nav.dart';

/// Layout responsivo para unificar la UI de Laptop/Desktop y Móvil/APK
class ResponsiveLayout extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final bool showBottomNav;
  final Widget? floatingActionButton;

  const ResponsiveLayout({
    super.key,
    required this.body,
    required this.currentIndex,
    this.showBottomNav = true,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (!isDesktop) {
      return Scaffold(
        body: body,
        bottomNavigationBar: showBottomNav ? AppBottomNav(currentIndex: currentIndex) : null,
        floatingActionButton: floatingActionButton,
      );
    }

    // Diseño Web para Laptop / Computadoras de Escritorio (Desktop UI Premium)
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          // Header Navbar superior elegante para la Web
          _WebDesktopHeader(currentIndex: currentIndex),
          
          // Contenido principal centrado con límite de ancho óptimo
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebDesktopHeader extends StatelessWidget {
  final int currentIndex;
  const _WebDesktopHeader({required this.currentIndex});

  static const _tabs = [
    _HeaderTab(icon: Icons.grid_view_rounded,       label: 'Catálogo',   path: '/'),
    _HeaderTab(icon: Icons.favorite_rounded,        label: 'Favoritos',  path: '/favorites'),
    _HeaderTab(icon: Icons.storefront_rounded,      label: 'Mis Ventas', path: '/dashboard'),
    _HeaderTab(icon: Icons.person_outline_rounded,  label: 'Perfil',     path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: AppColors.zinc200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sección de Logotipo e Identidad de Marca
          GestureDetector(
            onTap: () => context.go('/'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                    child: Text(
                      'K-china FIEI',
                      style: AppTextStyles.headlineLg.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pestañas de Navegación Horizontales (Navbar)
          Row(
            children: _tabs.asMap().entries.map((e) {
              final idx = e.key;
              final t = e.value;
              final isSelected = idx == currentIndex;

              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextButton.icon(
                  onPressed: () => context.go(t.path),
                  icon: Icon(
                    t.icon,
                    color: isSelected ? AppColors.primary : AppColors.zinc500,
                    size: 18,
                  ),
                  label: Text(
                    t.label,
                    style: AppTextStyles.labelMd.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.zinc700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: isSelected
                        ? AppColors.primaryLight.withValues(alpha: 0.4)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HeaderTab {
  final IconData icon;
  final String label;
  final String path;
  const _HeaderTab({required this.icon, required this.label, required this.path});
}
