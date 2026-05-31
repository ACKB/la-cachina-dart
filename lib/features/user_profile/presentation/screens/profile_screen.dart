import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';

// BottomNav index: 3 (con tab Favoritos el perfil es 3)

/// Pantalla de Perfil — número de WhatsApp, info de la cuenta, cerrar sesión
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _phoneCtrl = TextEditingController();
  String? _phoneError;
  bool _isSaving = false;
  bool _saveSuccess = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user        = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(body: SizedBox.shrink());
    }

    return ResponsiveLayout(
      currentIndex: 3,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => ErrorView(
          title: 'Error cargando perfil',
          message: e.toString(),
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (profile) {
          // Pre-llenar el campo con el número actual
          if (profile?.displayPhone != null && _phoneCtrl.text.isEmpty) {
            _phoneCtrl.text = profile!.displayPhone!;
          }

          final width = MediaQuery.of(context).size.width;
          final isDesktop = width >= 900;

          return CustomScrollView(
            slivers: [
              // ── AppBar con avatar grande ─────────────────────────────────
              if (!isDesktop)
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.heroGradient,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            child: Text(
                              user.initial,
                              style: AppTextStyles.displayMd.copyWith(
                                color: Colors.white,
                                fontSize: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user.name ?? user.email,
                            style: AppTextStyles.headlineSm
                                .copyWith(color: Colors.white),
                          ),
                          Text(
                            user.email,
                            style: AppTextStyles.bodySm
                                .copyWith(color: Colors.white.withOpacity(0.75)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isDesktop) const SliverToBoxAdapter(child: SizedBox(height: 32)),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.list(
                  children: [
                    if (isDesktop) ...[
                      _buildDesktopProfileCard(user),
                      const SizedBox(height: 24),
                    ],
                    // ── Sección WhatsApp ──────────────────────────────────
                    _buildSectionTitle('📱 Número de contacto'),
                    const SizedBox(height: 6),
                    Text(
                      'Los compradores te contactarán por WhatsApp cuando vean tu producto.',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.zinc500),
                    ),
                    const SizedBox(height: 14),
                    _buildWhatsAppForm(context, profile?.hasWhatsapp ?? false),
                    const SizedBox(height: 28),

                    // ── Sección Info cuenta ───────────────────────────────
                    _buildSectionTitle('🎓 Cuenta institucional'),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Correo', value: user.email),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Estado',
                      value: '✓ Verificado — UNFV FIEI',
                      valueColor: AppColors.success,
                    ),
                    const SizedBox(height: 28),

                    // ── Panel Admin PB-14 — solo visible para admins ──────
                    _AdminButton(),
                    const SizedBox(height: 12),

                    // ── Cerrar sesión ────────────────────────────────────
                    OutlinedButton.icon(
                      onPressed: () => _signOut(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Cerrar sesión'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headlineSm.copyWith(color: AppColors.zinc800),
    );
  }

  Widget _buildWhatsAppForm(BuildContext context, bool hasNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado actual del número
        if (hasNumber) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Número configurado — compradores pueden contactarte',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Input + botón guardar
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 9,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                  if (_saveSuccess) setState(() => _saveSuccess = false);
                },
                decoration: InputDecoration(
                  prefixText: '🇵🇪 +51  ',
                  hintText: '987 654 321',
                  counterText: '',
                  errorText: _phoneError,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWhatsApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(88, 52),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),

        if (_saveSuccess) ...[
          const SizedBox(height: 6),
          Text(
            '✓ Número actualizado correctamente.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.success),
          ),
        ],
      ],
    );
  }

  Future<void> _saveWhatsApp() async {
    setState(() {
      _isSaving    = true;
      _phoneError  = null;
      _saveSuccess = false;
    });

    final error = await ref
        .read(userProfileProvider.notifier)
        .updateWhatsApp(_phoneCtrl.text);

    setState(() {
      _isSaving    = false;
      _phoneError  = error;
      _saveSuccess = error == null;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) context.go('/login');
  }

  Widget _buildDesktopProfileCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.zinc200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              user.initial,
              style: AppTextStyles.displayMd.copyWith(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? user.email,
                  style: AppTextStyles.headlineLg.copyWith(
                    color: AppColors.zinc800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.zinc500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.zinc200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.zinc500),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.labelMd.copyWith(
                color: valueColor ?? AppColors.zinc800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget botón Admin ─────────────────────────────────────────────────────

class _AdminButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const SizedBox.shrink();
    return ElevatedButton.icon(
      onPressed: () => context.push('/admin'),
      icon: const Icon(Icons.admin_panel_settings_rounded),
      label: const Text('Panel de Administración'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.zinc800,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
      ),
    );
  }
}
