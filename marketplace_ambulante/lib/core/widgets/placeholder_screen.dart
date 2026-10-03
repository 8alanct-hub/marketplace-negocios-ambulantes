import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/providers.dart';
import '../router/app_router.dart';

/// Pantalla temporal para probar la navegación antes de construir
/// la pantalla real.
class PlaceholderScreen extends ConsumerWidget {
  const PlaceholderScreen({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pantalla pendiente: $titulo'),
            if (sesion != null) ...[
              const SizedBox(height: 8),
              Text('Sesión: ${sesion.email} (${sesion.rol?.name ?? 'sin rol'})'),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(sesionProvider.notifier).cerrar();
                context.go(AppRoutes.signIn);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
