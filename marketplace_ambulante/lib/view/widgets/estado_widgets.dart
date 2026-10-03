import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodel/sesion_viewmodel.dart';

/// Error al cargar una pantalla, con "Reintentar".
class ErrorCarga extends StatelessWidget {
  const ErrorCarga({
    super.key,
    required this.mensaje,
    required this.onReintentar,
    this.accionExtra,
  });

  final String mensaje;
  final VoidCallback onReintentar;

  /// Botón opcional debajo (ej. "Cerrar sesión").
  final Widget? accionExtra;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.grisTexto),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
            ?accionExtra,
          ],
        ),
      ),
    );
  }
}

/// Mensaje cuando una lista está vacía.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({super.key, required this.icono, required this.mensaje});

  final IconData icono;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 40, color: AppColors.grisTexto),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grisTexto),
          ),
        ],
      ),
    );
  }
}

/// Botón de cuenta en la barra superior con la opción "Cerrar sesión".
class MenuCuenta extends ConsumerWidget {
  const MenuCuenta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    return PopupMenuButton<String>(
      tooltip: 'Mi cuenta',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (opcion) {
        if (opcion == 'acerca') context.push(AppRoutes.acercaDe);
        if (opcion == 'salir') {
          ref.read(sesionProvider.notifier).cerrar();
          context.go(AppRoutes.iniciarSesion);
        }
      },
      itemBuilder: (context) => [
        if (sesion != null)
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              '${sesion.nombreCompleto}\n${sesion.email}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        const PopupMenuItem<String>(
          value: 'acerca',
          child: Text('Acerca de'),
        ),
        const PopupMenuItem<String>(
          value: 'salir',
          child: Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
