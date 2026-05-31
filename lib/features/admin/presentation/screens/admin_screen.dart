import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_provider.dart';

/// PB-14: Panel de Moderación — solo accesible para admins
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zinc50,
      appBar: AppBar(
        backgroundColor: AppColors.zinc900,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Panel de Administración', style: AppTextStyles.titleSm.copyWith(color: Colors.white)),
            Text('K-china FIEI', style: AppTextStyles.bodySm.copyWith(color: Colors.white60)),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.flag_rounded), text: 'Reportes'),
            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Productos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ReportsTab(),
          _ProductsTab(),
        ],
      ),
    );
  }
}

// ── Tab de Reportes ──────────────────────────────────────────────────────────

class _ReportsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.bodySm)),
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.success),
              const SizedBox(height: 12),
              Text('Sin reportes pendientes', style: AppTextStyles.headlineSm.copyWith(color: AppColors.zinc600)),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ReportTile(report: reports[i], ref: ref),
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Map<String, dynamic> report;
  final WidgetRef ref;
  const _ReportTile({required this.report, required this.ref});

  @override
  Widget build(BuildContext context) {
    final product  = report['products'] as Map<String, dynamic>? ?? {};
    final reporter = report['users']    as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.flag_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(product['title'] as String? ?? '—',
                  style: AppTextStyles.titleSm, overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Reportado por: ${reporter['name'] ?? reporter['email'] ?? '—'}',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.errorSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(report['reason'] as String? ?? '—',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
          ),
          const SizedBox(height: 10),
          Row(children: [
            OutlinedButton.icon(
              onPressed: () async {
                final pid = product['id'] as String?;
                if (pid != null) {
                  await ref.read(adminActionsProvider).hideProduct(pid);
                }
                await ref.read(adminActionsProvider).resolveReport(report['id'] as String);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Publicación ocultada')),
                  );
                }
              },
              icon: const Icon(Icons.visibility_off_rounded, size: 16),
              label: const Text('Ocultar'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error)),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () async {
                await ref.read(adminActionsProvider).resolveReport(report['id'] as String);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reporte marcado como resuelto')),
                  );
                }
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Resolver'),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Tab de Productos ─────────────────────────────────────────────────────────

class _ProductsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsAdminProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _AdminProductTile(product: products[i], ref: ref),
      ),
    );
  }
}

class _AdminProductTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final WidgetRef ref;
  const _AdminProductTile({required this.product, required this.ref});

  @override
  Widget build(BuildContext context) {
    final user   = product['users'] as Map<String, dynamic>? ?? {};
    final status = product['status'] as String? ?? 'AVAILABLE';

    Color statusColor;
    switch (status) {
      case 'AVAILABLE': statusColor = AppColors.success; break;
      case 'SOLD':      statusColor = AppColors.info;    break;
      default:          statusColor = AppColors.zinc400; break;
    }

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Text(product['title'] as String? ?? '—', style: AppTextStyles.titleSm,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(user['email'] as String? ?? '—',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          // Badge de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(status, style: AppTextStyles.labelSm.copyWith(color: statusColor)),
          ),
          const SizedBox(width: 4),
          // Menú
          PopupMenuButton<String>(
            onSelected: (action) async {
              final id = product['id'] as String;
              if (action == 'hide') {
                await ref.read(adminActionsProvider).hideProduct(id);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Publicación ocultada')));
              } else if (action == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('¿Eliminar publicación?'),
                    content: const Text('Esta acción es irreversible.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(adminActionsProvider).deleteProduct(id);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Publicación eliminada')));
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'hide',   child: Text('Ocultar publicación')),
              const PopupMenuItem(value: 'delete', child: Text('Eliminar permanentemente')),
            ],
          ),
        ]),
      ),
    );
  }
}
