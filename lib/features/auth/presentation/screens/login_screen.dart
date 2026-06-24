import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

/// Pantalla de Login con Microsoft Entra ID
///
/// Mobile-first: layout en columna con padding para safe area,
/// animación ping de badge institucional, métricas de plataforma.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pingCtrl;
  late Animation<double>   _pingAnim;

  @override
  void initState() {
    super.initState();
    _pingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pingAnim = Tween<double>(begin: 0, end: 1).animate(_pingCtrl);
  }

  @override
  void dispose() {
    _pingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de estado de autenticación
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      next.whenData((state) {
        if (state is AuthAuthenticated) context.go('/');
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading ||
        (authState.valueOrNull is AuthLoading);

    return Scaffold(
      body: Stack(
        children: [
          // Círculos de fondo decorativos
          _buildBackground(),
          // Contenido
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // Logos institucionales
                  _buildLogosRow(),
                  const SizedBox(height: 36),

                  // Badge "Plataforma Exclusiva FIEI"
                  _buildBadge(),
                  const SizedBox(height: 28),

                  // Título
                  _buildTitle(),
                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    'El marketplace de hardware para la comunidad FIEI-UNFV. '
                    'Publica, compra y vende componentes electrónicos con otros estudiantes.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.zinc500),
                  ),
                  const Spacer(),

                  // Botón de login Microsoft
                  _buildSignInButton(isLoading),
                  const SizedBox(height: 20),

                  // Aviso de dominio
                  Text(
                    '* Solo correos institucionales @unfv.edu.pe',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.zinc400),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amber.withOpacity(0.08),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogosRow() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        ref.read(authProvider.notifier).signInMockAdmin();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accediendo como Administrador (Modo Desarrollo)'),
            backgroundColor: AppColors.zinc800,
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LogoBubble(label: 'UNFV'),
          const SizedBox(width: 16),
          Container(width: 1, height: 40, color: AppColors.zinc200),
          const SizedBox(width: 16),
          _LogoBubble(label: 'FIEI'),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return AnimatedBuilder(
      animation: _pingAnim,
      builder: (context, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1 + _pingAnim.value * 1.2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(
                        (1 - _pingAnim.value).clamp(0.0, 0.6),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              'Plataforma Exclusiva FIEI',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) =>
          AppColors.brandGradient.createShader(bounds),
      child: Text(
        'K-china FIEI',
        style: AppTextStyles.displayLg.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSignInButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : () => ref.read(authProvider.notifier).signIn(),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.zinc900,
          side: const BorderSide(color: AppColors.zinc200),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MicrosoftIcon(),
                  const SizedBox(width: 14),
                  Text(
                    'Continuar con Microsoft',
                    style: AppTextStyles.titleMd,
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LogoBubble extends StatelessWidget {
  final String label;
  const _LogoBubble({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.zinc700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MicrosoftIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          ColoredBox(color: Color(0xFFf25022)),
          ColoredBox(color: Color(0xFF7fba00)),
          ColoredBox(color: Color(0xFF00a4ef)),
          ColoredBox(color: Color(0xFFffb900)),
        ],
      ),
    );
  }
}
