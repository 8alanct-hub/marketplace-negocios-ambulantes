import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../viewmodel/sesion_viewmodel.dart';

/// View: "Perfil" del usuario.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    // "Carla Gómez" → "CG"
    final iniciales = sesion == null
        ? '?'
        : [sesion.nombre, sesion.apellido]
            .where((p) => p.isNotEmpty)
            .map((p) => p[0].toUpperCase())
            .join();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.grisFondo,
              child: Text(
                iniciales,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.negro,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (sesion != null) ...[
            Text(
              sesion.nombreCompleto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Correo'),
              subtitle: Text(sesion.email),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Teléfono'),
              subtitle: Text(sesion.telefono),
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.acercaDe),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              ref.read(sesionProvider.notifier).cerrar();
              context.go(AppRoutes.iniciarSesion);
            },
          ),
        ],
      ),
    );
  }
}
