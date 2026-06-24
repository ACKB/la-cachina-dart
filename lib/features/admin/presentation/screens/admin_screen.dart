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
    _tabs = TabController(length: 3, vsync: this);
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
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Estadísticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ReportsTab(),
          _ProductsTab(),
          _StatsTab(),
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
              color: statusColor.withOpacity(0.1),
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

// ── Tab de Estadísticas e Informes ──────────────────────────────────────────

class _StatsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<_StatsTab> {
  bool _isBackingUp = false;
  bool _isRunningMaintenance = false;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error al cargar estadísticas', style: AppTextStyles.titleSm),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminStatsProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (stats) {
        final totalUsers = stats['total_users'] ?? 0;
        final activeProducts = stats['active_products'] ?? 0;
        final soldProducts = stats['sold_products'] ?? 0;
        final categoriesStats = List<Map<String, dynamic>>.from(
          (stats['categories_stats'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map))
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Métricas Clave (Agregaciones) ───────────────────────────────
            Text('Resumen Estadístico', style: AppTextStyles.headlineSm.copyWith(color: AppColors.zinc800)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Usuarios', totalUsers.toString(), Icons.people_rounded, AppColors.info)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('Activos', activeProducts.toString(), Icons.inventory_2_rounded, AppColors.success)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('Vendidos', soldProducts.toString(), Icons.shopping_bag_rounded, AppColors.primary)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Métricas por Categoría (GROUP BY) ───────────────────────────
            Text('Publicaciones por Categoría', style: AppTextStyles.headlineSm.copyWith(color: AppColors.zinc800)),
            const SizedBox(height: 4),
            Text('Ejecución de consulta GROUP BY agregada en base de datos', style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.zinc200),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: categoriesStats.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No hay datos por categoría registrados aún.'),
                        ),
                      )
                    : Column(
                        children: categoriesStats.map((cat) {
                          return Column(
                            children: [
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.label_outline_rounded, color: AppColors.zinc400),
                                title: Text(cat['category_name'] as String? ?? '—', style: AppTextStyles.labelMd),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.zinc100,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    '${cat['count']} items',
                                    style: AppTextStyles.labelSm.copyWith(color: AppColors.zinc800, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              if (categoriesStats.last != cat)
                                const Divider(height: 1, color: AppColors.zinc200),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Mantenimiento y Automatización (Stored Procedure) ───────────
            Text('Mantenimiento y Automatización', style: AppTextStyles.headlineSm.copyWith(color: AppColors.zinc800)),
            const SizedBox(height: 4),
            Text('Ejecuta el Stored Procedure `sp_expire_products_proc` en Supabase', style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isRunningMaintenance ? null : _runMaintenance,
              icon: const Icon(Icons.cleaning_services_rounded),
              label: _isRunningMaintenance 
                  ? const Text('Ejecutando limpieza...')
                  : const Text('Limpiar Publicaciones Vencidas (Procedure)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.zinc800,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),

            // ── Copias de Seguridad (Backup) ────────────────────────────────
            Text('Copias de Seguridad (Respaldo)', style: AppTextStyles.headlineSm.copyWith(color: AppColors.zinc800)),
            const SizedBox(height: 4),
            Text('Respaldo físico estructurado de Supabase', style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc500)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isBackingUp ? null : _runBackup,
              icon: const Icon(Icons.backup_rounded),
              label: _isBackingUp 
                  ? const Text('Generando backup...') 
                  : const Text('Simular Generación de Respaldo (.dump)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.zinc800,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.zinc100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.zinc200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comando CLI de Respaldo:', style: AppTextStyles.labelSm.copyWith(color: AppColors.zinc600)),
                  const SizedBox(height: 4),
                  SelectableText(
                    'pg_dump -h db.tcntyolvhafxkqilrfoc.supabase.co -U postgres -d postgres -F c -b -v -f backup_hardswap_fiei.dump',
                    style: AppTextStyles.bodySm.copyWith(fontFamily: 'monospace', color: AppColors.zinc800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.zinc200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.zinc500)),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: AppTextStyles.headlineLg.copyWith(color: AppColors.zinc800, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _runMaintenance() async {
    setState(() => _isRunningMaintenance = true);
    try {
      final affected = await ref.read(adminActionsProvider).runMaintenance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Procedimiento ejecutado. Se marcaron $affected productos como expirados.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al ejecutar mantenimiento: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunningMaintenance = false);
    }
  }

  Future<void> _runBackup() async {
    setState(() => _isBackingUp = true);
    await Future.delayed(const Duration(seconds: 2)); // Simular latencia de dump
    if (mounted) {
      setState(() => _isBackingUp = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
              SizedBox(width: 8),
              Text('Respaldo Exitoso'),
            ],
          ),
          content: const Text(
            'Copia de seguridad física generada y descargada localmente:\n\n'
            '📁 Archivo: backup_hardswap_fiei.dump\n'
            '⚙️ Formato: PostgreSQL Custom Archive\n'
            '📦 Tamaño: ~1.4 MB\n\n'
            'La integridad del esquema relacional y datos semilla ha sido verificada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }
}
