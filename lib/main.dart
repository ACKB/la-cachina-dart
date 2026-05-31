import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Punto de entrada — K-china FIEI
///
/// Orden de inicialización:
///   1. Flutter binding
///   2. Conexión a Supabase
///   3. ProviderScope (Riverpod)
///   4. MaterialApp.router con go_router
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar conexión a Supabase
  await Supabase.initialize(
    url: 'https://tcntyolvhafxkqilrfoc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjbnR5b2x2aGFmeGtxaWxyZm9jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNjY2MzIsImV4cCI6MjA5Mzc0MjYzMn0.CbZEnJg7qI-zXlXaDXz_MIwuoOnmiua4w1QNACBTwRk',
  );

  runApp(
    // ProviderScope es el contenedor de toda la inyección de dependencias
    const ProviderScope(
      child: KChinaFieiApp(),
    ),
  );
}

/// Comportamiento personalizado de scroll para permitir arrastre con mouse y trackpad en Web/Desktop
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class KChinaFieiApp extends ConsumerWidget {
  const KChinaFieiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'K-china FIEI — UNFV',
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),

      // Temas Material 3
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Router con guards de autenticación
      routerConfig: router,
    );
  }
}
